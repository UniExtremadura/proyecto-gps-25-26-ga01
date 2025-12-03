package io.audira.commerce.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Entidad de base de datos que representa un artículo comprado y que forma parte de la biblioteca digital de un usuario.
 * <p>
 * Mapeada a la tabla {@code purchased_items}. Esta entidad es la fuente de verdad de la propiedad del contenido.
 * Asegura la **unicidad** de la posesión de un artículo por usuario, ya que un usuario solo debe tener un registro
 * único por {@code itemId} y {@code itemType}.
 * </p>
 *
 * @author Grupo GA01
 * @see ItemType
 * @see Entity
 * 
 */
@Entity
@Table(name = "purchased_items", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"user_id", "item_type", "item_id"})
})
@Data
@NoArgsConstructor
@AllArgsConstructor
public class PurchasedItem {

    /**
     * ID primario y clave única de la entidad PurchasedItem. Generado automáticamente.
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * ID del usuario propietario del artículo.
     */
    @Column(name = "user_id", nullable = false)
    private Long userId;

    /**
     * Tipo de artículo comprado (ej. SONG, ALBUM) utilizando el enumerador {@link ItemType}.
     * <p>
     * Mapeado como String en la base de datos ({@code @Enumerated(EnumType.STRING)}).
     * </p>
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "item_type", nullable = false)
    private ItemType itemType;

    /**
     * ID único del producto o servicio referenciado en el catálogo.
     */
    @Column(name = "item_id", nullable = false)
    private Long itemId;

    /**
     * ID de la orden de compra ({@link Long}) que resultó en la adquisición de este artículo.
     * <p>
     * Clave foránea transaccional.
     * </p>
     */
    @Column(name = "order_id", nullable = false)
    private Long orderId;

    /**
     * ID del registro de pago ({@link Long}) que confirmó la transacción.
     * <p>
     * Clave foránea transaccional.
     * </p>
     */
    @Column(name = "payment_id", nullable = false)
    private Long paymentId;

    /**
     * Precio unitario final del artículo al momento exacto de la compra.
     * <p>
     * Se define la precisión en la base de datos (10 dígitos en total, 2 decimales).
     * </p>
     */
    @Column(precision = 10, scale = 2, nullable = false)
    private BigDecimal price;

    /**
     * Cantidad de unidades de este artículo adquiridas. Para contenido digital, suele ser 1.
     */
    @Column(nullable = false)
    private Integer quantity;

    /**
     * Marca de tiempo de la fecha y hora en que se confirmó la compra y se creó el registro.
     * <p>
     * {@code @CreationTimestamp} de Hibernate asegura que el valor se establezca automáticamente
     * al momento de la inserción y que no pueda ser modificado ({@code updatable = false}).
     * </p>
     */
    @CreationTimestamp
    @Column(name = "purchased_at", nullable = false, updatable = false)
    private LocalDateTime purchasedAt;

    /**
     * Constructor utilizado para crear una nueva instancia de PurchasedItem con los detalles
     * transaccionales antes de la persistencia (el ID y el timestamp se añaden automáticamente).
     *
     * @param userId ID del usuario comprador.
     * @param itemType Tipo de artículo.
     * @param itemId ID del artículo en el catálogo.
     * @param orderId ID de la orden asociada.
     * @param paymentId ID del pago asociado.
     * @param price Precio unitario registrado.
     * @param quantity Cantidad adquirida.
     */
    public PurchasedItem(Long userId, ItemType itemType, Long itemId, Long orderId, Long paymentId, BigDecimal price, Integer quantity) {
        this.userId = userId;
        this.itemType = itemType;
        this.itemId = itemId;
        this.orderId = orderId;
        this.paymentId = paymentId;
        this.price = price;
        this.quantity = quantity;
    }
}