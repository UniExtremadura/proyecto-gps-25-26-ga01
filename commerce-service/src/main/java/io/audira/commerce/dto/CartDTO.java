package io.audira.commerce.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Data Transfer Object (DTO) que representa el carrito de compras de un usuario.
 * <p>
 * Este objeto se utiliza para transferir datos del carrito entre la capa de servicio
 * y los controladores REST, o entre microservicios. Incluye el ID del usuario,
 * la lista de artículos y el total calculado.
 * </p>
 * <p>
 * Las anotaciones de Lombok {@code @Data}, {@code @Builder}, {@code @NoArgsConstructor}
 * y {@code @AllArgsConstructor} se utilizan para generar automáticamente los getters,
 * setters, métodos de construcción y constructores.
 * </p>
 *
 * @author Grupo GA01
 * 
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CartDTO {

    /**
     * ID único del carrito de compras.
     */
    private Long id;

    /**
     * ID del usuario al que pertenece el carrito.
     */
    private Long userId;

    /**
     * Lista de artículos {@link CartItemDTO} actualmente contenidos en el carrito.
     */
    private List<CartItemDTO> items;

    /**
     * Monto total del carrito, calculado a partir de la suma de los precios de todos los artículos.
     */
    private BigDecimal totalAmount;

    /**
     * Marca de tiempo de la creación inicial del carrito.
     */
    private LocalDateTime createdAt;

    /**
     * Marca de tiempo de la última actualización del carrito (ej. al añadir o eliminar un artículo).
     */
    private LocalDateTime updatedAt;
}