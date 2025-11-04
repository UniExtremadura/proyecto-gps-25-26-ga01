package io.audira.community.controller;

import io.audira.community.dto.UserDTO;
import io.audira.community.security.UserPrincipal;
import io.audira.community.service.FileStorageService;
import io.audira.community.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/files")
@RequiredArgsConstructor
public class FileUploadController {

    private final FileStorageService fileStorageService;
    private final UserService userService;

    @Value("${file.base-url:http://158.49.191.109:9001}")
    private String baseUrl;

    @PostMapping("/upload/profile-image")
    public ResponseEntity<?> uploadProfileImage(
            @RequestParam("file") MultipartFile file,
            @RequestParam("userId") Long userId) {

        try {
            // Log para debugging
            System.out.println("Recibido archivo: " + file.getOriginalFilename());
            System.out.println("Content-Type: " + file.getContentType());
            System.out.println("Tamaño: " + file.getSize() + " bytes");

            // Validar que sea una imagen
            if (!fileStorageService.isValidImageFile(file)) {
                return ResponseEntity.badRequest().body(
                    createErrorResponse("El archivo debe ser una imagen (JPEG, PNG, GIF, WEBP)")
                );
            }

            // Validar tamaño (máximo 5MB)
            if (file.getSize() > 5 * 1024 * 1024) {
                return ResponseEntity.badRequest().body(
                    createErrorResponse("El archivo no debe superar los 5MB")
                );
            }

            // Guardar el archivo
            String filePath = fileStorageService.storeFile(file, "profile-images");
            String fileUrl = baseUrl + "/api/files/" + filePath;

            // Actualizar el usuario con la nueva URL
            Map<String, Object> updates = new HashMap<>();
            updates.put("profileImageUrl", fileUrl);
            UserDTO updatedUser = userService.updateProfile(userId, updates);

            Map<String, Object> response = new HashMap<>();
            response.put("message", "Imagen de perfil actualizada exitosamente");
            response.put("fileUrl", fileUrl);
            response.put("user", updatedUser);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(
                createErrorResponse("Error al subir la imagen: " + e.getMessage())
            );
        }
    }

    @PostMapping("/upload/banner-image")
    public ResponseEntity<?> uploadBannerImage(
            @RequestParam("file") MultipartFile file,
            @RequestParam("userId") Long userId) {

        try {
            // Validar que sea una imagen
            if (!fileStorageService.isValidImageFile(file)) {
                return ResponseEntity.badRequest().body(
                    createErrorResponse("El archivo debe ser una imagen (JPEG, PNG, GIF, WEBP)")
                );
            }

            // Validar tamaño (máximo 10MB para banners)
            if (file.getSize() > 10 * 1024 * 1024) {
                return ResponseEntity.badRequest().body(
                    createErrorResponse("El archivo no debe superar los 10MB")
                );
            }

            // Guardar el archivo
            String filePath = fileStorageService.storeFile(file, "banner-images");
            String fileUrl = baseUrl + "/api/files/" + filePath;

            // Actualizar el usuario con la nueva URL
            Map<String, Object> updates = new HashMap<>();
            updates.put("bannerImageUrl", fileUrl);
            UserDTO updatedUser = userService.updateProfile(userId, updates);

            Map<String, Object> response = new HashMap<>();
            response.put("message", "Imagen de banner actualizada exitosamente");
            response.put("fileUrl", fileUrl);
            response.put("user", updatedUser);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(
                createErrorResponse("Error al subir la imagen: " + e.getMessage())
            );
        }
    }

    private Map<String, String> createErrorResponse(String message) {
        Map<String, String> error = new HashMap<>();
        error.put("error", message);
        return error;
    }
}
