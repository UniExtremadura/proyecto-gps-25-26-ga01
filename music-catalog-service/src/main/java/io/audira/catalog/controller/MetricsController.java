package io.audira.catalog.controller;

import io.audira.catalog.dto.ArtistMetricsSummary;
import io.audira.catalog.dto.SongMetrics;
import io.audira.catalog.service.MetricsService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Controller for artist and song metrics
 * GA01-108: Resumen rápido (plays, valoraciones, ventas, comentarios, evolución)
 */
@RestController
@RequestMapping("/api/metrics")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class MetricsController {

    private final MetricsService metricsService;

    /**
     * Get summary metrics for an artist
     * GA01-108: Resumen rápido
     *
     * @param artistId Artist ID
     * @return Summary with plays, ratings, sales, comments, and growth
     */
    @GetMapping("/artists/{artistId}")
    public ResponseEntity<ArtistMetricsSummary> getArtistMetricsSummary(
            @PathVariable Long artistId
    ) {
        ArtistMetricsSummary metrics = metricsService.getArtistMetricsSummary(artistId);
        return ResponseEntity.ok(metrics);
    }

    /**
     * Get metrics for a specific song
     *
     * @param songId Song ID
     * @return Song metrics
     */
    @GetMapping("/songs/{songId}")
    public ResponseEntity<SongMetrics> getSongMetrics(
            @PathVariable Long songId
    ) {
        SongMetrics metrics = metricsService.getSongMetrics(songId);
        return ResponseEntity.ok(metrics);
    }

    /**
     * Get top songs for an artist (for compatibility with existing frontend)
     * GA01-108: Part of summary
     *
     * @param artistId Artist ID
     * @param limit Number of top songs to return
     * @return List of top songs by plays
     */
    @GetMapping("/artists/{artistId}/top-songs")
    public ResponseEntity<?> getArtistTopSongs(
            @PathVariable Long artistId,
            @RequestParam(defaultValue = "10") int limit
    ) {
        // TODO: Implement properly
        // For now, return empty to maintain compatibility
        return ResponseEntity.ok(new java.util.ArrayList<>());
    }
}