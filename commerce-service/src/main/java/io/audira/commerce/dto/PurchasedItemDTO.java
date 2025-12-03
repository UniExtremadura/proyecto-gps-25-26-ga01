package io.audira.commerce.dto;

import io.audira.commerce.model.ItemType;
import io.audira.commerce.model.PurchasedItem;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Data Transfer Object (DTO) que representa un artículo comprado y que forma parte de la biblioteca digital de un usuario.
 * <p>
 * Este objeto se utiliza para transferir datos de un artículo adquirido, incluyendo
 * las referencias transaccionales (orden y pago) y los detalles del producto.
 * </p>
 *
 * @author Grupo GA01
 * @see PurchasedItem
 * @see ItemType
 * 
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class PurchasedItemDTO {

    /**
     * ID único del registro del artículo comprado en la base de datos.
     */
    private Long id;

    /**
     * ID del usuario propietario del artículo.
     */
    private Long userId;

    /**
     * Tipo de artículo comprado (ej. SONG, ALBUM) utilizando el enumerador {@link ItemType}.
     */
    private ItemType itemType;

    /**
     * ID único del producto o servicio referenciado en el catálogo.
     */
    private Long itemId;

    /**
     * ID de la orden de compra ({@link Long}) a la que pertenece esta adquisición.
     */
    private Long orderId;

    /**
     * ID del registro de pago ({@link Long}) que financió esta adquisición.
     */
    private Long paymentId;

    /**
     * Precio unitario final al que se compró el artículo.
     */
    private BigDecimal price;

    /**
     * Cantidad de unidades de este artículo adquiridas.
     */
    private Integer quantity;

    /**
     * Marca de tiempo de la fecha y hora en que se confirmó la compra.
     */
    private LocalDateTime purchasedAt;

    /**
     * Convierte una entidad {@link PurchasedItem} de base de datos a un objeto {@link PurchasedItemDTO}.
     * <p>
     * Este método estático facilita el mapeo de los resultados de la base de datos antes de exponerlos a la API.
     * </p>
     *
     * @param item La entidad {@link PurchasedItem} de origen.
     * @return Una nueva instancia de {@link PurchasedItemDTO}.
     */
    public static PurchasedItemDTO fromEntity(PurchasedItem item) {
        return new PurchasedItemDTO(
            item.getId(),
            item.getUserId(),
            item.getItemType(),
            item.getItemId(),
            item.getOrderId(),
            item.getPaymentId(),
            item.getPrice(),
            item.getQuantity(),
            item.getPurchasedAt()
        );
    }
}