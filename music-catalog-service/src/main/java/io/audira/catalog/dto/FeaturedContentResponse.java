package io.audira.catalog.dto;

import io.audira.catalog.model.FeaturedContent;
import io.audira.catalog.model.FeaturedContent.ContentType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * DTO for featured content responses
 * GA01-156: Seleccionar/ordenar contenido destacado
 * GA01-157: Programación de destacados
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FeaturedContentResponse {

    private Long id;
    private ContentType contentType;
    private Long contentId;
    private Integer displayOrder;
    private LocalDateTime startDate;
    private LocalDateTime endDate;
    private Boolean isActive;
    private String contentTitle;
    private String contentImageUrl;
    private String contentArtist;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    /**
     * Convert entity to response DTO
     */
    public static FeaturedContentResponse fromEntity(FeaturedContent entity) {
        return FeaturedContentResponse.builder()
                .id(entity.getId())
                .contentType(entity.getContentType())
                .contentId(entity.getContentId())
                .displayOrder(entity.getDisplayOrder())
                .startDate(entity.getStartDate())
                .endDate(entity.getEndDate())
                .isActive(entity.getIsActive())
                .contentTitle(entity.getContentTitle())
                .contentImageUrl(entity.getContentImageUrl())
                .contentArtist(entity.getContentArtist())
                .createdAt(entity.getCreatedAt())
                .updatedAt(entity.getUpdatedAt())
                .build();
    }
}
