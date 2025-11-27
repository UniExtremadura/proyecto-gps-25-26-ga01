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
 * REST client for sending notifications to users
 * Communicates with Commerce Service notification endpoints
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class NotificationClient {

    private final RestTemplate restTemplate;

    @Value("${services.commerce.url:http://172.16.0.4:9003/api/notifications}")
    private String notificationServiceUrl;

    /**
     * Send a notification to a user
     *
     * @param userId User ID to receive notification
     * @param title Notification title
     * @param message Notification message
     * @param type Notification type
     * @return true if notification was sent successfully
     */
    public boolean sendNotification(Long userId, String title, String message, String type) {
        try {
            log.info("Sending notification to user {}: {}", userId, title);

            Map<String, Object> notificationRequest = new HashMap<>();
            notificationRequest.put("userId", userId);
            notificationRequest.put("title", title);
            notificationRequest.put("message", message);
            notificationRequest.put("type", type);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            HttpEntity<Map<String, Object>> request = new HttpEntity<>(notificationRequest, headers);

            ResponseEntity<Map<String, Object>> response = restTemplate.exchange(
                notificationServiceUrl,
                HttpMethod.POST,
                request,
                new ParameterizedTypeReference<Map<String, Object>>() {} 
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
            return false;
        }
    }

    /**
     * Notify admin that a new ticket was created
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
     * Notify user that admin responded to their ticket
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
     * Notify user that their ticket was resolved
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
