package io.audira.commerce.service;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.*;
import io.audira.commerce.model.FcmToken;
import io.audira.commerce.repository.FcmTokenRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;
import java.io.IOException;
import java.io.InputStream;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Servicio encargado de la inicialización del SDK de Firebase Admin y del envío de notificaciones push (FCM).
 * <p>
 * Este servicio gestiona la autenticación con Firebase mediante el archivo de credenciales
 * y proporciona métodos para enviar mensajes a tokens individuales, a múltiples tokens (multicast)
 * y a temas (topics). Incluye lógica para eliminar tokens inválidos.
 * </p>
 *
 * @author Grupo GA01
 * @see FirebaseMessaging
 * 
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class FirebaseMessagingService {

    private final FcmTokenRepository fcmTokenRepository;

    /**
     * Recurso que apunta al archivo JSON de credenciales de la cuenta de servicio de Firebase.
     * El valor por defecto se carga desde {@code classpath:firebase-service-account.json}.
     */
    @Value("${firebase.credentials-file:classpath:firebase-service-account.json}")
    private Resource firebaseCredentials;

    /**
     * Inicializa el SDK de Firebase Admin al arrancar el servicio.
     * <p>
     * Este método utiliza la anotación {@code @PostConstruct} para asegurar que la inicialización
     * ocurra después de que la inyección de dependencias se haya completado.
     * </p>
     */
    @PostConstruct
    public void initialize() {
        try {
            
            if (FirebaseApp.getApps().isEmpty()) {
                InputStream serviceAccount = firebaseCredentials.getInputStream();

                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                        .build();

                FirebaseApp.initializeApp(options);
                log.info("Firebase Admin SDK initialized successfully");
            }
        } catch (IOException e) {
            log.error("Failed to initialize Firebase Admin SDK: {}", e.getMessage());
            log.warn("FCM notifications will not work without proper Firebase configuration");
        }
    }

    /**
     * Envía una notificación a un usuario específico, intentando enviar el mensaje a todos
     * los dispositivos (tokens) registrados para ese usuario.
     *
     * @param userId El ID del usuario (tipo {@link Long}) destinatario.
     * @param title El título de la notificación.
     * @param message El cuerpo o mensaje de la notificación.
     * @param type El tipo de notificación (String, ej. "PURCHASE_NOTIFICATION").
     * @param referenceId ID de referencia (ej. ID de orden, opcional).
     * @param referenceType Tipo de referencia (ej. "ORDER", opcional).
     * @return {@code true} si al menos un mensaje fue enviado con éxito, {@code false} si no hay tokens o si todos fallaron.
     */
    public boolean sendNotification(Long userId, String title, String message,
                                    String type, Long referenceId, String referenceType) {
        try {
            List<FcmToken> tokens = fcmTokenRepository.findByUserId(userId);

            if (tokens.isEmpty()) {
                log.warn("No FCM tokens found for user {}", userId);
                return false;
            }

            int successCount = 0;
            int failureCount = 0;

            for (FcmToken fcmToken : tokens) {
                
                boolean sent = sendToToken(fcmToken.getToken(), title, message, type, referenceId, referenceType);
                if (sent) {
                    successCount++;
                } else {
                    failureCount++;
                }
            }

            log.info("Sent notifications to user {}: {} success, {} failures",
                userId, successCount, failureCount);

            return successCount > 0;

        } catch (Exception e) {
            log.error("Error sending FCM notification to user {}: {}", userId, e.getMessage());
            return false;
        }
    }

    /**
     * Envía una notificación a un token de dispositivo específico.
     * <p>
     * Si el envío falla debido a un token inválido o no registrado (UNREGISTERED),
     * el token se elimina automáticamente de la base de datos.
     * </p>
     *
     * @param token El token FCM del dispositivo de destino.
     * @param title El título de la notificación.
     * @param message El cuerpo del mensaje.
     * @param type El tipo de notificación.
     * @param referenceId ID de referencia (opcional).
     * @param referenceType Tipo de referencia (opcional).
     * @return {@code true} si el mensaje se envió correctamente, {@code false} si hubo un fallo.
     */
    public boolean sendToToken(String token, String title, String message,
                               String type, Long referenceId, String referenceType) {
        try {
            
            Map<String, String> data = new HashMap<>();
            data.put("type", type);
            if (referenceId != null) {
                data.put("referenceId", referenceId.toString());
            }
            if (referenceType != null) {
                data.put("referenceType", referenceType);
            }

            
            Notification notification = Notification.builder()
                    .setTitle(title)
                    .setBody(message)
                    .build();

            
            Message fcmMessage = Message.builder()
                    .setToken(token)
                    .setNotification(notification)
                    .putAllData(data)
                    .setAndroidConfig(AndroidConfig.builder()
                            .setPriority(AndroidConfig.Priority.HIGH)
                            .setNotification(AndroidNotification.builder()
                                    .setSound("default")
                                    .setColor("#1E88E5")
                                    .build())
                            .build())
                    .setApnsConfig(ApnsConfig.builder()
                            .setAps(Aps.builder()
                                    .setSound("default")
                                    .build())
                            .build())
                    .build();

            
            String response = FirebaseMessaging.getInstance().send(fcmMessage);
            log.info("Successfully sent message: {}", response);
            return true;

        } catch (FirebaseMessagingException e) {
            log.error("Error sending FCM message to token: {}", e.getMessage());

            
            if (e.getMessagingErrorCode() == MessagingErrorCode.UNREGISTERED ||
                e.getMessagingErrorCode() == MessagingErrorCode.INVALID_ARGUMENT) {
                log.info("Removing invalid FCM token: {}", token);
                
                fcmTokenRepository.deleteByToken(token);
            }

            return false;
        } catch (Exception e) {
            log.error("Unexpected error sending FCM message: {}", e.getMessage());
            return false;
        }
    }

    /**
     * Envía una notificación a múltiples tokens simultáneamente utilizando la función Multicast de Firebase.
     * <p>
     * Esta función es más eficiente para enviar el mismo mensaje a un gran número de tokens.
     * También procesa la respuesta por lotes para eliminar los tokens inválidos.
     * </p>
     *
     * @param tokens Lista de tokens FCM de los dispositivos de destino.
     * @param title El título de la notificación.
     * @param message El cuerpo del mensaje.
     * @param type El tipo de notificación.
     * @param referenceId ID de referencia (opcional).
     * @param referenceType Tipo de referencia (opcional).
     */
    public void sendMulticast(List<String> tokens, String title, String message,
                              String type, Long referenceId, String referenceType) {
        if (tokens.isEmpty()) {
            log.warn("No tokens provided for multicast message");
            return;
        }

        try {
            
            Map<String, String> data = new HashMap<>();
            data.put("type", type);
            if (referenceId != null) {
                data.put("referenceId", referenceId.toString());
            }
            if (referenceType != null) {
                data.put("referenceType", referenceType);
            }

            
            Notification notification = Notification.builder()
                    .setTitle(title)
                    .setBody(message)
                    .build();

            
            MulticastMessage message_multicast = MulticastMessage.builder()
                    .addAllTokens(tokens)
                    .setNotification(notification)
                    .putAllData(data)
                    .setAndroidConfig(AndroidConfig.builder()
                            .setPriority(AndroidConfig.Priority.HIGH)
                            .build())
                    .build();

            
            BatchResponse response = FirebaseMessaging.getInstance().sendEachForMulticast(message_multicast);

            log.info("Multicast message sent: {} success, {} failures",
                        response.getSuccessCount(), response.getFailureCount());

            
            if (response.getFailureCount() > 0) {
                List<SendResponse> responses = response.getResponses();
                for (int i = 0; i < responses.size(); i++) {
                    if (!responses.get(i).isSuccessful()) {
                        FirebaseMessagingException exception = responses.get(i).getException();
                        if (exception != null &&
                            (exception.getMessagingErrorCode() == MessagingErrorCode.UNREGISTERED ||
                             exception.getMessagingErrorCode() == MessagingErrorCode.INVALID_ARGUMENT)) {
                            String invalidToken = tokens.get(i);
                            log.info("Removing invalid token from multicast: {}", invalidToken);
                            
                            fcmTokenRepository.deleteByToken(invalidToken);
                        }
                    }
                }
            }

        } catch (Exception e) {
            log.error("Error sending multicast message: {}", e.getMessage());
        }
    }

    /**
     * Envía una notificación a todos los dispositivos suscritos a un tema específico (Topic).
     * <p>
     * Este es el método más escalable para enviar el mismo mensaje a una audiencia amplia.
     * </p>
     *
     * @param topic El nombre del tema (String) al que se suscribe el dispositivo.
     * @param title El título de la notificación.
     * @param message El cuerpo del mensaje.
     * @param type El tipo de notificación.
     * @param referenceId ID de referencia (opcional).
     * @param referenceType Tipo de referencia (opcional).
     * @return {@code true} si el mensaje fue enviado correctamente, {@code false} si hubo un fallo.
     */
    public boolean sendToTopic(String topic, String title, String message,
                               String type, Long referenceId, String referenceType) {
        try {
            
            Map<String, String> data = new HashMap<>();
            data.put("type", type);
            if (referenceId != null) {
                data.put("referenceId", referenceId.toString());
            }
            if (referenceType != null) {
                data.put("referenceType", referenceType);
            }

            
            Notification notification = Notification.builder()
                    .setTitle(title)
                    .setBody(message)
                    .build();

            
            Message fcmMessage = Message.builder()
                    .setTopic(topic)
                    .setNotification(notification)
                    .putAllData(data)
                    .build();

            
            String response = FirebaseMessaging.getInstance().send(fcmMessage);
            log.info("Successfully sent message to topic {}: {}", topic, response);
            return true;

        } catch (Exception e) {
            log.error("Error sending FCM message to topic {}: {}", topic, e.getMessage());
            return false;
        }
    }
}