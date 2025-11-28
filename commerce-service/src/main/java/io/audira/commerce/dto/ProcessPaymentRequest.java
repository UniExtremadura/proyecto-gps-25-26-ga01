package io.audira.commerce.dto;

import io.audira.commerce.model.PaymentMethod;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.Map;

/**
 * Data Transfer Object (DTO) que representa la solicitud de un cliente para procesar un nuevo pago.
 * <p>
 * Este objeto se utiliza como cuerpo de la solicitud ({@code @RequestBody}) en el controlador de pagos
 * e incluye todos los datos necesarios para iniciar una transacción financiera con una pasarela de pago.
 * </p>
 * <p>
 * Utiliza anotaciones de validación de Jakarta para asegurar que todos los campos obligatorios
 * y numéricos sean correctos antes de que el pago sea procesado.
 * </p>
 *
 * @author Grupo GA01
 * @see PaymentMethod
 * 
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProcessPaymentRequest {

    /**
     * ID de la orden (tipo {@link Long}) para la cual se está realizando el pago.
     * <p>
     * Restricción: No puede ser nulo ({@code @NotNull}).
     * </p>
     */
    @NotNull(message = "Order ID is required")
    private Long orderId;

    /**
     * ID del usuario (tipo {@link Long}) que está realizando el pago.
     * <p>
     * Restricción: No puede ser nulo ({@code @NotNull}).
     * </p>
     */
    @NotNull(message = "User ID is required")
    private Long userId;

    /**
     * El método de pago a utilizar (ej. CARD, PAYPAL) utilizando el enumerador {@link PaymentMethod}.
     * <p>
     * Restricción: No puede ser nulo ({@code @NotNull}).
     * </p>
     */
    @NotNull(message = "Payment method is required")
    private PaymentMethod paymentMethod;

    /**
     * El monto total (tipo {@link BigDecimal}) a cobrar en la transacción.
     * <p>
     * Restricciones: No puede ser nulo ({@code @NotNull}) y debe ser un valor positivo (mayor que cero) ({@code @Positive}).
     * </p>
     */
    @NotNull(message = "Amount is required")
    @Positive(message = "Amount must be positive")
    private BigDecimal amount;

    /**
     * Detalles sensibles o específicos del método de pago (ej. número de tarjeta, CVV, token de pago).
     * <p>
     * Este mapa debe contener la información requerida por la pasarela de pago para el método seleccionado.
     * </p>
     */
    private Map<String, String> paymentDetails;
}