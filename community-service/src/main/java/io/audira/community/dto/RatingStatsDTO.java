package io.audira.community.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Data Transfer Object (DTO) que representa las estadísticas agregadas de las valoraciones (ratings) para una entidad específica (ej. un álbum).
 * <p>
 * Este objeto se utiliza para exponer métricas clave como la puntuación promedio y la distribución
 * del conteo de estrellas a través de la API.
 * </p>
 *
 * @author Grupo GA01
 * 
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class RatingStatsDTO {

    /**
     * Tipo de la entidad (ej. "SONG", "ALBUM").
     */
    private String entityType;

    /**
     * ID único de la entidad cuyas estadísticas se están calculando.
     */
    private Long entityId;

    /**
     * Promedio de valoraciones (escala 1 a 5), redondeado a dos decimales.
     */
    private Double averageRating;

    /**
     * Número total de valoraciones (reseñas) recibidas para la entidad.
     */
    private Long totalRatings;

    /**
     * Distribución del conteo de valoraciones con cinco estrellas.
     */
    private Long fiveStars;
    
    /**
     * Distribución del conteo de valoraciones con cuatro estrellas.
     */
    private Long fourStars;
    
    /**
     * Distribución del conteo de valoraciones con tres estrellas.
     */
    private Long threeStars;
    
    /**
     * Distribución del conteo de valoraciones con dos estrellas.
     */
    private Long twoStars;
    
    /**
     * Distribución del conteo de valoraciones con una estrella.
     */
    private Long oneStar;

    /**
     * Constructor simplificado que inicializa los campos principales y realiza el redondeo del promedio.
     * <p>
     * Nota: Las distribuciones de estrellas ({@code fiveStars}, etc.) deben ser establecidas por separado.
     * </p>
     *
     * @param entityType Tipo de la entidad.
     * @param entityId ID de la entidad.
     * @param averageRating El promedio de valoración calculado.
     * @param totalRatings El número total de valoraciones.
     */
    public RatingStatsDTO(String entityType, Long entityId, Double averageRating, Long totalRatings) {
        this.entityType = entityType;
        this.entityId = entityId;
        // Redondea el promedio a dos decimales
        this.averageRating = averageRating != null ? Math.round(averageRating * 100.0) / 100.0 : 0.0;
        this.totalRatings = totalRatings != null ? totalRatings : 0L;
    }
}