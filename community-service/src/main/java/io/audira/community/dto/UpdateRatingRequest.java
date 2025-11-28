package io.audira.community.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Data Transfer Object (DTO) que representa la solicitud de un usuario para actualizar una valoración (rating) existente.
 * <p>
 * Este objeto contiene los campos que pueden ser modificados: la puntuación y el comentario.
 * Los identificadores de la valoración y la entidad ({@code userId}, {@code entityId}, etc.) no se incluyen aquí
 * ya que son constantes y se pasan a través de la ruta o la identidad del usuario autenticado.
 * </p>
 * Requisito asociado: GA01-130 (Editar valoración).
 *
 * @author Grupo GA01
 * 
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class UpdateRatingRequest {

    /**
     * Puntuación de 1 a 5 estrellas.
     * <p>
     * Es opcional en la actualización (se puede actualizar solo el comentario).
     * Restricciones: Mínimo 1 ({@code @Min}) y máximo 5 ({@code @Max}).
     * </p>
     */
    @Min(value = 1, message = "Rating must be at least 1")
    @Max(value = 5, message = "Rating must be at most 5")
    private Integer rating;

    /**
     * Comentario o reseña opcional a actualizar.
     * <p>
     * Restricción: La longitud máxima permitida es de 500 caracteres ({@code @Size}).
     * </p>
     */
    @Size(max = 500, message = "Comment cannot exceed 500 characters")
    private String comment;
}