package io.audira.community.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.ZonedDateTime;

/**
 * Entidad de base de datos que representa una valoración o reseña (Rating) otorgada por un usuario a una entidad del sistema.
 * <p>
 * Mapeada a la tabla {@code ratings}. La restricción única asegura que un usuario solo pueda
 * valorar una entidad específica (ej. un álbum) una única vez.
 * </p>
 * Requisitos asociados: GA01-128 (Puntuación), GA01-129 (Comentario), GA01-130 (Edición/Eliminación).
 *
 * @author Grupo GA01
 * @see Entity
 * 
 */
@Entity
@Table(name = "ratings",
       uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "entity_type", "entity_id"}))
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Rating {

    /**
     * ID primario y clave única de la entidad Rating. Generado automáticamente.
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * ID del usuario que realiza la valoración.
     * <p>
     * Restricción: No puede ser nulo ({@code @NotNull}).
     * </p>
     */
    @NotNull(message = "User ID is required")
    @Column(name = "user_id", nullable = false)
    private Long userId;

    /**
     * Tipo de entidad valorada (ej. ARTIST, SONG, ALBUM).
     * <p>
     * Restricción: No puede ser nulo ({@code @NotNull}) y longitud máxima de 50 caracteres.
     * </p>
     */
    @NotNull(message = "Entity type is required")
    @Column(name = "entity_type", nullable = false, length = 50)
    private String entityType;

    /**
     * ID de la entidad valorada en el catálogo o sistema.
     * <p>
     * Restricción: No puede ser nulo ({@code @NotNull}).
     * </p>
     */
    @NotNull(message = "Entity ID is required")
    @Column(name = "entity_id", nullable = false)
    private Long entityId;

    /**
     * Puntuación otorgada (de 1 a 5 estrellas).
     * <p>
     * Requisito: GA01-128.
     * Restricciones: No puede ser nulo ({@code @NotNull}), mínimo 1 ({@code @Min}), y máximo 5 ({@code @Max}).
     * </p>
     */
    @NotNull(message = "Rating value is required")
    @Min(value = 1, message = "Rating must be at least 1")
    @Max(value = 5, message = "Rating must be at most 5")
    @Column(nullable = false)
    private Integer rating;

    /**
     * Comentario opcional (reseña) asociado a la valoración.
     * <p>
     * Requisito: GA01-129.
     * Restricción: La longitud máxima permitida es de 500 caracteres ({@code @Size}).
     * </p>
     */
    @Size(max = 500, message = "Comment cannot exceed 500 characters")
    @Column(length = 500)
    private String comment;

    /**
     * Indica si la valoración está activa y visible ({@code true}) o si ha sido deshabilitada lógicamente (ej. por moderación).
     * <p>
     * Valor por defecto: {@code true}.
     * </p>
     */
    @Column(name = "is_active")
    @Builder.Default
    private Boolean isActive = true;

    /**
     * Fecha y hora de creación de la valoración, incluyendo información de zona horaria ({@link ZonedDateTime}).
     */
    @Column(name = "created_at")
    private ZonedDateTime createdAt;

    /**
     * Fecha y hora de la última actualización de la valoración.
     * <p>
     * Requisito: GA01-130.
     * </p>
     */
    @Column(name = "updated_at")
    private ZonedDateTime updatedAt;
}