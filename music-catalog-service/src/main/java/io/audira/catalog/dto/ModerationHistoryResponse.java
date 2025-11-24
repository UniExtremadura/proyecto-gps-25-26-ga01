package io.audira.catalog.dto;

import io.audira.catalog.model.ModerationStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * GA01-163: DTO para respuestas de historial de moderación
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ModerationHistoryResponse {
    private Long id;
    private Long productId;
    private String productType;
    private String productTitle;
    private Long artistId;
    private String artistName;
    private ModerationStatus previousStatus;
    private ModerationStatus newStatus;
    private Long moderatedBy;
    private String moderatorName;
    private String rejectionReason;
    private LocalDateTime moderatedAt;
    private String notes;
}
