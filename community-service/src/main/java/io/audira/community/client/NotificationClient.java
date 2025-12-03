package io.audira.community.client;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;

/**
 * Cliente REST para la comunicación con el microservicio de Notificaciones (dentro del Commerce Service).
 * <p>
 * Este cliente se utiliza para disparar notificaciones de sistema o transaccionales a usuarios
 * enviando una solicitud POST al endpoint central de notificaciones.
 * </p>
 *
 * @author Grupo GA01
 * @see RestTemplate
 * 
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class NotificationClient {

    private final RestTemplate restTemplate;

    /**
     * URL base del endpoint de notificaciones del Commerce Service ({@code /api/notifications}).
     * El valor por defecto es {@code http://api-gateway:8080/api/notifications} (a través del API Gateway).
     */
    @Value("${services.commerce.url:http://api-gateway:8080/api/notifications}")
    private String notificationServiceUrl;

    /**
     * Envía una notificación genérica a un usuario específico.
     * <p>
     * Llama al endpoint {@code POST /api/notifications} con el cuerpo de la notificación en formato JSON.
     * </p>
     *
     * @param userId ID del usuario (tipo {@link Long}) destinatario.
     * @param title Título de la notificación.
     * @param message Mensaje (cuerpo) de la notificación.
     * @param type Tipo de notificación (String, ej. "TICKET_RESPONSE", "PAYMENT_SUCCESS").
     * @return {@code true} si la solicitud REST fue exitosa (código 2xx), {@code false} en caso contrario (fallo de comunicación o código de error HTTP).
     */
    public boolean sendNotification(Long userId, String title, String message, String type) {
        try {
            log.info("📤 Sending notification to user {} (type: {}): {}", userId, type, title);
            log.debug("Notification URL: {}", notificationServiceUrl);

            // 1. Preparar el cuerpo de la solicitud JSON
            Map<String, Object> notificationRequest = new HashMap<>();
            notificationRequest.put("userId", userId);
            notificationRequest.put("title", title);
            notificationRequest.put("message", message);
            notificationRequest.put("type", type);

            // 2. Configurar cabeceras
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            // 3. Crear la entidad de solicitud
            HttpEntity<Map<String, Object>> request = new HttpEntity<>(notificationRequest, headers);

            // 4. Ejecutar la llamada REST
            ResponseEntity<Map<String, Object>> response = restTemplate.exchange(
                notificationServiceUrl,
                HttpMethod.POST,
                request,
                new ParameterizedTypeReference<Map<String, Object>>() {}
            );

            if (response.getStatusCode().is2xxSuccessful()) {
                log.info("✅ Notification sent successfully to user {}", userId);
                return true;
            } else {
                log.warn("⚠️  Failed to send notification to user {}. Status: {}",
                    userId, response.getStatusCode());
                return false;
            }

        } catch (org.springframework.web.client.ResourceAccessException e) {
            log.error("❌ Cannot reach notification service at {}. Is commerce-service running? Error: {}",
                notificationServiceUrl, e.getMessage());
            return false;
        } catch (org.springframework.web.client.HttpClientErrorException e) {
            log.error("❌ HTTP error sending notification to user {}. Status: {}, Response: {}",
                userId, e.getStatusCode(), e.getResponseBodyAsString());
            return false;
        } catch (Exception e) {
            log.error("❌ Unexpected error sending notification to user {}: {}", userId, e.getMessage());
            log.debug("Full error:", e);
            return false;
        }
    }

    /**
     * Envía una notificación al administrador sobre la creación de un nuevo ticket de soporte.
     * <p>
     * Utiliza el tipo {@code TICKET_CREATED}.
     * </p>
     *
     * @param adminId ID del usuario administrador destinatario.
     * @param userName Nombre del usuario que creó el ticket.
     * @param subject Asunto o título del ticket.
     * @return {@code true} si se envió correctamente.
     */
    public boolean notifyAdminNewTicket(Long adminId, String userName, String subject) {
        String title = "Nuevo ticket de soporte";
        String message = String.format(
            "%s ha creado un nuevo ticket: \"%s\"",
            userName,
            subject
        );

        return sendNotification(adminId, title, message, "TICKET_CREATED");
    }

    /**
     * Envía una notificación al usuario indicando que el equipo de soporte ha respondido a su ticket.
     * <p>
     * Utiliza el tipo {@code TICKET_RESPONSE}.
     * </p>
     *
     * @param userId ID del usuario destinatario.
     * @param subject Asunto o título del ticket.
     * @return {@code true} si se envió correctamente.
     */
    public boolean notifyUserTicketResponse(Long userId, String subject) {
        String title = "Respuesta a tu ticket";
        String message = String.format(
            "El equipo de soporte ha respondido a tu ticket: \"%s\"",
            subject
        );

        return sendNotification(userId, title, message, "TICKET_RESPONSE");
    }

    /**
     * Envía una notificación al usuario informando que su ticket ha sido marcado como resuelto.
     * <p>
     * Utiliza el tipo {@code TICKET_RESOLVED}.
     * </p>
     *
     * @param userId ID del usuario destinatario.
     * @param subject Asunto o título del ticket.
     * @return {@code true} si se envió correctamente.
     */
    public boolean notifyUserTicketResolved(Long userId, String subject) {
        String title = "Ticket resuelto";
        String message = String.format(
            "Tu ticket \"%s\" ha sido marcado como resuelto",
            subject
        );

        return sendNotification(userId, title, message, "TICKET_RESOLVED");
    }
}