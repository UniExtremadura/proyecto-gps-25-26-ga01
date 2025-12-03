package io.audira.catalog.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * DTO que representa un pedido de compra (Order) proveniente del servicio de Comercio.
 * <p>
 * Contiene la información de cabecera de una transacción, incluyendo el total monetario,
 * el estado del pago y la lista de ítems adquiridos.
 * </p>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OrderDTO {
    /**
     * Identificador interno del pedido (Primary Key).
     */
    private Long id;

    /**
     * ID del usuario comprador.
     */
    private Long userId;

    /**
     * Identificador de negocio único para el pedido.
     * <p>Ej: "ORD-2023-XYZ". Es el código que se muestra al usuario en su historial o facturas.</p>
     */
    private String orderNumber;

    /**
     * Lista detallada de los productos incluidos en este pedido.
     */
    private List<OrderItemDTO> items;

    /**
     * Monto total de la transacción.
     */
    private BigDecimal totalAmount;

    /**
     * Estado actual del pedido.
     * <p>Ej: {@code PENDING}, {@code COMPLETED}, {@code CANCELLED}, {@code REFUNDED}.</p>
     */
    private String status;

    /**
     * Fecha y hora en la que se inició el pedido.
     */
    private LocalDateTime createdAt;

    /**
     * Fecha y hora de la última actualización de estado.
     */
    private LocalDateTime updatedAt;
}
