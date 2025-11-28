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

/**
 * Entidad de base de datos que representa una transacción o registro de pago.
 * <p>
 * Mapeada a la tabla {@code payments}. Esta entidad registra los detalles de cada intento
 * de pago para una orden, incluyendo el método, el estado transaccional, el monto y los detalles de error.
 * El campo {@code transactionId} es crucial para la unicidad del registro.
 * </p>
 *
 * @author Grupo GA01
 * @see PaymentMethod
 * @see PaymentStatus
 * @see Entity
 * 
 */
@Entity
@Table(name = "payments")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Payment {

    /**
     * ID primario y clave única de la entidad Payment. Generado automáticamente.
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * ID de la transacción único (String) proporcionado por la pasarela de pago externa.
     * <p>
     * Este campo debe ser único en la base de datos para evitar doble procesamiento.
     * </p>
     */
    @Column(nullable = false, unique = true)
    private String transactionId;

    /**
     * ID de la orden (tipo {@link Long}) a la que se aplica este pago.
     */
    @Column(nullable = false)
    private Long orderId;

    /**
     * ID del usuario (tipo {@link Long}) que inició el pago.
     */
    @Column(nullable = false)
    private Long userId;

    /**
     * Método de pago utilizado (ej. CARD, PAYPAL) utilizando el enumerador {@link PaymentMethod}.
     * <p>
     * Mapeado como String en la base de datos ({@code @Enumerated(EnumType.STRING)}).
     * </p>
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private PaymentMethod paymentMethod;

    /**
     * Estado actual del pago (ej. PENDING, SUCCESS, FAILED) utilizando el enumerador {@link PaymentStatus}.
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private PaymentStatus status;

    /**
     * Monto exacto (tipo {@link BigDecimal}) que fue procesado.
     */
    @Column(nullable = false)
    private BigDecimal amount;

    /**
     * Mensaje de error detallado de la pasarela de pago, si el estado es FAILED.
     * <p>
     * Se limita la longitud a 500 caracteres.
     * </p>
     */
    @Column(length = 500)
    private String errorMessage;

    /**
     * Contador de reintentos de pago asociados a esta transacción.
     * <p>
     * Valor por defecto: 0.
     * </p>
     */
    @Column
    private Integer retryCount;

    /**
     * Campo de metadatos opcional (String JSON) para almacenar datos adicionales de la pasarela o la aplicación.
     * <p>
     * Se limita la longitud a 1000 caracteres.
     * </p>
     */
    @Column(length = 1000)
    private String metadata;

    /**
     * Marca de tiempo de la creación inicial del registro de pago.
     */
    @Column(nullable = false)
    private LocalDateTime createdAt;

    /**
     * Marca de tiempo de la última actualización del estado del pago.
     */
    private LocalDateTime updatedAt;

    /**
     * Marca de tiempo en la que el pago finalizó (ej. pasó a SUCCESS, FAILED o REFUNDED).
     */
    private LocalDateTime completedAt;

    /**
     * Método de callback de JPA que se ejecuta antes de la persistencia (guardar por primera vez).
     * <p>
     * 1. Inicializa {@code createdAt}, {@code updatedAt} y {@code completedAt} utilizando la zona horaria "Europe/Madrid".
     * 2. Si el estado es nulo, lo establece en {@code PaymentStatus.PENDING}.
     * 3. Si el contador de reintentos es nulo, lo establece en 0.
     * </p>
     */
    @PrePersist
    protected void onCreate() {
        // Asegura la consistencia horaria en Madrid para la transacción inicial
        ZonedDateTime now = ZonedDateTime.now(ZoneId.of("Europe/Madrid"));
        this.createdAt = now.toLocalDateTime();
        this.updatedAt = now.toLocalDateTime();
        this.completedAt = now.toLocalDateTime();
        if (this.status == null) {
            this.status = PaymentStatus.PENDING;
        }
        if (this.retryCount == null) {
            this.retryCount = 0;
        }
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
}