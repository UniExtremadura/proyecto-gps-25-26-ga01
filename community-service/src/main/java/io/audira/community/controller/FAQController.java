package io.audira.community.controller;

import io.audira.community.model.FAQ;
import io.audira.community.service.FAQService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/faqs")
@RequiredArgsConstructor
public class FAQController {

    private final FAQService faqService;

    @GetMapping
    public ResponseEntity<List<FAQ>> getAllFaqs() {
        return ResponseEntity.ok(faqService.getAllFaqs());
    }

    @GetMapping("/active")
    public ResponseEntity<List<FAQ>> getActiveFaqs() {
        return ResponseEntity.ok(faqService.getActiveFaqs());
    }

    @GetMapping("/category/{category}")
    public ResponseEntity<List<FAQ>> getFaqsByCategory(@PathVariable String category) {
        return ResponseEntity.ok(faqService.getFaqsByCategory(category));
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getFaqById(@PathVariable Long id) {
        try {
            FAQ faq = faqService.getFaqById(id);
            return ResponseEntity.ok(faq);
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }

    @PostMapping
    public ResponseEntity<?> createFaq(@RequestBody FAQ faq) {
        try {
            FAQ createdFaq = faqService.createFaq(faq);
            return ResponseEntity.status(HttpStatus.CREATED).body(createdFaq);
        } catch (IllegalArgumentException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateFaq(@PathVariable Long id, @RequestBody FAQ faqDetails) {
        try {
            FAQ updatedFaq = faqService.updateFaq(id, faqDetails);
            return ResponseEntity.ok(updatedFaq);
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }

    @PutMapping("/{id}/toggle-active")
    public ResponseEntity<?> toggleActive(@PathVariable Long id) {
        try {
            FAQ faq = faqService.toggleActive(id);
            return ResponseEntity.ok(faq);
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteFaq(@PathVariable Long id) {
        try {
            faqService.deleteFaq(id);
            return ResponseEntity.noContent().build();
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }

    @PostMapping("/{id}/view")
    public ResponseEntity<?> incrementViewCount(@PathVariable Long id) {
        try {
            faqService.incrementViewCount(id);
            return ResponseEntity.ok().build();
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }

    @PostMapping("/{id}/helpful")
    public ResponseEntity<?> markAsHelpful(@PathVariable Long id) {
        try {
            faqService.markAsHelpful(id);
            return ResponseEntity.ok().build();
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }

    @PostMapping("/{id}/not-helpful")
    public ResponseEntity<?> markAsNotHelpful(@PathVariable Long id) {
        try {
            faqService.markAsNotHelpful(id);
            return ResponseEntity.ok().build();
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }
}
