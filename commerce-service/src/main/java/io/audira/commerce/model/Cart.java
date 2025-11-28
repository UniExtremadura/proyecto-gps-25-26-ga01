package io.audira.commerce.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Entidad de base de datos que representa el carrito de compras de un usuario.
 * <p>
 * Mapeada a la tabla {@code carts}. Un carrito contiene una lista de {@link CartItem}
 * y es único por usuario. La lógica para calcular el monto total se implementa directamente
 * en los métodos del ciclo de vida de JPA.
 * </p>
 *
 * @author Grupo GA01
 * @see CartItem
 * @see Entity
 * 
 */
@Entity
@Table(name = "carts")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Cart {

    /**
     * ID primario y clave única de la entidad Cart. Generado automáticamente.
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * ID del usuario al que pertenece este carrito. Es único para asegurar que un usuario solo
     * pueda tener un carrito activo a la vez.
     */
    @Column(nullable = false, unique = true)
    private Long userId;

    /**
     * Lista de artículos {@link CartItem} contenidos en el carrito.
     * <p>
     * Relación {@code OneToMany}:
     * <ul>
     * <li>{@code cascade = CascadeType.ALL}: Las operaciones (guardar, actualizar, eliminar) se propagan a los ítems.</li>
     * <li>{@code orphanRemoval = true}: Si se elimina un ítem de la lista, se elimina de la base de datos.</li>
     * <li>{@code fetch = FetchType.LAZY}: Los ítems se cargan solo cuando son accedidos.</li>
     * </ul>
     * {@code @JoinColumn(name = "cartId")} indica que la columna de clave foránea está en la tabla {@code CartItem}.
     * </p>
     */
    @OneToMany(cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @JoinColumn(name = "cartId")
    @Builder.Default
    private List<CartItem> items = new ArrayList<>();

    /**
     * Monto total calculado de todos los artículos en el carrito.
     * <p>
     * Se recalcula automáticamente en {@link #onCreate()} y {@link #onUpdate()}.
     * </p>
     */
    @Column(nullable = false)
    @Builder.Default
    private BigDecimal totalAmount = BigDecimal.ZERO;

    /**
     * Marca de tiempo de la creación inicial del carrito.
     */
    @Column(nullable = false)
    private LocalDateTime createdAt;

    /**
     * Marca de tiempo de la última actualización del carrito.
     */
    private LocalDateTime updatedAt;

    /**
     * Método de callback de JPA que se ejecuta antes de la persistencia (guardar por primera vez).
     * <p>
     * Inicializa {@code createdAt}, {@code updatedAt} y asegura que {@code totalAmount} esté calculado.
     * </p>
     */
    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
        calculateTotalAmount();
    }

    /**
     * Método de callback de JPA que se ejecuta antes de cualquier actualización.
     * <p>
     * Actualiza {@code updatedAt} y recalcula {@code totalAmount}.
     * </p>
     */
    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
        calculateTotalAmount();
    }

    /**
     * Recalcula el monto total del carrito sumando el precio * cantidad de todos los {@link CartItem}.
     */
    public void calculateTotalAmount() {
        this.totalAmount = items.stream()
                .map(item -> item.getPrice().multiply(BigDecimal.valueOf(item.getQuantity())))
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    /**
     * Obtiene el número total de unidades de artículos en el carrito (suma de las cantidades de todos los ítems).
     *
     * @return La suma total de las cantidades de todos los artículos.
     */
    public int getTotalItems() {
        return items.stream()
                .mapToInt(CartItem::getQuantity)
                .sum();
    }
}