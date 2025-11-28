package io.audira.community.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Data Transfer Object (DTO) que representa la respuesta estandarizada de autenticación exitosa (login o registro).
 * <p>
 * Este objeto contiene el token de seguridad necesario para que el cliente realice
 * peticiones autenticadas y la información básica del usuario.
 * </p>
 *
 * @author Grupo GA01
 * @see UserDTO
 * 
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AuthResponse {

    /**
     * El token JWT (JSON Web Token) emitido, el cual debe ser incluido en los encabezados
     * de futuras peticiones para la autenticación.
     */
    private String token;

    /**
     * El tipo de token emitido (generalmente "Bearer").
     */
    private String type;

    /**
     * Objeto {@link UserDTO} que contiene la información básica del perfil del usuario autenticado.
     */
    private UserDTO user;
}