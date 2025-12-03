package io.audira.community.controller;

import io.audira.community.dto.ChangePasswordRequest;
import io.audira.community.dto.UpdateProfileRequest;
import io.audira.community.dto.UserDTO;
import io.audira.community.security.UserPrincipal;
import io.audira.community.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

/**
 * Controlador REST que gestiona las operaciones relacionadas con el perfil, la consulta pública y las interacciones sociales (follow/unfollow) de los usuarios.
 * <p>
 * Los endpoints base se mapean a {@code /api/users}. Utiliza el principio de usuario autenticado
 * ({@link UserPrincipal}) para proteger las operaciones sensibles.
 * </p>
 *
 * @author Grupo GA01
 * @see UserService
 * 
 */
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    // --- Métodos de Perfil y Actualización ---

    /**
     * Obtiene el perfil del usuario actualmente autenticado.
     * <p>
     * Mapeo: {@code GET /api/users/profile}
     * </p>
     *
     * @param currentUser El principio de usuario autenticado.
     * @return {@link ResponseEntity} que contiene el {@link UserDTO} del perfil.
     */
    @GetMapping("/profile")
    public ResponseEntity<UserDTO> getCurrentUserProfile(@AuthenticationPrincipal UserPrincipal currentUser) {
        UserDTO userProfile = userService.getUserById(currentUser.getId());
        return ResponseEntity.ok(userProfile);
    }

    /**
     * Actualiza el perfil del usuario actualmente autenticado.
     * <p>
     * Mapeo: {@code PUT /api/users/profile}
     * Requiere el cuerpo de la solicitud {@link UpdateProfileRequest} validado.
     * </p>
     *
     * @param currentUser El principio de usuario autenticado.
     * @param updateRequest La solicitud {@link UpdateProfileRequest} con los datos a modificar.
     * @return {@link ResponseEntity} con el {@link UserDTO} actualizado.
     */
    @PutMapping("/profile")
    public ResponseEntity<UserDTO> updateCurrentUserProfile(
            @AuthenticationPrincipal UserPrincipal currentUser,
            @Valid @RequestBody UpdateProfileRequest updateRequest
    ) {
        UserDTO updatedProfile = userService.updateProfile(currentUser.getId(), updateRequest);
        return ResponseEntity.ok(updatedProfile);
    }

    /**
     * Permite al usuario autenticado cambiar su contraseña.
     * <p>
     * Mapeo: {@code POST /api/users/change-password}
     * </p>
     *
     * @param userId ID del usuario (tipo {@link Long}).
     * @param request Solicitud {@link ChangePasswordRequest} validada con la contraseña actual y la nueva.
     * @return {@link ResponseEntity} con un mensaje de éxito o un error 400 BAD REQUEST si la contraseña actual es incorrecta.
     */
    @PostMapping("/change-password")
    public ResponseEntity<?> changePassword(
            @RequestParam("userId") Long userId,
            @Valid @RequestBody ChangePasswordRequest request) {
        try {
            userService.changePassword(userId, request);
            return ResponseEntity.ok().body(
                java.util.Map.of("message", "Contraseña actualizada exitosamente")
            );
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(
                java.util.Map.of("error", e.getMessage())
            );
        }
    }

    // --- Subida de Imágenes ---

    /**
     * Sube una nueva imagen de perfil para el usuario autenticado (o un usuario especificado por Admin).
     * <p>
     * Mapeo: {@code POST /api/users/profile/image}
     * Incluye validación de tamaño (máx 5MB) y tipo de archivo (solo imágenes).
     * </p>
     *
     * @param currentUser El principio de usuario autenticado.
     * @param file El archivo de imagen {@link MultipartFile}.
     * @param userId ID opcional del usuario a modificar (solo si el usuario actual es ADMIN y lo especifica).
     * @return {@link ResponseEntity} con el {@link UserDTO} actualizado y un mensaje de éxito.
     */
    @PostMapping("/profile/image")
    public ResponseEntity<?> uploadProfileImage(
            @AuthenticationPrincipal UserPrincipal currentUser,
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "userId", required = false) Long userId) {
        try {
            Long targetUserId = (userId != null) ? userId : currentUser.getId();

            // Validaciones (tamaño y tipo)
            if (file.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of("error", "El archivo está vacío"));
            }
            if (file.getSize() > 5 * 1024 * 1024) {
                return ResponseEntity.badRequest().body(Map.of("error", "El archivo no debe superar los 5MB"));
            }
            if (!isValidImageFile(file)) {
                return ResponseEntity.badRequest().body(Map.of("error", "El archivo debe ser una imagen (JPEG, PNG, GIF, WEBP)"));
            }

            // Upload the profile image
            UserDTO updatedUser = userService.uploadProfileImage(targetUserId, file);

            // Return response in the format expected by the frontend
            Map<String, Object> response = new HashMap<>();
            response.put("message", "Foto de perfil actualizada exitosamente");
            response.put("user", updatedUser);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(
                Map.of("error", "Error al subir la imagen de perfil: " + e.getMessage())
            );
        }
    }

    /**
     * Sube una nueva imagen de banner para el usuario autenticado (o un usuario especificado por Admin).
     * <p>
     * Mapeo: {@code POST /api/users/profile/banner}
     * Incluye validación de tamaño (máx 10MB) y tipo de archivo (solo imágenes).
     * </p>
     *
     * @param currentUser El principio de usuario autenticado.
     * @param file El archivo de imagen {@link MultipartFile}.
     * @param userId ID opcional del usuario a modificar.
     * @return {@link ResponseEntity} con el {@link UserDTO} actualizado y un mensaje de éxito.
     */
    @PostMapping("/profile/banner")
    public ResponseEntity<?> uploadBannerImage(
            @AuthenticationPrincipal UserPrincipal currentUser,
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "userId", required = false) Long userId) {
        try {
            Long targetUserId = (userId != null) ? userId : currentUser.getId();

            // Validaciones (tamaño y tipo)
            if (file.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of("error", "El archivo está vacío"));
            }
            if (file.getSize() > 10 * 1024 * 1024) {
                return ResponseEntity.badRequest().body(Map.of("error", "El archivo no debe superar los 10MB"));
            }
            if (!isValidImageFile(file)) {
                return ResponseEntity.badRequest().body(Map.of("error", "El archivo debe ser una imagen (JPEG, PNG, GIF, WEBP)"));
            }

            // Upload the banner image
            UserDTO updatedUser = userService.uploadBannerImage(targetUserId, file);

            // Return response in the format expected by the frontend
            Map<String, Object> response = new HashMap<>();
            response.put("message", "Banner actualizado exitosamente");
            response.put("user", updatedUser);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(
                Map.of("error", "Error al subir el banner: " + e.getMessage())
            );
        }
    }
    
    /**
     * Método auxiliar para validar si un {@link MultipartFile} es una imagen aceptada.
     */
    private boolean isValidImageFile(MultipartFile file) {
        String contentType = file.getContentType();
        String fileName = file.getOriginalFilename();
        
        boolean validContentType = contentType != null && (
            contentType.equals("image/jpeg") ||
            contentType.equals("image/jpg") ||
            contentType.equals("image/png") ||
            contentType.equals("image/gif") ||
            contentType.equals("image/webp") ||
            contentType.equals("application/octet-stream")
        );
        
        boolean validExtension = false;
        if (fileName != null && fileName.contains(".")) {
            String extension = fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase();
            validExtension = extension.equals("jpg") ||
                             extension.equals("jpeg") ||
                             extension.equals("png") ||
                             extension.equals("gif") ||
                             extension.equals("webp");
        }
        
        return validContentType || validExtension;
    }


    // --- Métodos de Consulta Pública y Social ---

    /**
     * Obtiene el perfil de cualquier usuario por su ID (consulta pública).
     * <p>
     * Mapeo: {@code GET /api/users/{id}}
     * </p>
     *
     * @param userId ID del usuario (tipo {@link Long}) cuyo perfil se desea obtener.
     * @return {@link ResponseEntity} que contiene el {@link UserDTO}.
     */
    @GetMapping("/{id}")
    public ResponseEntity<UserDTO> getUserProfileById(@PathVariable("id") Long userId) {
        UserDTO userProfile = userService.getUserById(userId);
        return ResponseEntity.ok(userProfile);
    }

    /**
     * Obtiene una lista de todos los usuarios (consulta pública).
     * <p>
     * Mapeo: {@code GET /api/users}
     * </p>
     *
     * @return {@link ResponseEntity} que contiene una {@link List} de {@link UserDTO}.
     */
    @GetMapping
    public ResponseEntity<List<UserDTO>> getAllUsers() {
        List<UserDTO> users = userService.getAllUsers();
        return ResponseEntity.ok(users);
    }

    /**
     * Obtiene la lista de seguidores de un usuario específico.
     * <p>
     * Mapeo: {@code GET /api/users/{userId}/followers}
     * </p>
     *
     * @param userId ID del usuario (tipo {@link Long}) del que se quieren obtener los seguidores.
     * @return {@link ResponseEntity} con una {@link List} de {@link UserDTO} que son seguidores.
     */
    @GetMapping("/{userId}/followers")
    public ResponseEntity<List<UserDTO>> getUserFollowers(@PathVariable("userId") Long userId) {
        List<UserDTO> followers = userService.getFollowers(userId);
        return ResponseEntity.ok(followers);
    }

    /**
     * Obtiene la lista de usuarios que un usuario específico está siguiendo.
     * <p>
     * Mapeo: {@code GET /api/users/{userId}/following}
     * </p>
     *
     * @param userId ID del usuario (tipo {@link Long}) del que se quieren obtener los seguidos.
     * @return {@link ResponseEntity} con una {@link List} de {@link UserDTO} seguidos.
     */
    @GetMapping("/{userId}/following")
    public ResponseEntity<List<UserDTO>> getUserFollowing(@PathVariable("userId") Long userId) {
        List<UserDTO> following = userService.getFollowing(userId);
        return ResponseEntity.ok(following);
    }

    /**
     * Obtiene la lista de artistas que un usuario específico está siguiendo.
     * <p>
     * Mapeo: {@code GET /api/users/{userId}/following/artists}
     * </p>
     *
     * @param userId ID del usuario (tipo {@link Long}) del que se quieren obtener los artistas seguidos.
     * @return {@link ResponseEntity} con una {@link List} de {@link UserDTO} que son artistas seguidos.
     */
    @GetMapping("/{userId}/following/artists")
    public ResponseEntity<List<UserDTO>> getFollowedArtists(@PathVariable("userId") Long userId) {
        List<UserDTO> followedArtists = userService.getFollowedArtists(userId);
        return ResponseEntity.ok(followedArtists);
    }

    /**
     * Inicia la acción de seguir a otro usuario.
     * <p>
     * Mapeo: {@code POST /api/users/{userId}/follow/{targetUserId}}
     * </p>
     *
     * @param userId ID del usuario que inicia la acción (seguidor).
     * @param targetUserId ID del usuario objetivo (seguido).
     * @return {@link ResponseEntity} con el perfil del usuario que sigue actualizado.
     */
    @PostMapping("/{userId}/follow/{targetUserId}")
    public ResponseEntity<UserDTO> followUser(
            @PathVariable("userId") Long userId,
            @PathVariable("targetUserId") Long targetUserId) {
        UserDTO updatedUser = userService.followUser(userId, targetUserId);
        return ResponseEntity.ok(updatedUser);
    }

    /**
     * Inicia la acción de dejar de seguir a otro usuario.
     * <p>
     * Mapeo: {@code DELETE /api/users/{userId}/follow/{targetUserId}}
     * </p>
     *
     * @param userId ID del usuario que inicia la acción (seguidor).
     * @param targetUserId ID del usuario objetivo (seguido).
     * @return {@link ResponseEntity} con el perfil del usuario que deja de seguir actualizado.
     */
    @DeleteMapping("/{userId}/follow/{targetUserId}")
    public ResponseEntity<UserDTO> unfollowUser(
            @PathVariable("userId") Long userId,
            @PathVariable("targetUserId") Long targetUserId) {
        UserDTO updatedUser = userService.unfollowUser(userId, targetUserId);
        return ResponseEntity.ok(updatedUser);
    }

    /**
     * Busca artistas por una cadena de consulta (nombre, alias, etc.).
     * <p>
     * Mapeo: {@code GET /api/users/search/artists?query={consulta}}
     * </p>
     *
     * @param query La cadena de texto de búsqueda.
     * @return {@link ResponseEntity} con una {@link List} de {@link UserDTO} que coinciden y tienen rol ARTIST.
     */
    @GetMapping("/search/artists")
    public ResponseEntity<List<UserDTO>> searchArtists(@RequestParam("query") String query) {
        List<UserDTO> artists = userService.searchArtists(query);
        return ResponseEntity.ok(artists);
    }

    /**
     * Busca los IDs de artistas por una cadena de consulta.
     * <p>
     * Mapeo: {@code GET /api/users/search/artist-ids?query={consulta}}
     * Destinado a uso interno por otros microservicios (ej. {@code music-catalog-service}).
     * </p>
     *
     * @param query La cadena de texto de búsqueda.
     * @return {@link ResponseEntity} con una {@link List} de IDs (tipo {@link Long}) de los artistas que coinciden.
     */
    @GetMapping("/search/artist-ids")
    public ResponseEntity<List<Long>> searchArtistIds(@RequestParam("query") String query) {
        List<Long> artistIds = userService.searchArtistIds(query);
        return ResponseEntity.ok(artistIds);
    }
}