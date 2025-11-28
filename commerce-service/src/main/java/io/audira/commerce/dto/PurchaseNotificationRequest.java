package io.audira.commerce.dto;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

/**
 * Data Transfer Object (DTO) utilizado para solicitar el procesamiento de notificaciones
 * después de que una compra ha sido exitosa.
 * <p>
 * Este objeto es enviado por el servicio de Órdenes o Pagos al servicio de Notificaciones
 * para disparar las notificaciones push al comprador y al artista/vendedor.
 * </p>
 * <p>
 * Incluye todos los IDs de referencia y detalles del comprador y los artículos adquiridos.
 * </p>
 *
 * @author Grupo GA01
 * @see PurchasedItemInfo
 * 
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PurchaseNotificationRequest {

    /**
     * ID de la orden (tipo {@link Long}) asociada a esta compra.
     * <p>
     * Restricción: No puede ser nulo ({@code @NotNull}).
     * </p>
     */
    @NotNull(message = "Order ID is required")
    private Long orderId;

    /**
     * ID del registro de pago (tipo {@link Long}) que confirmó la transacción.
     * <p>
     * Restricción: No puede ser nulo ({@code @NotNull}).
     * </p>
     */
    @NotNull(message = "Payment ID is required")
    private Long paymentId;

    /**
     * ID del usuario comprador (tipo {@link Long}).
     * <p>
     * Restricción: No puede ser nulo ({@code @NotNull}).
     * </p>
     */
    @NotNull(message = "Buyer ID is required")
    private Long buyerId;

    /**
     * Nombre visible del comprador (utilizado para notificar al artista).
     */
    private String buyerName;

    /**
     * Monto total de la orden de compra.
     * <p>
     * Restricción: No puede ser nulo ({@code @NotNull}).
     * </p>
     */
    @NotNull(message = "Total amount is required")
    private BigDecimal totalAmount;

    /**
     * Lista de los artículos adquiridos en la transacción, incluyendo detalles para la notificación.
     * <p>
     * Restricción: La lista no puede ser nula ({@code @NotNull}).
     * </p>
     */
    @NotNull(message = "Purchased items are required")
    private List<PurchasedItemInfo> purchasedItems;

    /**
     * Clase interna estática que representa la información mínima de un artículo comprado
     * necesaria para generar notificaciones para el artista/vendedor.
     *
     * @author TuNombre o Audira Team
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PurchasedItemInfo {
        /**
         * ID único del artículo en el catálogo.
         */
        private Long itemId;
        
        /**
         * Tipo de artículo (ej. SONG, ALBUM).
         */
        private String itemType; 
        
        /**
         * Nombre o título del artículo.
         */
        private String itemName;
        
        /**
         * ID del artista o vendedor propietario del artículo.
         */
        private Long artistId;
        
        /**
         * Precio unitario final del artículo.
         */
        private BigDecimal price;
        
        /**
         * Cantidad comprada.
         */
        private Integer quantity;
    }
}