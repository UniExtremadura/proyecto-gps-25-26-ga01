package io.audira.catalog.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Entidad de auditoría para el historial de moderación.
 * <p>
 * Esta tabla es <b>inmutable</b> (solo inserciones). Registra cada cambio de estado
 * en el flujo de aprobación de contenido para cumplir con el requisito <b>GA01-163</b>.
 * Permite responder preguntas como: "¿Quién rechazó este álbum y cuándo?".
 * </p>
 */
@Entity
@Table(name = "moderation_history")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ModerationHistory {

    /** Identificador único del evento de auditoría. */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** ID de la entidad moderada. */
    @Column(name = "product_id", nullable = false)
    private Long productId;

    /** Tipo de producto: "SONG" o "ALBUM". */
    @Column(name = "product_type", nullable = false)
    private String productType;

    /**
     * Snapshot del título del producto al momento de la moderación.
     * <p>Útil si el título cambia posteriormente.</p>
     */
    @Column(name = "product_title", nullable = false)
    private String productTitle;

    /** ID del artista propietario. */
    @Column(name = "artist_id", nullable = false)
    private Long artistId;

    /** Snapshot del nombre del artista. */
    @Column(name = "artist_name")
    private String artistName;

    /** Estado anterior (Origen de la transición). */
    @Enumerated(EnumType.STRING)
    @Column(name = "previous_status")
    private ModerationStatus previousStatus;

    /** Nuevo estado asignado (Destino de la transición). */
    @Enumerated(EnumType.STRING)
    @Column(name = "new_status", nullable = false)
    private ModerationStatus newStatus;

    /** ID del administrador que realizó la acción. */
    @Column(name = "moderated_by", nullable = false)
    private Long moderatedBy;

    /** Nombre del administrador (para visualización rápida en logs). */
    @Column(name = "moderator_name")
    private String moderatorName;

    /**
     * Motivo del rechazo.
     * <p>Generalmente poblado solo si {@code newStatus} es {@code REJECTED}.</p>
     */
    @Column(name = "rejection_reason", columnDefinition = "TEXT")
    private String rejectionReason;

    /** Fecha y hora exacta del evento. */
    @Column(name = "moderated_at", nullable = false)
    private LocalDateTime moderatedAt;

    /** Notas internas para otros administradores. */
    @Column(columnDefinition = "TEXT")
    private String notes;

    @PrePersist
    protected void onCreate() {
        if (this.moderatedAt == null) {
            this.moderatedAt = LocalDateTime.now();
        }
    }
}
