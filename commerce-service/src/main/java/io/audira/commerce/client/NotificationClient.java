package io.audira.commerce.client;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;

/**
 * Cliente REST para comunicación con Community Service - Notificaciones
 * Envía notificaciones cuando se realizan compras
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class NotificationClient {

    private final RestTemplate restTemplate;

    @Value("${services.notification.url:http://172.16.0.4:9001/api/notifications}")
    private String notificationServiceUrl;

    /**
     * Envía una notificación a un usuario
     * 
     * @param userId ID del usuario destinatario
     * @param title Título de la notificación
     * @param message Mensaje de la notificación
     * @param type Tipo de notificación (SUCCESS, INFO, WARNING, ERROR)
     * @return true si se envió correctamente, false en caso contrario
     */
    public boolean sendNotification(Long userId, String title, String message, String type) {
        try {
            String url = notificationServiceUrl;

            log.info("Sending notification to user {}: {}", userId, title);

            Map<String, Object> notificationRequest = new HashMap<>();
            notificationRequest.put("userId", userId);
            notificationRequest.put("title", title);
            notificationRequest.put("message", message);
            notificationRequest.put("type", type);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            HttpEntity<Map<String, Object>> request = new HttpEntity<>(notificationRequest, headers);

            @SuppressWarnings("rawtypes")
            ResponseEntity<Map> response = restTemplate.exchange(
                url,
                HttpMethod.POST,
                request,
                Map.class
            );

            if (response.getStatusCode().is2xxSuccessful()) {
                log.info("Notification sent successfully to user {}", userId);
                return true;
            } else {
                log.warn("Failed to send notification to user {}. Status: {}", 
                    userId, response.getStatusCode());
                return false;
            }

        } catch (Exception e) {
            log.error("Error sending notification to user {}: {}", userId, e.getMessage());
            // No lanzamos excepción para no interrumpir el flujo principal
            return false;
        }
    }

    /**
     * Notifica a un artista sobre una nueva compra
     */
    public boolean notifyArtistPurchase(Long artistId, String productType, String productTitle, 
                                       String buyerName, Double amount, String orderNumber) {
        String title = "🎉 Nueva compra realizada";
        String message = String.format(
            "%s ha comprado tu %s \"%s\" por $%.2f. Pedido: %s",
            buyerName, 
            productType.toLowerCase(), 
            productTitle, 
            amount,
            orderNumber
        );

        return sendNotification(artistId, title, message, "SUCCESS");
    }

    /**
     * Notifica a un usuario sobre una compra exitosa
     */
    public boolean notifyUserPurchaseSuccess(Long userId, String orderNumber, Double amount) {
        String title = "✅ Compra confirmada";
        String message = String.format(
            "Tu compra ha sido procesada exitosamente. Pedido: %s. Total: $%.2f. " +
            "Los productos están disponibles en tu biblioteca.",
            orderNumber,
            amount
        );

        return sendNotification(userId, title, message, "SUCCESS");
    }

    /**
     * Notifica a un usuario sobre una compra fallida
     */
    public boolean notifyUserPurchaseFailed(Long userId, String orderNumber, String reason) {
        String title = "❌ Error en la compra";
        String message = String.format(
            "No se pudo procesar tu compra (Pedido: %s). Razón: %s. " +
            "No se realizó ningún cargo. Por favor, intenta nuevamente.",
            orderNumber,
            reason
        );

        return sendNotification(userId, title, message, "ERROR");
    }

    /**
     * Notifica a un usuario sobre un reembolso
     */
    public boolean notifyUserRefund(Long userId, String orderNumber, Double amount) {
        String title = "💰 Reembolso procesado";
        String message = String.format(
            "Se ha procesado un reembolso de $%.2f para tu pedido %s. " +
            "El dinero será devuelto a tu método de pago original en 5-10 días hábiles.",
            amount,
            orderNumber
        );

        return sendNotification(userId, title, message, "INFO");
    }

    /**
     * Notifica al artista sobre un reembolso
     */
    public boolean notifyArtistRefund(Long artistId, String productTitle, String orderNumber) {
        String title = "⚠️ Reembolso procesado";
        String message = String.format(
            "Se ha procesado un reembolso para \"%s\" (Pedido: %s). " +
            "Los fondos serán deducidos de tus próximas ventas.",
            productTitle,
            orderNumber
        );

        return sendNotification(artistId, title, message, "WARNING");
    }
}
