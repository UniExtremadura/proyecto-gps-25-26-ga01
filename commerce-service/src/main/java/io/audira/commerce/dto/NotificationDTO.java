package io.audira.commerce.dto;

import io.audira.commerce.model.NotificationType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Data Transfer Object (DTO) que representa una notificación destinada a la bandeja de entrada de un usuario.
 * <p>
 * Este objeto encapsula el contenido (título, mensaje), el tipo, el estado de lectura/envío,
 * y referencias a otros elementos del sistema. Se utiliza para transferir datos a los
 * clientes del API.
 * </p>
 *
 * @author Grupo GA01
 * @see NotificationType
 * 
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificationDTO {

    /**
     * ID único de la notificación.
     */
    private Long id;

    /**
     * ID del usuario destinatario de la notificación.
     */
    private Long userId;

    /**
     * Tipo o categoría de la notificación (ej. SYSTEM, PROMOTION, PURCHASE) usando el enumerador {@link NotificationType}.
     */
    private NotificationType type;

    /**
     * Título visible de la notificación.
     */
    private String title;

    /**
     * Cuerpo principal del mensaje de la notificación.
     */
    private String message;

    /**
     * ID de un objeto relacionado en el sistema (ej. ID de una Orden o ID de un Artículo).
     * Permite que la aplicación redirija al usuario a la vista relevante.
     */
    private Long referenceId;

    /**
     * Tipo de objeto al que hace referencia {@code referenceId} (ej. "ORDER", "ALBUM").
     */
    private String referenceType;

    /**
     * Indica si el usuario ha marcado la notificación como leída ({@code true}) o no ({@code false}).
     */
    private Boolean isRead;

    /**
     * Indica si la notificación fue procesada y enviada al sistema de mensajería push (FCM) ({@code true}) o si solo es de bandeja de entrada.
     */
    private Boolean isSent;

    /**
     * Marca de tiempo en la que la notificación fue enviada (o el intento de envío fue realizado).
     */
    private LocalDateTime sentAt;

    /**
     * Marca de tiempo en la que el usuario marcó la notificación como leída. Es nulo si {@code isRead} es falso.
     */
    private LocalDateTime readAt;

    /**
     * Marca de tiempo de la creación inicial del registro de la notificación.
     */
    private LocalDateTime createdAt;

    /**
     * Campo JSON opcional para almacenar datos adicionales no estructurados (ej. datos del icono, colores, deep link).
     */
    private String metadata;
}