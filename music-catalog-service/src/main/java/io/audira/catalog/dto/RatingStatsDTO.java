package io.audira.catalog.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO que transfiere estadísticas de valoraciones (Ratings) desde el servicio de Comunidad.
 * <p>
 * Se utiliza para hidratar las vistas de canciones, álbumes y artistas con información
 * agregada sobre la recepción del público, evitando que el servicio de catálogo tenga
 * que calcular promedios en tiempo real.
 * </p>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RatingStatsDTO {
    /**
     * Tipo de entidad evaluada.
     * <p>Valores esperados: {@code "SONG"}, {@code "ALBUM"}, {@code "ARTIST"}.</p>
     */
    private String entityType;

    /**
     * Identificador único de la entidad evaluada.
     */
    private Long entityId;

    /**
     * Puntuación promedio calculada.
     * <p>Valor decimal entre 0.0 y 5.0.</p>
     */
    private Double averageRating;

    /**
     * Número total de valoraciones recibidas.
     */
    private Long totalRatings;

    /**
     * Cantidad de votos con puntuación de 5 estrellas.
     * <p>Utilizado para renderizar histogramas de distribución de votos.</p>
     */
    private Long fiveStars;

    /** Cantidad de votos con puntuación de 4 estrellas. */
    private Long fourStars;

    /** Cantidad de votos con puntuación de 3 estrellas. */
    private Long threeStars;

    /** Cantidad de votos con puntuación de 2 estrellas. */
    private Long twoStars;

    /** Cantidad de votos con puntuación de 1 estrella. */
    private Long oneStar;
}
