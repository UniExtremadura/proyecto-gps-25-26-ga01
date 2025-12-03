package io.audira.catalog.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO que agrupa todas las métricas de rendimiento para una canción específica.
 * <p>
 * Utilizado para cumplir con los requisitos de dashboard <b>GA01-108</b> y <b>GA01-109</b>.
 * Combina datos de consumo (streaming) con datos financieros y de comunidad.
 * </p>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SongMetrics {

    // --- Contexto ---
    /** ID de la canción analizada. */
    private Long songId;

    /** Título de la canción. */
    private String songName;

    /** Nombre del artista. */
    private String artistName;

    // --- Rendimiento y Comunidad ---
    /** Total de reproducciones históricas. */
    private Long totalPlays;

    /** Valoración promedio (1-5 estrellas) actual. */
    private Double averageRating;

    /** Cantidad de usuarios que han valorado la canción. */
    private Long totalRatings;

    /** Número de comentarios recibidos. */
    private Long totalComments;

    // --- Ventas y Finanzas ---
    /** Unidades vendidas individualmente. */
    private Long totalSales;

    /** Ingresos totales brutos generados por esta canción. */
    private Double totalRevenue;

    // --- Ranking y Posicionamiento ---
    /**
     * Posición de esta canción dentro del catálogo del artista.
     * <p>Ej: {@code 1} indica que es la canción más exitosa del artista.</p>
     */
    private Integer rankInArtistCatalog;
}
