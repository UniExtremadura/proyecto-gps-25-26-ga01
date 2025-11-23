package io.audira.catalog.controller;

import io.audira.catalog.dto.FeaturedContentRequest;
import io.audira.catalog.dto.FeaturedContentResponse;
import io.audira.catalog.dto.ReorderRequest;
import io.audira.catalog.service.FeaturedContentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Controller for managing featured content
 * GA01-156: Seleccionar/ordenar contenido destacado
 * GA01-157: Programación de destacados
 */
@RestController
@RequiredArgsConstructor
public class FeaturedContentController {

    private final FeaturedContentService featuredContentService;

    /**
     * Get all featured content (admin)
     * GA01-156
     * GET /api/admin/featured-content
     */
    @GetMapping("/api/admin/featured-content")
    public ResponseEntity<List<FeaturedContentResponse>> getAllFeaturedContent() {
        return ResponseEntity.ok(featuredContentService.getAllFeaturedContent());
    }

    /**
     * Get active featured content (public)
     * GA01-157
     * GET /api/featured-content/active
     */
    @GetMapping("/api/featured-content/active")
    public ResponseEntity<List<FeaturedContentResponse>> getActiveFeaturedContent() {
        return ResponseEntity.ok(featuredContentService.getActiveFeaturedContent());
    }

    /**
     * Get featured content by ID (admin)
     * GA01-156
     * GET /api/admin/featured-content/{id}
     */
    @GetMapping("/api/admin/featured-content/{id}")
    public ResponseEntity<?> getFeaturedContentById(@PathVariable Long id) {
        try {
            return ResponseEntity.ok(featuredContentService.getFeaturedContentById(id));
        } catch (IllegalArgumentException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }

    /**
     * Create new featured content (admin)
     * GA01-156, GA01-157
     * POST /api/admin/featured-content
     */
    @PostMapping("/api/admin/featured-content")
    public ResponseEntity<?> createFeaturedContent(@RequestBody FeaturedContentRequest request) {
        try {
            FeaturedContentResponse response = featuredContentService.createFeaturedContent(request);
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (IllegalArgumentException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    /**
     * Update featured content (admin)
     * GA01-156, GA01-157
     * PUT /api/admin/featured-content/{id}
     */
    @PutMapping("/api/admin/featured-content/{id}")
    public ResponseEntity<?> updateFeaturedContent(
            @PathVariable Long id,
            @RequestBody FeaturedContentRequest request) {
        try {
            return ResponseEntity.ok(featuredContentService.updateFeaturedContent(id, request));
        } catch (IllegalArgumentException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }

    /**
     * Delete featured content (admin)
     * GA01-156
     * DELETE /api/admin/featured-content/{id}
     */
    @DeleteMapping("/api/admin/featured-content/{id}")
    public ResponseEntity<?> deleteFeaturedContent(@PathVariable Long id) {
        try {
            featuredContentService.deleteFeaturedContent(id);
            return ResponseEntity.noContent().build();
        } catch (IllegalArgumentException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }

    /**
     * Reorder featured content (admin)
     * GA01-156
     * PUT /api/admin/featured-content/reorder
     */
    @PutMapping("/api/admin/featured-content/reorder")
    public ResponseEntity<?> reorderFeaturedContent(@RequestBody ReorderRequest request) {
        try {
            return ResponseEntity.ok(featuredContentService.reorderFeaturedContent(request));
        } catch (IllegalArgumentException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    /**
     * Toggle active status (admin)
     * GA01-156
     * PATCH /api/admin/featured-content/{id}/toggle-active
     */
    @PatchMapping("/api/admin/featured-content/{id}/toggle-active")
    public ResponseEntity<?> toggleActive(
            @PathVariable Long id,
            @RequestBody Map<String, Boolean> body) {
        try {
            Boolean isActive = body.get("isActive");
            if (isActive == null) {
                Map<String, String> error = new HashMap<>();
                error.put("error", "isActive field is required");
                return ResponseEntity.badRequest().body(error);
            }
            return ResponseEntity.ok(featuredContentService.toggleActive(id, isActive));
        } catch (IllegalArgumentException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }
}
