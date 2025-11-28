package io.audira.community.dto;

import io.audira.community.model.UserRole;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Data Transfer Object (DTO) que representa la solicitud para cambiar el rol de un usuario existente.
 * <p>
 * Este DTO es utilizado por los administradores (ej. en {@code AdminController}) para asignar
 * nuevos roles de seguridad (como {@link UserRole#ADMIN} o {@link UserRole#ARTIST}) a un usuario.
 * </p>
 * Requisito asociado: GA01-164 (Buscar/editar usuario [roles, estado]).
 *
 * @author Grupo GA01
 * @see UserRole
 * 
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ChangeRoleRequest {

    /**
     * El nuevo rol de seguridad que se desea asignar al usuario.
     * <p>
     * Restricción: No puede ser nulo ({@code @NotNull}).
     * </p>
     */
    @NotNull(message = "Role is required")
    private UserRole role;
}