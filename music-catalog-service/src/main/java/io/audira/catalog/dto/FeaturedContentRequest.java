package io.audira.catalog.dto;

import io.audira.catalog.model.FeaturedContent.ContentType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * DTO for creating/updating featured content
 * GA01-156: Seleccionar/ordenar contenido destacado
 * GA01-157: Programación de destacados
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FeaturedContentRequest {

    private ContentType contentType;
    private Long contentId;
    private Integer displayOrder;
    private LocalDateTime startDate;  // GA01-157
    private LocalDateTime endDate;    // GA01-157
    private Boolean isActive;
}
