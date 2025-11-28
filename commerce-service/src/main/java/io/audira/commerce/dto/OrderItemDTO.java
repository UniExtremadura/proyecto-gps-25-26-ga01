package io.audira.commerce.dto;

import io.audira.commerce.model.ItemType;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Data Transfer Object (DTO) que representa un artículo individual incluido en una {@link OrderDTO}.
 * <p>
 * Este objeto contiene los detalles inmutables del artículo al momento de la compra (precio, cantidad),
 * así como referencias clave al catálogo ({@code itemId}) y al propietario ({@code artistId}).
 * </p>
 * <p>
 * Utiliza anotaciones de validación de Jakarta para asegurar la integridad de los datos.
 * </p>
 *
 * @author Grupo GA01
 * @see OrderDTO
 * @see ItemType
 * 
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OrderItemDTO {

    /**
     * ID único del registro del artículo en la orden.
     */
    private Long id;

    /**
     * ID de la orden (tipo {@link Long}) a la que pertenece este artículo, estableciendo la relación padre-hijo.
     */
    private Long orderId;
    
    /**
     * Tipo de artículo (ej. SONG, ALBUM) utilizando el enumerador {@link ItemType}.
     * <p>
     * Restricción: No puede ser nulo ({@code @NotNull}).
     * </p>
     */
    @NotNull(message = "ItemType cannot be null")
    private ItemType itemType;

    /**
     * ID único del producto o servicio referenciado en el catálogo.
     * <p>
     * Restricción: No puede ser nulo ({@code @NotNull}).
     * </p>
     */
    @NotNull(message = "ItemId cannot be null")
    private Long itemId;

    /**
     * ID del artista o vendedor propietario del artículo, utilizado para el cálculo de regalías.
     * <p>
     * Restricción: No puede ser nulo ({@code @NotNull}).
     * </p>
     */
    @NotNull(message = "ArtistId cannot be null")
    private Long artistId;

    /**
     * Cantidad de unidades de este artículo compradas.
     * <p>
     * Restricción: Debe ser un número entero positivo (mayor que cero) ({@code @Positive}).
     * </p>
     */
    @Positive(message = "Quantity must be positive")
    private int quantity;

    /**
     * Precio unitario final del artículo al momento de la compra.
     * <p>
     * Restricciones: No puede ser nulo ({@code @NotNull}) y debe ser un valor positivo ({@code @Positive}).
     * </p>
     */
    @NotNull(message = "Price cannot be null")
    @Positive(message = "Price must be positive")
    private BigDecimal price;
}