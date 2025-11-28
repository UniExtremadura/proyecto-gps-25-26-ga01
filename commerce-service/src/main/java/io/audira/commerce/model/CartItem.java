package io.audira.commerce.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Entidad de base de datos que representa un artículo específico dentro de un {@link Cart}.
 * <p>
 * Mapeada a la tabla {@code cart_items}. Esta entidad asegura la **unicidad**
 * de un artículo dentro de un carrito mediante una restricción compuesta por {@code cartId},
 * {@code itemType} y {@code itemId}.
 * </p>
 *
 * @author Grupo GA01
 * @see Cart
 * @see ItemType
 * @see Entity
 * 
 */
@Entity
@Table(name = "cart_items", uniqueConstraints = {
        @UniqueConstraint(columnNames = {"cartId", "itemType", "itemId"})
})
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CartItem {

    /**
     * ID primario y clave única de la entidad CartItem. Generado automáticamente.
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * ID de la clave foránea que apunta a la entidad {@link Cart} padre.
     * <p>
     * Nota: Aunque es una clave foránea, se mapea directamente como una columna de ID en esta entidad.
     * </p>
     */
    @Column(nullable = false)
    private Long cartId;

    /**
     * Tipo de artículo (ej. SONG, ALBUM).
     * <p>
     * Mapeado como String en la base de datos ({@code @Enumerated(EnumType.STRING)}) para mayor legibilidad y estabilidad.
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
     * Cantidad de unidades de este artículo.
     */
    @Column(nullable = false)
    private Integer quantity;

    /**
     * Precio unitario del artículo al momento de ser añadido al carrito.
     */
    @Column(nullable = false)
    private BigDecimal price;

    /**
     * Marca de tiempo de la creación inicial del registro.
     */
    @Column(nullable = false)
    private LocalDateTime createdAt;

    /**
     * Marca de tiempo de la última actualización del registro (ej. al cambiar la cantidad).
     */
    private LocalDateTime updatedAt;

    /**
     * Método de callback de JPA que se ejecuta antes de la persistencia (guardar por primera vez).
     * <p>
     * Inicializa {@code createdAt} y {@code updatedAt}.
     * </p>
     */
    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }

    /**
     * Método de callback de JPA que se ejecuta antes de cualquier actualización.
     * <p>
     * Actualiza {@code updatedAt}.
     * </p>
     */
    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    /**
     * Calcula el subtotal de este artículo (precio unitario * cantidad).
     *
     * @return El subtotal de la línea como {@link BigDecimal}.
     */
    public BigDecimal getSubtotal() {
        return price.multiply(BigDecimal.valueOf(quantity));
    }
}