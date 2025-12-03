package io.audira.commerce.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Entidad de base de datos que representa una Orden de Compra (Order) en el sistema.
 * <p>
 * Mapeada a la tabla {@code orders}. Una orden es la representación de una transacción de compra
 * e incluye los detalles de los artículos adquiridos, el monto total y el estado de procesamiento.
 * </p>
 *
 * @author Grupo GA01
 * @see OrderItem
 * @see OrderStatus
 * @see Entity
 * 
 */
@Entity
@Table(name = "orders")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Order {

    /**
     * ID primario y clave única de la entidad Order. Generado automáticamente.
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * ID del usuario (tipo {@link Long}) que realizó la orden de compra.
     */
    @Column(nullable = false)
    private Long userId;

    /**
     * Número de orden único y legible (String) utilizado para referencia externa (ej. en facturas o emails).
     */
    @Column(nullable = false, unique = true)
    private String orderNumber;

    /**
     * Lista de artículos {@link OrderItem} incluidos en esta orden.
     * <p>
     * Relación {@code OneToMany}: Las operaciones (guardar, actualizar, eliminar) se propagan a los ítems ({@code CascadeType.ALL}).
     * La columna de clave foránea {@code orderId} se encuentra en la tabla {@code OrderItem}.
     * </p>
     */
    @OneToMany(cascade = CascadeType.ALL, orphanRemoval = true)
    @JoinColumn(name = "orderId")
    @Builder.Default
    private List<OrderItem> items = new ArrayList<>();

    /**
     * Monto total final (tipo {@link BigDecimal}) de la orden.
     */
    @Column(nullable = false)
    private BigDecimal totalAmount;

    /**
     * Estado actual de la orden (ej. PENDING, SHIPPED, COMPLETED) utilizando el enumerador {@link OrderStatus}.
     * <p>
     * Mapeado como String en la base de datos ({@code @Enumerated(EnumType.STRING)}).
     * </p>
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private OrderStatus status;

    /**
     * Dirección de envío registrada para esta orden.
     * <p>
     * Se permite una longitud máxima de 1000 caracteres.
     * </p>
     */
    @Column(nullable = false, length = 1000)
    private String shippingAddress;

    /**
     * Marca de tiempo de la creación inicial de la orden.
     */
    @Column(nullable = false)
    private LocalDateTime createdAt;

    /**
     * Marca de tiempo de la última actualización del estado o detalles de la orden.
     */
    private LocalDateTime updatedAt;

    /**
     * Método de callback de JPA que se ejecuta antes de la persistencia (guardar por primera vez).
     * <p>
     * 1. Inicializa {@code createdAt} y {@code updatedAt} utilizando la zona horaria "Europe/Madrid".
     * 2. Si el estado es nulo, lo establece en {@code OrderStatus.PENDING}.
     * </p>
     */
    @PrePersist
    protected void onCreate() {
        // Asegura la consistencia horaria en Madrid
        ZonedDateTime now = ZonedDateTime.now(ZoneId.of("Europe/Madrid"));
        this.createdAt = now.toLocalDateTime();
        this.updatedAt = now.toLocalDateTime();
        if (this.status == null) {
            this.status = OrderStatus.PENDING;
        }
    }

    /**
     * Método de callback de JPA que se ejecuta antes de cualquier actualización.
     * <p>
     * Actualiza {@code updatedAt} utilizando la zona horaria "Europe/Madrid".
     * </p>
     */
    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = ZonedDateTime.now(ZoneId.of("Europe/Madrid")).toLocalDateTime();
    }
}