package io.audira.community.dto;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Data Transfer Object (DTO) que representa la solicitud para cambiar el estado de actividad (activo/inactivo) de una cuenta de usuario.
 * <p>
 * Este DTO es utilizado por los administradores (ej. en {@code AdminController}) para suspender o reactivar cuentas.
 * </p>
 * Requisito asociado: GA01-165 (Suspender/reactivar cuentas).
 *
 * @author Grupo GA01
 * 
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ChangeStatusRequest {

    /**
     * El nuevo estado de actividad deseado para la cuenta.
     * <p>
     * {@code true}: Activar/Reactivar la cuenta.
     * {@code false}: Suspender/Desactivar la cuenta.
     * </p>
     * <p>
     * Restricción: No puede ser nulo ({@code @NotNull}).
     * </p>
     */
    @NotNull(message = "Active status is required")
    private Boolean isActive;
}