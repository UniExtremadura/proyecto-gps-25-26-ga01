package io.audira.commerce.controller;

import io.audira.commerce.model.FcmToken;
import io.audira.commerce.model.Platform;
import io.audira.commerce.service.FcmTokenService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Controlador REST para la gestión de tokens de Firebase Cloud Messaging (FCM).
 * <p>
 * Los endpoints base se mapean a {@code /api/notifications/fcm} y se utilizan
 * para registrar, anular el registro y consultar los tokens de dispositivos
 * asociados a un usuario para el envío de notificaciones push.
 * </p>
 *
 * @author Grupo GA01
 * @see FcmTokenService
 * @see FcmToken
 * 
 */
@RestController
@RequestMapping("/api/notifications/fcm")
@RequiredArgsConstructor
@Slf4j
public class FcmTokenController {

    /**
     * Servicio de lógica de negocio para la gestión de tokens FCM.
     */
    private final FcmTokenService fcmTokenService;

    /**
     * Registra un nuevo token FCM para un usuario.
     * <p>
     * Este endpoint se llama típicamente cuando la aplicación móvil o web obtiene un
     * token por primera vez o cuando el token es refrescado.
     * Mapeo: {@code POST /api/notifications/fcm/register}
     * </p>
     *
     * @param request Cuerpo de la solicitud {@link RequestBody} que debe contener:
     * <ul>
     * <li>{@code userId} (Long): ID del usuario.</li>
     * <li>{@code token} (String): El token FCM único del dispositivo.</li>
     * <li>{@code platform} (String): La plataforma del dispositivo (ej. "ANDROID", "IOS", "WEB"). Por defecto a ANDROID si es inválido.</li>
     * </ul>
     * @return {@link ResponseEntity} que contiene un mapa de éxito y el ID del token registrado, o un mapa de error si falla.
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
                "message", "FCM token registrado exitosamente",
                "tokenId", fcmToken.getId()
            ));

        } catch (Exception e) {
            log.error("Error registrando FCM token: {}", e.getMessage());
            return ResponseEntity.badRequest().body(Map.of(
                "success", false,
                "error", e.getMessage()
            ));
        }
    }

    /**
     * Anula el registro (elimina) un token FCM para un usuario.
     * <p>
     * Este endpoint se llama cuando un usuario cierra sesión o desinstala la aplicación,
     * para evitar enviar notificaciones a un token inactivo.
     * Mapeo: {@code DELETE /api/notifications/fcm/unregister}
     * </p>
     *
     * @param request Cuerpo de la solicitud {@link RequestBody} que debe contener:
     * <ul>
     * <li>{@code userId} (Long): ID del usuario.</li>
     * <li>{@code token} (String): El token FCM a eliminar.</li>
     * </ul>
     * @return {@link ResponseEntity} que contiene un mapa de éxito o un mapa de error si falla.
     */
    @DeleteMapping("/unregister")
    public ResponseEntity<?> unregisterToken(@RequestBody Map<String, Object> request) {
        try {
            Long userId = Long.valueOf(request.get("userId").toString());
            String token = request.get("token").toString();

            fcmTokenService.deleteToken(userId, token);

            return ResponseEntity.ok(Map.of(
                "success", true,
                "message", "FCM token anulado exitosamente"
            ));

        } catch (Exception e) {
            log.error("Error anulando FCM token: {}", e.getMessage());
            return ResponseEntity.badRequest().body(Map.of(
                "success", false,
                "error", e.getMessage()
            ));
        }
    }

    /**
     * Obtiene todos los tokens FCM activos asociados a un usuario.
     * <p>
     * Mapeo: {@code GET /api/notifications/fcm/user/{userId}}
     * </p>
     *
     * @param userId El ID del usuario (tipo {@link Long}) para el que se desean obtener los tokens.
     * @return {@link ResponseEntity} que contiene un mapa con la clave {@code tokens}
     * y una lista de los objetos {@link FcmToken} asociados, o un mapa de error si falla.
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
            log.error("Error obteniendo tokens de usuario: {}", e.getMessage());
            return ResponseEntity.badRequest().body(Map.of(
                "success", false,
                "error", e.getMessage()
            ));
        }
    }
}