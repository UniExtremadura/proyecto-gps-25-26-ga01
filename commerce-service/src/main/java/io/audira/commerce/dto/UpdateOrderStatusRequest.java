package io.audira.commerce.dto;

import io.audira.commerce.model.OrderStatus;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Data Transfer Object (DTO) que representa la solicitud para actualizar el estado de una orden de compra.
 * <p>
 * Este objeto se utiliza como cuerpo de la solicitud ({@code @RequestBody}) en los endpoints de administración
 * o internos del sistema de órdenes para cambiar el estado (ej. de PENDING a SHIPPED).
 * </p>
 *
 * @author Grupo GA01
 * @see OrderStatus
 * 
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class UpdateOrderStatusRequest {

    /**
     * Nuevo estado de la orden (ej. COMPLETED, CANCELED) utilizando el enumerador {@link OrderStatus}.
     * <p>
     * Restricción: No puede ser nulo ({@code @NotNull}).
     * </p>
     */
    @NotNull(message = "Status cannot be null")
    private OrderStatus status;
}