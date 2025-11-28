package io.audira.catalog.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

/**
 * Entidad que representa un Género Musical.
 * <p>
 * Actúa como una taxonomía para clasificar canciones y álbumes.
 * </p>
 */
@Entity
@Table(name = "genres")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Genre {

    /** Identificador único del género. */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Nombre único del género (ej: "Rock", "Jazz").
     * <p>Restricción de unicidad a nivel de base de datos.</p>
     */
    @Column(nullable = false, unique = true)
    private String name;

    /** Descripción detallada o historia del género. */
    @Column(columnDefinition = "TEXT")
    private String description;

    /** URL de una imagen representativa para la UI de exploración. */
    @Column(name = "image_url")
    private String imageUrl;

    /** Fecha de creación. */
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    /** Fecha de última actualización. */
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    /**
     * Callback JPA ejecutado antes de la persistencia inicial.
     * <p>Inicializa los timestamps.</p>
     */
    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }

    /**
     * Callback JPA ejecutado antes de cualquier actualización.
     * <p>Refresca el timestamp {@code updatedAt}.</p>
     */
    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
}
