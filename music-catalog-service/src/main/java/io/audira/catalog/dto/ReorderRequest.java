package io.audira.catalog.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * DTO de entrada (Request) para reordenar elementos de una lista.
 * <p>
 * Diseñado específicamente para cumplir con el requisito <b>GA01-156: Seleccionar y ordenar contenido destacado</b>.
 * Permite actualizar la prioridad de visualización (displayOrder) de múltiples elementos en una sola transacción.
 * </p>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReorderRequest {

    /**
     * Lista de pares (ID, Nuevo Orden) a procesar.
     */
    private List<ReorderItem> items;

    /**
     * Clase interna estática que representa un cambio de orden individual.
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ReorderItem {
        
        /**
         * Identificador único del recurso a mover (ej: ID del FeaturedContent).
         */
        private Long id;

        /**
         * La nueva posición numérica en la lista.
         * <p>Los valores más bajos (ej: 1) aparecen primero/arriba.</p>
         */
        private Integer displayOrder;
    }
}
