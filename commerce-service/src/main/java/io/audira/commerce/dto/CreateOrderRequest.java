package io.audira.commerce.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Data Transfer Object (DTO) que representa la solicitud de un cliente para crear una nueva orden de compra.
 * <p>
 * Este objeto se utiliza como cuerpo de la solicitud ({@code @RequestBody}) en el controlador de órdenes
 * y contiene las propiedades mínimas necesarias para iniciar el proceso transaccional.
 * </p>
 * <p>
 * Utiliza anotaciones de validación de Jakarta para asegurar la integridad de los datos de entrada
 * antes de que la orden sea procesada por la lógica de negocio.
 * </p>
 *
 * @author Grupo GA01
 * 
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateOrderRequest {

    /**
     * ID del usuario que realiza la compra.
     * <p>
     * Restricción: No puede ser nulo ({@code @NotNull}).
     * </p>
     */
    @NotNull(message = "User ID cannot be null")
    private Long userId;

    /**
     * Dirección de envío del pedido.
     * <p>
     * Restricción: No puede ser nula y debe contener al menos un carácter no blanco ({@code @NotBlank}).
     * </p>
     */
    @NotBlank(message = "Shipping address cannot be blank")
    private String shippingAddress;

    /**
     * Lista de artículos {@link OrderItemDTO} incluidos en la orden.
     * <p>
     * Restricción: La lista no puede ser nula ni estar vacía ({@code @NotEmpty}).
     * La anotación {@code @Valid} asegura que cada {@link OrderItemDTO} dentro de la lista
     * también cumpla con sus propias restricciones de validación.
     * </p>
     */
    @NotEmpty(message = "Order must contain at least one item")
    @Valid // This enables validation on the OrderItemDTOs inside the list
    private List<OrderItemDTO> items;
}