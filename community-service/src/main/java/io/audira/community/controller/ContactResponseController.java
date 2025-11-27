package io.audira.community.controller;

import io.audira.community.model.ContactResponse;
import io.audira.community.service.ContactResponseService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/contact/responses")
@RequiredArgsConstructor
public class ContactResponseController {

    private final ContactResponseService contactResponseService;

    @GetMapping("/message/{messageId}")
    public ResponseEntity<List<ContactResponse>> getResponsesByMessageId(@PathVariable Long messageId) {
        return ResponseEntity.ok(contactResponseService.getResponsesByMessageId(messageId));
    }

    @GetMapping("/admin/{adminId}")
    public ResponseEntity<List<ContactResponse>> getResponsesByAdminId(@PathVariable Long adminId) {
        return ResponseEntity.ok(contactResponseService.getResponsesByAdminId(adminId));
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getResponseById(@PathVariable Long id) {
        try {
            ContactResponse response = contactResponseService.getResponseById(id);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }

    @PostMapping
    public ResponseEntity<?> createResponse(@RequestBody Map<String, Object> request) {
        try {
            Long contactMessageId = ((Number) request.get("contactMessageId")).longValue();
            Long adminId = ((Number) request.get("adminId")).longValue();
            String adminName = (String) request.get("adminName");
            String responseText = (String) request.get("response");

            if (responseText == null || responseText.trim().isEmpty()) {
                Map<String, String> error = new HashMap<>();
                error.put("error", "La respuesta es obligatoria");
                return ResponseEntity.badRequest().body(error);
            }

            ContactResponse response = contactResponseService.createResponse(
                    contactMessageId, adminId, adminName, responseText
            );
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateResponse(@PathVariable Long id, @RequestBody Map<String, String> request) {
        try {
            String responseText = request.get("response");
            if (responseText == null || responseText.trim().isEmpty()) {
                Map<String, String> error = new HashMap<>();
                error.put("error", "La respuesta es obligatoria");
                return ResponseEntity.badRequest().body(error);
            }

            ContactResponse response = contactResponseService.updateResponse(id, responseText);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteResponse(@PathVariable Long id) {
        try {
            contactResponseService.deleteResponse(id);
            return ResponseEntity.noContent().build();
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }
}
