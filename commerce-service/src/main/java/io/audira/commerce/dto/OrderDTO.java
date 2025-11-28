package io.audira.commerce.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Data Transfer Object (DTO) que representa una Orden de Compra (Order) ya procesada en el sistema.
 * <p>
 * Este objeto encapsula toda la información clave de una transacción completada, incluyendo
 * los artículos comprados, el monto total y el estado actual de la orden. Se utiliza
 * para la consulta de órdenes a través de la API.
 * </p>
 *
 * @author Grupo GA01
 * @see OrderItemDTO
 * 
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OrderDTO {

    /**
     * ID único del registro de la orden en la base de datos.
     */
    private Long id;

    /**
     * ID del usuario que realizó la compra.
     */
    private Long userId;

    /**
     * Número de orden único y legible (ej. una cadena alfanumérica) utilizado para referencia externa.
     */
    private String orderNumber;

    /**
     * Lista de artículos {@link OrderItemDTO} incluidos en esta orden.
     */
    private List<OrderItemDTO> items;

    /**
     * Monto total final de la orden, incluyendo impuestos y costos de envío (si aplica).
     */
    private BigDecimal totalAmount;

    /**
     * Estado actual de la orden (ej. "PENDING", "PROCESSING", "COMPLETED", "CANCELED").
     */
    private String status;

    /**
     * Dirección de envío registrada para esta orden.
     */
    private String shippingAddress;

    /**
     * Marca de tiempo de la creación de la orden.
     */
    private LocalDateTime createdAt;

    /**
     * Marca de tiempo de la última actualización del estado de la orden.
     */
    private LocalDateTime updatedAt;
}