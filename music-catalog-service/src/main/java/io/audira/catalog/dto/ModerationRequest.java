package io.audira.catalog.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * GA01-162: DTO para solicitudes de moderación (aprobar/rechazar)
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ModerationRequest {
    private Long adminId; // ID del administrador que modera
    private String rejectionReason; // Motivo de rechazo (requerido si se rechaza)
    private String notes; // Notas adicionales opcionales
}
