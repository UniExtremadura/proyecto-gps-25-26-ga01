package io.audira.commerce.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Entidad de base de datos que representa un artículo específico incluido en una {@link Order}.
 * <p>
 * Mapeada a la tabla {@code order_items}. Esta entidad registra los detalles exactos (precio, cantidad, tipo)
 * de un producto en el momento en que se realizó la compra, asegurando que la información transaccional sea inmutable.
 * </p>
 *
 * @author Grupo GA01
 * @see Order
 * @see ItemType
 * @see Entity
 * 
 */
@Entity
@Table(name = "order_items")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OrderItem {

    /**
     * ID primario y clave única de la entidad OrderItem. Generado automáticamente.
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * ID de la clave foránea que apunta a la entidad {@link Order} padre.
     */
    @Column(nullable = false)
    private Long orderId;

    /**
     * Tipo de artículo (ej. SONG, ALBUM) utilizando el enumerador {@link ItemType}.
     * <p>
     * Mapeado como String en la base de datos ({@code @Enumerated(EnumType.STRING)}).
     * </p>
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ItemType itemType;

    /**
     * ID del artículo referenciado en el catálogo (ej. ID de la canción).
     */
    @Column(nullable = false)
    private Long itemId;

    /**
     * ID del artista o vendedor propietario del artículo. Es esencial para el cálculo de regalías y pagos.
     */
    @Column(name = "artist_id") 
    private Long artistId; 
    
    /**
     * Cantidad de unidades de este artículo compradas.
     */
    @Column(nullable = false)
    private Integer quantity;

    /**
     * Precio unitario final del artículo al momento exacto de la compra.
     */
    @Column(nullable = false)
    private BigDecimal price;
}