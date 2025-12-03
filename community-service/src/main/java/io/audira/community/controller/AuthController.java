package io.audira.community.controller;

import io.audira.community.dto.AuthResponse;
import io.audira.community.dto.LoginRequest;
import io.audira.community.dto.RegisterRequest;
import io.audira.community.model.User;
import io.audira.community.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

import java.util.HashMap;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Controlador REST que maneja los flujos de autenticación y autorización del usuario.
 * <p>
 * Los endpoints se mapean a {@code /api/auth} y permiten el registro, la verificación
 * del correo electrónico y el inicio de sesión, devolviendo el JWT (JSON Web Token)
 * para futuras solicitudes autenticadas. Habilita CORS para todos los orígenes.
 * </p>
 *
 * @author Grupo GA01
 * @see UserService
 * 
 */
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
@CrossOrigin(origins = "*", maxAge = 3600)
public class AuthController {

    private static final Logger logger = LoggerFactory.getLogger(AuthController.class);
    private final UserService userService;

    /**
     * Registra un nuevo usuario en el sistema.
     * <p>
     * Mapeo: {@code POST /api/auth/register}
     * El cuerpo de la solicitud debe ser un objeto {@link RegisterRequest} válido.
     * </p>
     *
     * @param request La solicitud {@link RegisterRequest} validada que contiene los datos de registro.
     * @return {@link ResponseEntity} que contiene el objeto {@link AuthResponse} (incluyendo el JWT) con estado HTTP 200 (OK).
     * @throws Exception Si ocurre un error durante el proceso de registro (ej. usuario ya existente).
     */
    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        logger.info("Register request received for email: {}", request.getEmail());
        try {
            AuthResponse response = userService.registerUser(request);
            logger.info("User registered successfully: {}", request.getEmail());
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.error("Error during registration: {}", e.getMessage(), e);
            throw e;
        }
    }
    
    /**
     * Verifica la dirección de correo electrónico de un usuario utilizando el ID proporcionado en la ruta.
     * <p>
     * Mapeo: {@code POST /api/auth/verify-email/{userId}}
     * Este endpoint simula el proceso de verificación a través de un enlace enviado por email.
     * </p>
     *
     * @param userId El ID del usuario (tipo {@link Long}) cuya dirección de correo electrónico se va a verificar.
     * @return {@link ResponseEntity} que contiene un mapa con los datos del usuario verificado y un mensaje de éxito.
     * @throws RuntimeException si el usuario no existe o ya está verificado.
     */
    @PostMapping("/verify-email/{userId}")
    public ResponseEntity<Map<String, Object>> verifyEmail(@PathVariable Long userId) {
        logger.info("Email verification request received for userId: {}", userId);

        try {
            User user = userService.verifyEmail(userId);

            Map<String, Object> response = new HashMap<>();
            response.put("user", user);
            response.put("message", "Email verified successfully!");

            logger.info("Email verified successfully for userId: {}", userId);
            return ResponseEntity.ok(response);

        } catch (RuntimeException e) {
            logger.error("Error verifying email for userId {}: {}", userId, e.getMessage());
            throw e;
        }
    }

    /**
     * Inicia la sesión de un usuario y emite un JWT para futuras solicitudes.
     * <p>
     * Mapeo: {@code POST /api/auth/login}
     * El cuerpo de la solicitud debe ser un objeto {@link LoginRequest} válido.
     * </p>
     *
     * @param request La solicitud {@link LoginRequest} validada que contiene las credenciales.
     * @return {@link ResponseEntity} que contiene el objeto {@link AuthResponse} (incluyendo el JWT) con estado HTTP 200 (OK).
     * @throws Exception Si ocurre un error durante el proceso de inicio de sesión (ej. credenciales inválidas).
     */
    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        logger.info("Login request received for: {}", request.getEmailOrUsername());
        try {
            AuthResponse response = userService.loginUser(request);
            logger.info("User logged in successfully: {}", request.getEmailOrUsername());
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.error("Error during login: {}", e.getMessage(), e);
            throw e;
        }
    }
}