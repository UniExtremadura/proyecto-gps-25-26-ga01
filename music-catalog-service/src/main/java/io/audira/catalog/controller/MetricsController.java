package io.audira.catalog.controller;

import io.audira.catalog.dto.ArtistMetricsDetailed;
import io.audira.catalog.dto.ArtistMetricsSummary;
import io.audira.catalog.dto.SongMetrics;
import io.audira.catalog.service.MetricsService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

/**
 * Controlador para la consulta de métricas de rendimiento.
 * <p>
 * GA01-108: Resumen rápido (plays, valoraciones, ventas).
 * GA01-109: Vista detallada y gráficos.
 * </p>
 */
@RestController
@RequestMapping("/api/metrics")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class MetricsController {

    private final MetricsService metricsService;

    /**
     * Obtiene un resumen ejecutivo de las métricas de un artista.
     *
     * @param artistId ID del artista.
     * @return DTO con totales acumulados (plays, ventas, ratings).
     */
    @GetMapping("/artists/{artistId}")
    public ResponseEntity<ArtistMetricsSummary> getArtistMetricsSummary(
            @PathVariable Long artistId
    ) {
        ArtistMetricsSummary metrics = metricsService.getArtistMetricsSummary(artistId);
        return ResponseEntity.ok(metrics);
    }

    /**
     * Obtiene métricas detalladas de un artista en un rango de fechas.
     * <p>
     * Si no se especifican fechas, devuelve los últimos 30 días por defecto.
     * </p>
     *
     * @param artistId ID del artista.
     * @param startDate Fecha inicio (opcional).
     * @param endDate Fecha fin (opcional).
     * @return Datos detallados para graficar evolución.
     */
    @GetMapping("/artists/{artistId}/detailed")
    public ResponseEntity<ArtistMetricsDetailed> getArtistMetricsDetailed(
            @PathVariable Long artistId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate
    ) {
        if (startDate == null) {
            startDate = LocalDate.now().minusDays(30);
        }
        if (endDate == null) {
            endDate = LocalDate.now();
        }

        ArtistMetricsDetailed metrics = metricsService.getArtistMetricsDetailed(
                artistId, startDate, endDate
        );
        return ResponseEntity.ok(metrics);
    }

    /**
     * Obtiene métricas específicas de rendimiento para una sola canción.
     *
     * @param songId ID de la canción.
     * @return Métricas de la canción.
     */
    @GetMapping("/songs/{songId}")
    public ResponseEntity<SongMetrics> getSongMetrics(
            @PathVariable Long songId
    ) {
        SongMetrics metrics = metricsService.getSongMetrics(songId);
        return ResponseEntity.ok(metrics);
    }

    /**
     * Obtiene el ranking de las canciones más exitosas de un artista.
     *
     * @param artistId ID del artista.
     * @param limit Cantidad de canciones a retornar.
     * @return Lista de métricas de las top canciones.
     */
    @GetMapping("/artists/{artistId}/top-songs")
    public ResponseEntity<java.util.List<SongMetrics>> getArtistTopSongs(
            @PathVariable Long artistId,
            @RequestParam(defaultValue = "10") int limit
    ) {
        java.util.List<SongMetrics> topSongs = metricsService.getArtistTopSongs(artistId, limit);
        return ResponseEntity.ok(topSongs);
    }
}
