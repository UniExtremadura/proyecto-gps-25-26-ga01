package io.audira.commerce.client;

import io.audira.commerce.service.FirebaseMessagingService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * Cliente para envío de notificaciones usando Firebase Cloud Messaging
 * Envía notificaciones push cuando se realizan compras y otros eventos
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class NotificationClient {

    private final FirebaseMessagingService fcmService;

    /**
     * Envía una notificación a un usuario usando Firebase Cloud Messaging
     *
     * @param userId ID del usuario destinatario
     * @param title Título de la notificación
     * @param message Mensaje de la notificación
     * @param type Tipo de notificación (SUCCESS, INFO, WARNING, ERROR)
     * @return true si se envió correctamente, false en caso contrario
     */
    public boolean sendNotification(Long userId, String title, String message, String type) {
        try {
            log.info("Sending FCM notification to user {}: {}", userId, title);

            // Enviar notificación FCM
            return fcmService.sendNotification(userId, title, message, type, null, null);

        } catch (Exception e) {
            log.error("Error sending FCM notification to user {}: {}", userId, e.getMessage());
            // No lanzamos excepción para no interrumpir el flujo principal
            return false;
        }
    }

    /**
     * Notifica a un artista sobre una nueva compra
     */
    public boolean notifyArtistPurchase(Long artistId, String productType, String productTitle,
                                       String buyerName, Double amount, String orderNumber) {
        String title = "Nueva compra realizada";
        String message = String.format(
            "%s ha comprado tu %s \"%s\" por $%.2f. Pedido: %s",
            buyerName,
            productType.toLowerCase(),
            productTitle,
            amount,
            orderNumber
        );

        return sendNotification(artistId, title, message, "PURCHASE_NOTIFICATION");
    }

    /**
     * Notifica a un usuario sobre una compra exitosa
     */
    public boolean notifyUserPurchaseSuccess(Long userId, String orderNumber, Double amount) {
        String title = "Compra confirmada";
        String message = String.format(
            "Tu compra ha sido procesada exitosamente. Pedido: %s. Total: $%.2f. " +
            "Los productos están disponibles en tu biblioteca.",
            orderNumber,
            amount
        );

        return sendNotification(userId, title, message, "PAYMENT_SUCCESS");
    }

    /**
     * Notifica a un usuario sobre una compra fallida
     */
    public boolean notifyUserPurchaseFailed(Long userId, String orderNumber, String reason) {
        String title = "Error en la compra";
        String message = String.format(
            "No se pudo procesar tu compra (Pedido: %s). Razón: %s. " +
            "No se realizó ningún cargo. Por favor, intenta nuevamente.",
            orderNumber,
            reason
        );

        return sendNotification(userId, title, message, "PAYMENT_FAILED");
    }

    /**
     * Notifica a un usuario sobre un reembolso
     */
    public boolean notifyUserRefund(Long userId, String orderNumber, Double amount) {
        String title = "Reembolso procesado";
        String message = String.format(
            "Se ha procesado un reembolso de $%.2f para tu pedido %s. " +
            "El dinero será devuelto a tu método de pago original en 5-10 días hábiles.",
            amount,
            orderNumber
        );

        return sendNotification(userId, title, message, "SYSTEM_NOTIFICATION");
    }

    /**
     * Notifica al artista sobre un reembolso
     */
    public boolean notifyArtistRefund(Long artistId, String productTitle, String orderNumber) {
        String title = "Reembolso procesado";
        String message = String.format(
            "Se ha procesado un reembolso para \"%s\" (Pedido: %s). " +
            "Los fondos serán deducidos de tus próximas ventas.",
            productTitle,
            orderNumber
        );

        return sendNotification(artistId, title, message, "SYSTEM_NOTIFICATION");
    }
}
