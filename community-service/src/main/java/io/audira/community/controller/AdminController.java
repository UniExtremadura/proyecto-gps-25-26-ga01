package io.audira.community.controller;

import io.audira.community.dto.ChangeRoleRequest;
import io.audira.community.dto.ChangeStatusRequest;
import io.audira.community.dto.UserDTO;
import io.audira.community.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Controlador REST para las operaciones de administración y gestión de usuarios.
 * <p>
 * Todos los endpoints en esta clase requieren que el usuario autenticado posea el rol {@code ADMIN}
 * (controlado por {@code @PreAuthorize("hasRole('ADMIN')"})).
 * </p>
 * Requisitos asociados: GA01-164 (Buscar/editar usuario), GA01-165 (Suspender/reactivar cuentas).
 *
 * @author Grupo GA01
 * @see UserService
 * 
 */
@RestController
@RequestMapping("/api/admin/users")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")  // Todos los endpoints requieren el rol ADMIN
public class AdminController {

    private final UserService userService;

    // --- Métodos de Consulta y Búsqueda (GA01-164) ---

    /**
     * Obtiene una lista de todos los usuarios del sistema (vista administrativa).
     * <p>
     * Mapeo: {@code GET /api/admin/users}
     * </p>
     *
     * @return {@link ResponseEntity} que contiene una {@link List} de {@link UserDTO} con estado HTTP 200 (OK).
     */
    @GetMapping
    public ResponseEntity<List<UserDTO>> getAllUsersAdmin() {
        List<UserDTO> users = userService.getAllUsers();
        return ResponseEntity.ok(users);
    }

    /**
     * Obtiene los detalles de un usuario específico por su ID (vista administrativa).
     * <p>
     * Mapeo: {@code GET /api/admin/users/{userId}}
     * </p>
     *
     * @param userId ID del usuario (tipo {@link Long}).
     * @return {@link ResponseEntity} que contiene el {@link UserDTO} con estado HTTP 200 (OK).
     */
    @GetMapping("/{userId}")
    public ResponseEntity<UserDTO> getUserByIdAdmin(@PathVariable Long userId) {
        UserDTO user = userService.getUserById(userId);
        return ResponseEntity.ok(user);
    }

    /**
     * Obtiene métricas y estadísticas agregadas sobre los usuarios del sistema.
     * <p>
     * Mapeo: {@code GET /api/admin/users/stats}
     * </p>
     *
     * @return {@link ResponseEntity} que contiene un {@link Map} con las estadísticas, con estado HTTP 200 (OK).
     */
    @GetMapping("/stats")
    public ResponseEntity<Map<String, Object>> getUserStatistics() {
        Map<String, Object> stats = userService.getUserStatistics();
        return ResponseEntity.ok(stats);
    }

    /**
     * Busca usuarios por una cadena de consulta que puede coincidir con username, email o nombre.
     * <p>
     * Mapeo: {@code GET /api/admin/users/search?query={consulta}}
     * </p>
     *
     * @param query La cadena de texto a buscar.
     * @return {@link ResponseEntity} que contiene una {@link List} de {@link UserDTO} que coinciden.
     */
    @GetMapping("/search")
    public ResponseEntity<List<UserDTO>> searchUsers(@RequestParam String query) {
        List<UserDTO> users = userService.searchUsers(query);
        return ResponseEntity.ok(users);
    }

    /**
     * Obtiene una lista de usuarios filtrados por su rol (ej. "ARTIST", "USER").
     * <p>
     * Mapeo: {@code GET /api/admin/users/by-role/{role}}
     * </p>
     *
     * @param role El nombre del rol (String) por el cual filtrar.
     * @return {@link ResponseEntity} que contiene una {@link List} de {@link UserDTO} con el rol especificado.
     */
    @GetMapping("/by-role/{role}")
    public ResponseEntity<List<UserDTO>> getUsersByRole(@PathVariable String role) {
        List<UserDTO> users = userService.getUsersByRole(role);
        return ResponseEntity.ok(users);
    }

    // --- Métodos de Edición y Moderación (GA01-164, GA01-165) ---

    /**
     * Cambia el rol de un usuario.
     * <p>
     * Mapeo: {@code PUT /api/admin/users/{userId}/role}
     * </p>
     *
     * @param userId ID del usuario (tipo {@link Long}) cuyo rol se va a modificar.
     * @param request Objeto {@link ChangeRoleRequest} validado, conteniendo el nuevo nombre del rol.
     * @return El {@link UserDTO} actualizado.
     */
    @PutMapping("/{userId}/role")
    public ResponseEntity<UserDTO> changeUserRole(
            @PathVariable Long userId,
            @Valid @RequestBody ChangeRoleRequest request
    ) {
        UserDTO updatedUser = userService.changeUserRole(userId, request.getRole());
        return ResponseEntity.ok(updatedUser);
    }

    /**
     * Verifica manualmente el correo electrónico de un usuario (acción de administrador).
     * <p>
     * Mapeo: {@code PUT /api/admin/users/{userId}/verify}
     * </p>
     *
     * @param userId ID del usuario (tipo {@link Long}) a verificar.
     * @return El {@link UserDTO} actualizado con el estado de verificación cambiado.
     */
    @PutMapping("/{userId}/verify")
    public ResponseEntity<UserDTO> verifyUserEmail(@PathVariable Long userId) {
        UserDTO updatedUser = userService.adminVerifyUser(userId);
        return ResponseEntity.ok(updatedUser);
    }

    /**
     * Cambia el estado de actividad (activo/inactivo) de una cuenta de usuario.
     * <p>
     * Mapeo: {@code PUT /api/admin/users/{userId}/status}
     * </p>
     *
     * @param userId ID del usuario (tipo {@link Long}) cuyo estado se va a modificar.
     * @param request Objeto {@link ChangeStatusRequest} validado, conteniendo el nuevo estado booleano ({@code true} para activar, {@code false} para suspender).
     * @return El {@link UserDTO} actualizado.
     */
    @PutMapping("/{userId}/status")
    public ResponseEntity<UserDTO> changeUserStatus(
            @PathVariable Long userId,
            @Valid @RequestBody ChangeStatusRequest request
    ) {
        UserDTO updatedUser = userService.changeUserStatus(userId, request.getIsActive());
        return ResponseEntity.ok(updatedUser);
    }

    /**
     * Suspende la cuenta de un usuario (atajo para establecer {@code isActive = false}).
     * <p>
     * Mapeo: {@code PUT /api/admin/users/{userId}/suspend}
     * </p>
     *
     * @param userId ID del usuario (tipo {@link Long}) a suspender.
     * @return El {@link UserDTO} actualizado.
     */
    @PutMapping("/{userId}/suspend")
    public ResponseEntity<UserDTO> suspendUser(@PathVariable Long userId) {
        UserDTO updatedUser = userService.changeUserStatus(userId, false);
        return ResponseEntity.ok(updatedUser);
    }

    /**
     * Reactiva la cuenta de un usuario (atajo para establecer {@code isActive = true}).
     * <p>
     * Mapeo: {@code PUT /api/admin/users/{userId}/activate}
     * </p>
     *
     * @param userId ID del usuario (tipo {@link Long}) a reactivar.
     * @return El {@link UserDTO} actualizado.
     */
    @PutMapping("/{userId}/activate")
    public ResponseEntity<UserDTO> activateUser(@PathVariable Long userId) {
        UserDTO updatedUser = userService.changeUserStatus(userId, true);
        return ResponseEntity.ok(updatedUser);
    }
}