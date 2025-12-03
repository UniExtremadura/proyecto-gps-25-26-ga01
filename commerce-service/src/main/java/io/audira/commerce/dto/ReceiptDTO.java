package io.audira.commerce.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Data Transfer Object (DTO) que representa el Recibo o Comprobante de Pago final de una transacción.
 * <p>
 * Este objeto consolida la información de la orden ({@link OrderDTO}), el pago ({@link PaymentDTO})
 * y los detalles fiscales y de cliente para generar un documento final.
 * </p>
 *
 * @author Grupo GA01
 * @see PaymentDTO
 * @see OrderDTO
 * @see ReceiptItemDTO
 * 
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReceiptDTO {

    /**
     * Número único de identificación del recibo.
     */
    private String receiptNumber;

    /**
     * Objeto {@link PaymentDTO} que representa el pago asociado a este recibo.
     */
    private PaymentDTO payment;

    /**
     * Objeto {@link OrderDTO} que representa la orden de compra asociada a este recibo.
     */
    private OrderDTO order;

    /**
     * Nombre del cliente que realizó la compra.
     */
    private String customerName;

    /**
     * Dirección de correo electrónico del cliente.
     */
    private String customerEmail;

    /**
     * Subtotal de los artículos antes de impuestos.
     */
    private BigDecimal subtotal;

    /**
     * Monto total de impuestos aplicados a la compra.
     */
    private BigDecimal tax;

    /**
     * Monto total final pagado (Subtotal + Impuestos).
     */
    private BigDecimal total;

    /**
     * Marca de tiempo de la fecha y hora en que se emitió o generó el recibo.
     */
    private LocalDateTime issuedAt;

    /**
     * Lista de artículos {@link ReceiptItemDTO} incluidos en este recibo, reflejando los cargos detallados.
     */
    private List<ReceiptItemDTO> items;
}