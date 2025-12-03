package io.audira.commerce.dto;

import io.audira.commerce.model.PaymentMethod;
import io.audira.commerce.model.PaymentStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Data Transfer Object (DTO) que representa un registro individual de intento o transacción de pago.
 * <p>
 * Este objeto encapsula todos los detalles de una transacción, incluyendo el método utilizado,
 * el monto, el estado actual y las referencias a la orden y al usuario. Se utiliza para
 * la transferencia de datos entre la capa de servicio y los controladores.
 * </p>
 *
 * @author Grupo GA01
 * @see PaymentMethod
 * @see PaymentStatus
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PaymentDTO {

    /**
     * ID único del registro de pago en la base de datos.
     */
    private Long id;

    /**
     * ID de la transacción único proporcionado por la pasarela de pago (ej. Stripe ID, PayPal ID).
     */
    private String transactionId;

    /**
     * ID de la orden (tipo {@link Long}) asociada a este pago.
     */
    private Long orderId;

    /**
     * ID del usuario (tipo {@link Long}) que realizó el pago.
     */
    private Long userId;

    /**
     * Método de pago utilizado (ej. CARD, PAYPAL, WALLET) utilizando el enumerador {@link PaymentMethod}.
     */
    private PaymentMethod paymentMethod;

    /**
     * Estado actual del pago (ej. PENDING, SUCCESS, FAILED, REFUNDED) utilizando el enumerador {@link PaymentStatus}.
     */
    private PaymentStatus status;

    /**
     * Monto exacto (tipo {@link BigDecimal}) que fue procesado en esta transacción.
     */
    private BigDecimal amount;

    /**
     * Mensaje de error detallado de la pasarela de pago, si el estado es FAILED.
     */
    private String errorMessage;

    /**
     * Contador de reintentos de pago que se han realizado para esta transacción.
     */
    private Integer retryCount;

    /**
     * Campo JSON opcional para almacenar datos adicionales no estructurados de la pasarela de pago.
     */
    private String metadata;

    /**
     * Marca de tiempo del intento inicial de creación/procesamiento del pago.
     */
    private LocalDateTime createdAt;

    /**
     * Marca de tiempo de la última actualización del estado del pago.
     */
    private LocalDateTime updatedAt;

    /**
     * Marca de tiempo en la que el pago pasó al estado de {@code SUCCESS} o {@code FAILED} definitivo.
     */
    private LocalDateTime completedAt;
}