package io.audira.commerce.dto;

import io.audira.commerce.model.ItemType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Data Transfer Object (DTO) que representa un artículo individual dentro de un carrito de compras.
 * <p>
 * Este objeto define las características de un producto o servicio que ha sido añadido
 * al carrito por un usuario, incluyendo su tipo, ID y la cantidad deseada.
 * </p>
 * <p>
 * Las anotaciones de Lombok se utilizan para generar automáticamente constructores y métodos de acceso/modificación.
 * </p>
 *
 * @author Grupo GA01
 * @see CartDTO
 * @see ItemType
 * 
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CartItemDTO {

    /**
     * ID único del registro del artículo en el carrito.
     */
    private Long id;

    /**
     * ID del carrito (tipo {@link Long}) al que pertenece este artículo, estableciendo la relación padre-hijo.
     */
    private Long cartId;

    /**
     * Tipo de artículo (ej. ALBUM, SONG, ARTIST) utilizando el enumerador {@link ItemType}.
     */
    private ItemType itemType;

    /**
     * ID único del producto o servicio referenciado en el catálogo (ej. ID de la canción, ID del álbum).
     */
    private Long itemId;

    /**
     * Cantidad de unidades de este artículo en el carrito.
     */
    private Integer quantity;

    /**
     * Precio unitario del artículo al momento de ser añadido o actualizado en el carrito.
     */
    private BigDecimal price;
}