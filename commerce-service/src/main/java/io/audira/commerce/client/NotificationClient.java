package io.audira.commerce.client;

import io.audira.commerce.service.FirebaseMessagingService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * Cliente de fachada para el envío de notificaciones push a través de Firebase Cloud Messaging (FCM).
 * <p>
 * Esta clase actúa como una capa de abstracción sobre {@link FirebaseMessagingService},
 * proporcionando métodos específicos y de alto nivel para eventos comunes de comercio
 * (compras, fallos y reembolsos).
 * </p>
 *
 * @author Grupo GA01
 * @see FirebaseMessagingService
 * 
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class NotificationClient {

    /**
     * Servicio subyacente responsable de la comunicación directa con la API de Firebase.
     * Se inyecta automáticamente gracias a {@link RequiredArgsConstructor}.
     */
    private final FirebaseMessagingService fcmService;

    /**
     * Envía una notificación push genérica a un usuario usando Firebase Cloud Messaging (FCM).
     * <p>
     * Este es el método base de la clase. Captura cualquier excepción para evitar interrumpir
     * el flujo principal de la aplicación (e.g., el procesamiento de la compra).
     * </p>
     *
     * @param userId ID del usuario destinatario (tipo {@link Long}).
     * @param title Título visible de la notificación.
     * @param message Mensaje (cuerpo) de la notificación.
     * @param type Tipo de notificación (e.g., "SUCCESS", "INFO", "WARNING", "ERROR", o un identificador custom).
     * @return {@code true} si la llamada al servicio FCM fue exitosa o se manejó sin lanzar excepción, {@code false} en caso contrario.
     */
    public boolean sendNotification(Long userId, String title, String message, String type) {
        try {
            log.info("Sending FCM notification to user {}: {}", userId, title);

            // Enviar notificación FCM
            // Nota: Los últimos dos parámetros (null, null) son campos de datos opcionales
            return fcmService.sendNotification(userId, title, message, type, null, null);

        } catch (Exception e) {
            log.error("Error sending FCM notification to user {}: {}", userId, e.getMessage());
            // No lanzamos excepción para no interrumpir el flujo principal
            return false;
        }
    }

    /**
     * Notifica a un artista sobre una nueva compra realizada de su producto.
     * <p>
     * Construye un mensaje detallado con información sobre el comprador, el producto y el monto.
     * </p>
     *
     * @param artistId ID del artista (vendedor) destinatario (tipo {@link Long}).
     * @param productType Tipo de producto comprado (e.g., "Álbum", "Pista", "Merchandise").
     * @param productTitle Título del producto comprado.
     * @param buyerName Nombre del usuario que realizó la compra.
     * @param amount Monto total de la compra (tipo {@link Double}).
     * @param orderNumber Número de identificación del pedido.
     * @return {@code true} si el intento de envío de notificación fue exitoso, {@code false} en caso contrario.
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
     * Notifica a un usuario sobre la confirmación y éxito de su compra.
     * <p>
     * Informa al usuario que el pedido ha sido procesado y que los productos están disponibles.
     * </p>
     *
     * @param userId ID del usuario comprador (tipo {@link Long}).
     * @param orderNumber Número de identificación del pedido.
     * @param amount Monto total pagado (tipo {@link Double}).
     * @return {@code true} si el intento de envío de notificación fue exitoso, {@code false} en caso contrario.
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
     * Notifica a un usuario sobre el fallo de su intento de compra.
     * <p>
     * Advierte al usuario sobre el problema y asegura que no se realizó ningún cargo.
     * </p>
     *
     * @param userId ID del usuario comprador (tipo {@link Long}).
     * @param orderNumber Número de identificación del pedido.
     * @param reason Razón o descripción del fallo de la transacción.
     * @return {@code true} si el intento de envío de notificación fue exitoso, {@code false} en caso contrario.
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
     * Notifica a un usuario (comprador) sobre un reembolso procesado.
     * <p>
     * Detalla el monto y el tiempo estimado para que el dinero sea devuelto al medio de pago.
     * </p>
     *
     * @param userId ID del usuario comprador (tipo {@link Long}).
     * @param orderNumber Número de identificación del pedido.
     * @param amount Monto reembolsado (tipo {@link Double}).
     * @return {@code true} si el intento de envío de notificación fue exitoso, {@code false} en caso contrario.
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
     * Notifica al artista (vendedor) sobre un reembolso procesado de su producto.
     * <p>
     * Advierte al artista que los fondos correspondientes serán deducidos de sus próximas ganancias.
     * </p>
     *
     * @param artistId ID del artista (vendedor) destinatario (tipo {@link Long}).
     * @param productTitle Título del producto reembolsado.
     * @param orderNumber Número de identificación del pedido.
     * @return {@code true} si el intento de envío de notificación fue exitoso, {@code false} en caso contrario.
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