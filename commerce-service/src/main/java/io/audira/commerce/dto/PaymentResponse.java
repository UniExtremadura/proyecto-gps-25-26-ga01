package io.audira.commerce.dto;

import io.audira.commerce.model.PaymentStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Data Transfer Object (DTO) que representa la respuesta estandarizada después de intentar procesar un pago, reintentarlo o reembolsarlo.
 * <p>
 * Este objeto es clave para comunicar el resultado de una operación transaccional al cliente,
 * indicando el estado final y el registro del pago (si fue creado).
 * </p>
 *
 * @author Grupo GA01
 * @see PaymentDTO
 * @see PaymentStatus
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PaymentResponse {

    /**
     * Indica si la operación solicitada (ej. procesamiento de pago) fue exitosa a nivel general ({@code true}) o si ocurrió un fallo ({@code false}).
     */
    private boolean success;

    /**
     * El ID de la transacción proporcionado por la pasarela de pago (si el intento llegó a la pasarela).
     * Puede ser nulo si el fallo ocurrió antes de contactar a la pasarela.
     */
    private String transactionId;

    /**
     * El estado final del pago tras la operación (ej. SUCCESS, FAILED, PENDING) utilizando el enumerador {@link PaymentStatus}.
     */
    private PaymentStatus status;

    /**
     * Mensaje descriptivo del resultado de la operación. Contiene un mensaje de éxito o el detalle del error de negocio/pasarela.
     */
    private String message;

    /**
     * El DTO completo del registro de pago asociado a la transacción, si la transacción fue creada en la base de datos.
     * Es nulo si la operación falló antes de la creación del registro.
     */
    private PaymentDTO payment;
}