package io.audira.community.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * Data Transfer Object (DTO) que representa la solicitud de un usuario para cambiar su contraseña.
 * <p>
 * Este objeto encapsula las tres contraseñas necesarias (actual, nueva y confirmación)
 * para realizar la operación de forma segura.
 * </p>
 * <p>
 * Utiliza anotaciones de validación de Jakarta para asegurar que las contraseñas
 * no estén vacías y que la nueva cumpla con los requisitos mínimos de longitud.
 * </p>
 *
 * @author Grupo GA01
 * 
 */
@Data
public class ChangePasswordRequest {

    /**
     * Contraseña actual del usuario. Se utiliza para verificar la identidad del solicitante.
     * <p>
     * Restricción: No puede estar vacía ({@code @NotBlank}).
     * </p>
     */
    @NotBlank(message = "La contraseña actual es requerida")
    private String currentPassword;

    /**
     * La nueva contraseña que el usuario desea establecer.
     * <p>
     * Restricciones: No puede estar vacía ({@code @NotBlank}) y debe tener un mínimo de 8 caracteres ({@code @Size}).
     * </p>
     */
    @NotBlank(message = "La nueva contraseña es requerida")
    @Size(min = 8, message = "La nueva contraseña debe tener al menos 8 caracteres")
    private String newPassword;

    /**
     * Confirmación de la nueva contraseña. Se utiliza para verificar que el usuario no cometió errores tipográficos en {@code newPassword}.
     * <p>
     * Restricción: No puede estar vacía ({@code @NotBlank}).
     * </p>
     */
    @NotBlank(message = "La confirmación de contraseña es requerida")
    private String confirmPassword;
}