package io.audira.catalog.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Entidad que representa la asociación entre un artista y una obra musical (Canción o Álbum).
 * <p>
 * Esta tabla gestiona dos conceptos clave:
 * <ol>
 * <li><b>Créditos:</b> Quién participó y qué rol desempeñó (GA01-154).</li>
 * <li><b>Regalías (Splits):</b> Qué porcentaje de las ganancias le corresponde (GA01-155).</li>
 * </ol>
 * </p>
 */
@Entity
@Table(name = "collaborators")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Collaborator {
/** Identificador único del registro de colaboración. */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * ID de la canción asociada.
     * <p>Puede ser {@code null} si la colaboración es a nivel de álbum.</p>
     */
    @Column(name = "song_id")
    private Long songId;

    /**
     * ID del álbum asociado.
     * <p>Puede ser {@code null} si la colaboración es específica de una canción (Single).</p>
     */
    @Column(name = "album_id")
    private Long albumId;

    /**
     * ID del artista que colabora (el invitado).
     */
    @Column(name = "artist_id", nullable = false)
    private Long artistId;

    /**
     * El rol desempeñado en la obra.
     * <p>Ej: "Featured Artist", "Producer", "Songwriter".</p>
     */
    @Column(nullable = false, length = 100)
    private String role;

    /**
     * Estado actual de la invitación.
     * <p>Por defecto inicia en {@link CollaborationStatus#PENDING}.</p>
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private CollaborationStatus status = CollaborationStatus.PENDING;

    /**
     * ID del usuario que creó la invitación (generalmente el dueño del contenido).
     * <p>Campo de auditoría para saber quién inició el proceso.</p>
     */
    @Column(name = "invited_by")
    private Long invitedBy;

    /**
     * Porcentaje de ingresos asignado a este colaborador.
     * <p>
     * <b>GA01-155:</b> Valor entre 0.00 y 100.00.
     * Se utiliza {@code BigDecimal} con precisión de 5 dígitos y 2 decimales para cálculos financieros exactos.
     * </p>
     */
    @Column(name = "revenue_percentage", precision = 5, scale = 2)
    @Builder.Default
    private BigDecimal revenuePercentage = BigDecimal.ZERO;

    /** Fecha de creación del registro. */
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    /** Fecha de la última actualización. */
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    /**
     * Callback JPA ejecutado antes de insertar el registro en la base de datos.
     * <p>
     * Establece las fechas de auditoría y garantiza valores por defecto seguros para
     * el estado y el porcentaje de regalías si no fueron provistos.
     * </p>
     */
    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
        if (this.status == null) {
            this.status = CollaborationStatus.PENDING;
        }
        if (this.revenuePercentage == null) {
            this.revenuePercentage = BigDecimal.ZERO;
        }
    }

    /**
     * Callback JPA ejecutado antes de actualizar el registro.
     * <p>Actualiza la marca de tiempo {@code updatedAt}.</p>
     */
    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    /**
     * Verifica si esta colaboración pertenece a una canción individual.
     *
     * @return {@code true} si {@code songId} no es nulo.
     */
    public boolean isForSong() {
        return songId != null;
    }

    /**
     * Verifica si esta colaboración pertenece a un álbum completo.
     *
     * @return {@code true} si {@code albumId} no es nulo.
     */
    public boolean isForAlbum() {
        return albumId != null;
    }

    /**
     * Obtiene el ID de la entidad relacionada (polimorfismo manual).
     * <p>
     * Útil para lógica genérica que no necesita distinguir entre álbum o canción
     * en el momento de la ejecución.
     * </p>
     *
     * @return El ID de la canción o el ID del álbum, según corresponda.
     */
    public Long getEntityId() {
        return isForSong() ? songId : albumId;
    }
}