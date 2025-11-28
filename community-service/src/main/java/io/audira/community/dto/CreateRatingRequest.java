package io.audira.community.dto;

import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Data Transfer Object (DTO) que representa la solicitud de un usuario para crear una nueva valoración (rating).
 * <p>
 * Este objeto contiene la información necesaria para asociar una puntuación y un comentario
 * a una entidad específica del sistema (ej. canción, álbum).
 * </p>
 * Requisitos asociados: GA01-128 (Puntuación de 1-5 estrellas), GA01-129 (Comentario opcional).
 *
 * @author Grupo GA01
 * 
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateRatingRequest {

    /**
     * Tipo de la entidad que está siendo valorada (ej. "SONG", "ALBUM").
     * <p>
     * Restricciones: No puede ser nulo ({@code @NotNull}) ni estar en blanco ({@code @NotBlank}).
     * </p>
     */
    @NotNull(message = "Entity type is required")
    @NotBlank(message = "Entity type cannot be blank")
    private String entityType;

    /**
     * ID único de la entidad que está siendo valorada (ej. ID de la canción).
     * <p>
     * Restricciones: No puede ser nulo ({@code @NotNull}) y debe ser un número positivo ({@code @Min(1)}).
     * </p>
     */
    @NotNull(message = "Entity ID is required")
    @Min(value = 1, message = "Entity ID must be positive")
    private Long entityId;

    /**
     * Puntuación otorgada por el usuario, en escala de 1 a 5 estrellas.
     * <p>
     * Requisito: GA01-128.
     * Restricciones: No puede ser nulo ({@code @NotNull}), mínimo 1 ({@code @Min}), y máximo 5 ({@code @Max}).
     * </p>
     */
    @NotNull(message = "Rating is required")
    @Min(value = 1, message = "Rating must be at least 1")
    @Max(value = 5, message = "Rating must be at most 5")
    private Integer rating;

    /**
     * Comentario o reseña opcional asociado a la valoración.
     * <p>
     * Requisito: GA01-129.
     * Restricción: La longitud máxima permitida es de 500 caracteres ({@code @Size}).
     * </p>
     */
    @Size(max = 500, message = "Comment cannot exceed 500 characters")
    private String comment;
}