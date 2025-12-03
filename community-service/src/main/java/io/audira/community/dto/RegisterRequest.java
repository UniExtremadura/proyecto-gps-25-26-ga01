package io.audira.community.dto;

import io.audira.community.model.UserRole;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * Data Transfer Object (DTO) que representa la solicitud de un cliente para registrar un nuevo usuario.
 * <p>
 * Este objeto contiene las credenciales básicas (email, nombre de usuario, contraseña) y los datos
 * de perfil requeridos para la creación de una cuenta. Utiliza la validación de Jakarta para
 * asegurar la integridad de los datos de entrada.
 * </p>
 *
 * @author Grupo GA01
 * @see UserRole
 * 
 */
@Data
public class RegisterRequest {

    /**
     * Dirección de correo electrónico del nuevo usuario.
     * <p>
     * Restricciones: No puede estar vacía ({@code @NotBlank}) y debe ser una dirección de correo electrónico válida ({@code @Email}).
     * </p>
     */
    @NotBlank(message = "Email is required")
    @Email(message = "Email must be valid")
    private String email;

    /**
     * Nombre de usuario o alias.
     * <p>
     * Restricciones: No puede estar vacío ({@code @NotBlank}) y debe tener entre 3 y 50 caracteres ({@code @Size}).
     * </p>
     */
    @NotBlank(message = "Username is required")
    @Size(min = 3, max = 50, message = "Username must be between 3 and 50 characters")
    private String username;

    /**
     * Contraseña del usuario.
     * <p>
     * Restricciones: No puede estar vacía ({@code @NotBlank}) y debe tener un mínimo de 6 caracteres ({@code @Size}).
     * </p>
     */
    @NotBlank(message = "Password is required")
    @Size(min = 6, max = 100, message = "Password must be at least 6 characters")
    private String password;

    /**
     * Nombre de pila o primer nombre del usuario.
     * <p>
     * Restricción: No puede estar vacío ({@code @NotBlank}).
     * </p>
     */
    @NotBlank(message = "First name is required")
    private String firstName;

    /**
     * Apellido del usuario.
     * <p>
     * Restricción: No puede estar vacío ({@code @NotBlank}).
     * </p>
     */
    @NotBlank(message = "Last name is required")
    private String lastName;

    /**
     * Rol de seguridad asignado al usuario durante el registro.
     * <p>
     * Valor por defecto: {@link UserRole#USER}. El registro por defecto no permite asignar roles administrativos.
     * </p>
     */
    private UserRole role = UserRole.USER;
}