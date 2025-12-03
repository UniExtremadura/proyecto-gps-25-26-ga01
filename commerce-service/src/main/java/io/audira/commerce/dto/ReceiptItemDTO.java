package io.audira.commerce.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Data Transfer Object (DTO) que representa un artículo o línea de detalle dentro de un Recibo de Pago (Receipt).
 * <p>
 * Este objeto se utiliza para desglosar los cargos de un recibo, especificando la descripción,
 * la cantidad y el precio por unidad y el total por línea.
 * </p>
 *
 * @author Grupo GA01
 * @see ReceiptDTO
 * 
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReceiptItemDTO {

    /**
     * Nombre descriptivo del artículo o servicio.
     */
    private String itemName;

    /**
     * Tipo de artículo (ej. 'Canción', 'Álbum', 'Impuesto') para categorización.
     */
    private String itemType;

    /**
     * Cantidad de unidades de este artículo.
     */
    private int quantity;

    /**
     * Precio unitario del artículo al momento de la transacción.
     */
    private BigDecimal unitPrice;

    /**
     * Precio total de esta línea de artículo ({@code unitPrice * quantity}).
     */
    private BigDecimal totalPrice;
}