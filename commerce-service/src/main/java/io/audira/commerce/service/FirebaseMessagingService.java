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

@Service
@RequiredArgsConstructor
@Slf4j
public class FirebaseMessagingService {

    private final FcmTokenRepository fcmTokenRepository;

    @Value("${firebase.credentials-file:classpath:firebase-service-account.json}")
    private Resource firebaseCredentials;

    @PostConstruct
    public void initialize() {
        try {
            // Check if already initialized
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
     * Send notification to a specific user
     * Sends to all registered devices for that user
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
     * Send notification to a specific token
     */
    public boolean sendToToken(String token, String title, String message,
                              String type, Long referenceId, String referenceType) {
        try {
            // Build data payload
            Map<String, String> data = new HashMap<>();
            data.put("type", type);
            if (referenceId != null) {
                data.put("referenceId", referenceId.toString());
            }
            if (referenceType != null) {
                data.put("referenceType", referenceType);
            }

            // Build notification
            Notification notification = Notification.builder()
                    .setTitle(title)
                    .setBody(message)
                    .build();

            // Build message
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

            // Send message
            String response = FirebaseMessaging.getInstance().send(fcmMessage);
            log.info("Successfully sent message: {}", response);
            return true;

        } catch (FirebaseMessagingException e) {
            log.error("Error sending FCM message to token: {}", e.getMessage());

            // If token is invalid, remove it from database
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
     * Send notification to multiple tokens
     */
    public void sendMulticast(List<String> tokens, String title, String message,
                             String type, Long referenceId, String referenceType) {
        if (tokens.isEmpty()) {
            log.warn("No tokens provided for multicast message");
            return;
        }

        try {
            // Build data payload
            Map<String, String> data = new HashMap<>();
            data.put("type", type);
            if (referenceId != null) {
                data.put("referenceId", referenceId.toString());
            }
            if (referenceType != null) {
                data.put("referenceType", referenceType);
            }

            // Build notification
            Notification notification = Notification.builder()
                    .setTitle(title)
                    .setBody(message)
                    .build();

            // Build multicast message
            MulticastMessage message_multicast = MulticastMessage.builder()
                    .addAllTokens(tokens)
                    .setNotification(notification)
                    .putAllData(data)
                    .setAndroidConfig(AndroidConfig.builder()
                            .setPriority(AndroidConfig.Priority.HIGH)
                            .build())
                    .build();

            // Send multicast
            BatchResponse response = FirebaseMessaging.getInstance().sendEachForMulticast(message_multicast);

            log.info("Multicast message sent: {} success, {} failures",
                    response.getSuccessCount(), response.getFailureCount());

            // Clean up invalid tokens
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
     * Send notification to a topic
     */
    public boolean sendToTopic(String topic, String title, String message,
                              String type, Long referenceId, String referenceType) {
        try {
            // Build data payload
            Map<String, String> data = new HashMap<>();
            data.put("type", type);
            if (referenceId != null) {
                data.put("referenceId", referenceId.toString());
            }
            if (referenceType != null) {
                data.put("referenceType", referenceType);
            }

            // Build notification
            Notification notification = Notification.builder()
                    .setTitle(title)
                    .setBody(message)
                    .build();

            // Build message
            Message fcmMessage = Message.builder()
                    .setTopic(topic)
                    .setNotification(notification)
                    .putAllData(data)
                    .build();

            // Send message
            String response = FirebaseMessaging.getInstance().send(fcmMessage);
            log.info("Successfully sent message to topic {}: {}", topic, response);
            return true;

        } catch (Exception e) {
            log.error("Error sending FCM message to topic {}: {}", topic, e.getMessage());
            return false;
        }
    }
}
