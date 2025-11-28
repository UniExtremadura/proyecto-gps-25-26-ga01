package io.audira.community.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * Data Transfer Object (DTO) que representa la solicitud de un usuario para iniciar sesión (login).
 * <p>
 * Este objeto contiene las credenciales necesarias (identificador y contraseña) para la autenticación
 * en el sistema.
 * </p>
 * <p>
 * Utiliza anotaciones de validación de Jakarta para asegurar que los campos no estén vacíos.
 * </p>
 *
 * @author Grupo GA01
 * 
 */
@Data
public class LoginRequest {

    /**
     * El identificador utilizado por el usuario para iniciar sesión. Puede ser la dirección de
     * correo electrónico o el nombre de usuario (alias).
     * <p>
     * Restricción: No puede estar vacía ({@code @NotBlank}).
     * </p>
     */
    @NotBlank(message = "Email or username is required")
    private String emailOrUsername;

    /**
     * La contraseña del usuario.
     * <p>
     * Restricción: No puede estar vacía ({@code @NotBlank}).
     * </p>
     */
    @NotBlank(message = "Password is required")
    private String password;
}