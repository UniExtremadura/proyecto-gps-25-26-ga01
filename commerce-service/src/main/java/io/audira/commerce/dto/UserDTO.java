package io.audira.commerce.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Data Transfer Object (DTO) que representa la información esencial de un usuario.
 * <p>
 * Este objeto se utiliza para transferir datos de perfil de usuario entre servicios
 * (ej. desde el Servicio de Usuarios hacia el Servicio de Comercio) o para exponer
 * información básica de usuario a través de la API sin incluir detalles sensibles
 * como contraseñas o tokens.
 * </p>
 *
 * @author Grupo GA01
 * 
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserDTO {

    /**
     * ID único del usuario en el sistema.
     */
    private Long id;

    /**
     * Dirección de correo electrónico del usuario.
     */
    private String email;

    /**
     * Nombre de usuario o alias.
     */
    private String username;

    /**
     * Nombre de pila o primer nombre del usuario.
     */
    private String firstName;

    /**
     * Apellido del usuario.
     */
    private String lastName;
}