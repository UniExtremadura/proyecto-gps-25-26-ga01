package io.audira.commerce.controller;

import io.audira.commerce.model.FcmToken;
import io.audira.commerce.model.Platform;
import io.audira.commerce.service.FcmTokenService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/notifications/fcm")
@RequiredArgsConstructor
@Slf4j
public class FcmTokenController {

    private final FcmTokenService fcmTokenService;

    /**
     * Register a new FCM token for a user
     */
    @PostMapping("/register")
    public ResponseEntity<?> registerToken(@RequestBody Map<String, Object> request) {
        try {
            Long userId = Long.valueOf(request.get("userId").toString());
            String token = request.get("token").toString();
            String platformStr = request.get("platform").toString();

            Platform platform;
            try {
                platform = Platform.valueOf(platformStr.toUpperCase());
            } catch (IllegalArgumentException e) {
                platform = Platform.ANDROID; // Default to Android
            }

            FcmToken fcmToken = fcmTokenService.registerToken(userId, token, platform);

            return ResponseEntity.ok(Map.of(
                "success", true,
                "message", "FCM token registered successfully",
                "tokenId", fcmToken.getId()
            ));

        } catch (Exception e) {
            log.error("Error registering FCM token: {}", e.getMessage());
            return ResponseEntity.badRequest().body(Map.of(
                "success", false,
                "error", e.getMessage()
            ));
        }
    }

    /**
     * Unregister an FCM token
     */
    @DeleteMapping("/unregister")
    public ResponseEntity<?> unregisterToken(@RequestBody Map<String, Object> request) {
        try {
            Long userId = Long.valueOf(request.get("userId").toString());
            String token = request.get("token").toString();

            fcmTokenService.deleteToken(userId, token);

            return ResponseEntity.ok(Map.of(
                "success", true,
                "message", "FCM token unregistered successfully"
            ));

        } catch (Exception e) {
            log.error("Error unregistering FCM token: {}", e.getMessage());
            return ResponseEntity.badRequest().body(Map.of(
                "success", false,
                "error", e.getMessage()
            ));
        }
    }

    /**
     * Get all tokens for a user
     */
    @GetMapping("/user/{userId}")
    public ResponseEntity<?> getUserTokens(@PathVariable Long userId) {
        try {
            var tokens = fcmTokenService.getUserTokens(userId);

            return ResponseEntity.ok(Map.of(
                "success", true,
                "tokens", tokens
            ));

        } catch (Exception e) {
            log.error("Error fetching user tokens: {}", e.getMessage());
            return ResponseEntity.badRequest().body(Map.of(
                "success", false,
                "error", e.getMessage()
            ));
        }
    }
}
