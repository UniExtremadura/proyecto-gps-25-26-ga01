package io.audira.commerce.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Entidad de base de datos que representa una notificación destinada a la bandeja de entrada de un usuario.
 * <p>
 * Mapeada a la tabla {@code notifications}. Almacena el contenido, el estado de lectura/envío,
 * y referencias a otros elementos del sistema para fines de trazabilidad.
 * </p>
 *
 * @author Grupo GA01
 * @see NotificationType
 * @see Entity
 * 
 */
@Entity
@Table(name = "notifications")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Notification {

    /**
     * ID primario y clave única de la entidad Notification. Generado automáticamente.
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * ID del usuario destinatario de la notificación.
     */
    @Column(name = "user_id", nullable = false)
    private Long userId;

    /**
     * Tipo o categoría de la notificación (ej. SYSTEM, PROMOTION) utilizando el enumerador {@link NotificationType}.
     * <p>
     * Mapeado como String en la base de datos ({@code @Enumerated(EnumType.STRING)}).
     * </p>
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private NotificationType type;

    /**
     * Título visible de la notificación.
     */
    @Column(nullable = false)
    private String title;

    /**
     * Cuerpo principal del mensaje de la notificación.
     * <p>
     * Utiliza {@code columnDefinition = "TEXT"} para permitir mensajes largos.
     * </p>
     */
    @Column(columnDefinition = "TEXT")
    private String message;

    /**
     * ID de un objeto relacionado en el sistema (ej. ID de una Orden, {@link Payment}, etc.).
     */
    @Column(name = "reference_id")
    private Long referenceId;

    /**
     * Tipo de objeto al que hace referencia {@code referenceId} (ej. "ORDER", "PAYMENT").
     */
    @Column(name = "reference_type")
    private String referenceType;

    /**
     * Indica si el usuario ha marcado la notificación como leída.
     * <p>
     * Valor por defecto: {@code false}.
     * </p>
     */
    @Column(name = "is_read", nullable = false)
    @Builder.Default
    private Boolean isRead = false;

    /**
     * Indica si la notificación fue procesada y enviada a través de un canal push (ej. FCM).
     * <p>
     * Valor por defecto: {@code false}.
     * </p>
     */
    @Column(name = "is_sent", nullable = false)
    @Builder.Default
    private Boolean isSent = false;

    /**
     * Marca de tiempo de la fecha y hora en que la notificación fue enviada (o el intento de envío).
     */
    @Column(name = "sent_at")
    private LocalDateTime sentAt;

    /**
     * Marca de tiempo de la fecha y hora en que el usuario marcó la notificación como leída.
     */
    @Column(name = "read_at")
    private LocalDateTime readAt;

    /**
     * Marca de tiempo de la creación inicial del registro de la notificación.
     */
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    /**
     * Campo de metadatos opcional para almacenar información adicional no estructurada (ej. deep links, datos de payload).
     * <p>
     * Mapeado como texto para JSON o datos largos.
     * </p>
     */
    @Column(columnDefinition = "TEXT")
    private String metadata;

    /**
     * Método de callback de JPA que se ejecuta antes de la persistencia (guardar por primera vez).
     * <p>
     * Inicializa {@code createdAt}.
     * </p>
     */
    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }
}