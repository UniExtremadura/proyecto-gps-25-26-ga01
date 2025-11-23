package io.audira.catalog.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * GA01-163: Historial de moderaciones
 * Registra cada acción de moderación realizada sobre contenido
 */
@Entity
@Table(name = "moderation_history")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ModerationHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "product_id", nullable = false)
    private Long productId;

    @Column(name = "product_type", nullable = false)
    private String productType; // SONG o ALBUM

    @Column(name = "product_title", nullable = false)
    private String productTitle;

    @Column(name = "artist_id", nullable = false)
    private Long artistId;

    @Column(name = "artist_name")
    private String artistName;

    @Enumerated(EnumType.STRING)
    @Column(name = "previous_status")
    private ModerationStatus previousStatus;

    @Enumerated(EnumType.STRING)
    @Column(name = "new_status", nullable = false)
    private ModerationStatus newStatus;

    @Column(name = "moderated_by", nullable = false)
    private Long moderatedBy; // ID del admin

    @Column(name = "moderator_name")
    private String moderatorName;

    @Column(name = "rejection_reason", columnDefinition = "TEXT")
    private String rejectionReason;

    @Column(name = "moderated_at", nullable = false)
    private LocalDateTime moderatedAt;

    @Column(columnDefinition = "TEXT")
    private String notes; // Notas adicionales del moderador

    @PrePersist
    protected void onCreate() {
        if (this.moderatedAt == null) {
            this.moderatedAt = LocalDateTime.now();
        }
    }
}
