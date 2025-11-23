package io.audira.catalog.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * DTO for reordering featured content
 * GA01-156: Seleccionar/ordenar contenido destacado
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReorderRequest {

    private List<ReorderItem> items;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ReorderItem {
        private Long id;
        private Integer displayOrder;
    }
}
