package io.audira.catalog.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * DTO que representa una línea de detalle (Item) dentro de un pedido.
 * <p>
 * Vincula la transacción comercial con el producto específico del catálogo
 * (Canción o Álbum) que fue adquirido.
 * </p>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OrderItemDTO {
    /**
     * Identificador único de la línea de detalle.
     */
    private Long id;

    /**
     * Tipo de producto adquirido.
     * <p>Ej: {@code "SONG"}, {@code "ALBUM"}.</p>
     */
    private String itemType;

    /**
     * ID del producto en el catálogo.
     * <p>Referencia al ID de la tabla de Songs o Albums.</p>
     */
    private Long itemId;

    /**
     * Cantidad de unidades compradas.
     * <p>Generalmente es 1 para productos digitales, pero el modelo soporta más.</p>
     */
    private Integer quantity;

    /**
     * Precio unitario al momento de la compra.
     * <p>
     * <b>Importante:</b> Este valor es una instantánea (snapshot) del precio histórico.
     * No debe consultarse el precio actual del producto, ya que pudo haber cambiado.
     * </p>
     */
    private BigDecimal price;
}
