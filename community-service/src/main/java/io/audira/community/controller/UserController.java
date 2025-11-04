package io.audira.community.controller;

import io.audira.community.dto.ChangePasswordRequest;
import io.audira.community.dto.UpdateProfileRequest;
import io.audira.community.dto.UserDTO;
import io.audira.community.security.UserPrincipal;
import io.audira.community.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    // Endpoint: PUT /api/users/profile (probado en el script)
    @PutMapping("/profile")
    public ResponseEntity<UserDTO> updateCurrentUserProfile(
            @AuthenticationPrincipal UserPrincipal currentUser,
            @Valid @RequestBody UpdateProfileRequest updateRequest
    ) {
        UserDTO updatedProfile = userService.updateProfile(currentUser.getId(), updateRequest);
        return ResponseEntity.ok(updatedProfile);
    }

    // Endpoint: POST /api/users/change-password
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
}