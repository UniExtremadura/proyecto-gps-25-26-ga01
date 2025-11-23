package io.audira.catalog.controller;

import io.audira.catalog.dto.ModerationRequest;
import io.audira.catalog.model.Album;
import io.audira.catalog.model.ModerationStatus;
import io.audira.catalog.model.Song;
import io.audira.catalog.service.ModerationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * GA01-162 y GA01-163: Controlador para moderación de contenido
 * Endpoints para que los administradores revisen, aprueben o rechacen contenido
 */
@RestController
@RequestMapping("/api/moderation")
@RequiredArgsConstructor
public class ModerationController {

    private final ModerationService moderationService;

    // ============= GA01-162: Endpoints de Aprobación/Rechazo =============

    /**
     * Aprobar una canción
     */
    @PostMapping("/songs/{id}/approve")
    public ResponseEntity<?> approveSong(@PathVariable Long id,
                                         @RequestBody ModerationRequest request) {
        try {
            Song song = moderationService.approveSong(id, request.getAdminId(), request.getNotes());
            return ResponseEntity.ok(song);
        } catch (IllegalArgumentException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    /**
     * Rechazar una canción
     */
    @PostMapping("/songs/{id}/reject")
    public ResponseEntity<?> rejectSong(@PathVariable Long id,
                                        @RequestBody ModerationRequest request) {
        try {
            Song song = moderationService.rejectSong(id, request.getAdminId(),
                    request.getRejectionReason(), request.getNotes());
            return ResponseEntity.ok(song);
        } catch (IllegalArgumentException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    /**
     * Aprobar un álbum
     */
    @PostMapping("/albums/{id}/approve")
    public ResponseEntity<?> approveAlbum(@PathVariable Long id,
                                          @RequestBody ModerationRequest request) {
        try {
            Album album = moderationService.approveAlbum(id, request.getAdminId(), request.getNotes());
            return ResponseEntity.ok(album);
        } catch (IllegalArgumentException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    /**
     * Rechazar un álbum
     */
    @PostMapping("/albums/{id}/reject")
    public ResponseEntity<?> rejectAlbum(@PathVariable Long id,
                                         @RequestBody ModerationRequest request) {
        try {
            Album album = moderationService.rejectAlbum(id, request.getAdminId(),
                    request.getRejectionReason(), request.getNotes());
            return ResponseEntity.ok(album);
        } catch (IllegalArgumentException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    /**
     * Obtener todas las canciones pendientes de moderación
     */
    @GetMapping("/songs/pending")
    public ResponseEntity<List<Song>> getPendingSongs() {
        return ResponseEntity.ok(moderationService.getPendingSongs());
    }

    /**
     * Obtener todos los álbumes pendientes de moderación
     */
    @GetMapping("/albums/pending")
    public ResponseEntity<List<Album>> getPendingAlbums() {
        return ResponseEntity.ok(moderationService.getPendingAlbums());
    }

    /**
     * Obtener canciones por estado de moderación
     */
    @GetMapping("/songs/status/{status}")
    public ResponseEntity<List<Song>> getSongsByStatus(@PathVariable String status) {
        try {
            ModerationStatus moderationStatus = ModerationStatus.valueOf(status.toUpperCase());
            return ResponseEntity.ok(moderationService.getSongsByStatus(moderationStatus));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    /**
     * Obtener álbumes por estado de moderación
     */
    @GetMapping("/albums/status/{status}")
    public ResponseEntity<List<Album>> getAlbumsByStatus(@PathVariable String status) {
        try {
            ModerationStatus moderationStatus = ModerationStatus.valueOf(status.toUpperCase());
            return ResponseEntity.ok(moderationService.getAlbumsByStatus(moderationStatus));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        }
    }
}
