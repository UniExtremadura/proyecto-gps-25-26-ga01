package io.audira.catalog.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO de entrada (Request Payload) para ejecutar acciones de moderación.
 * <p>
 * Se utiliza en los endpoints de aprobación y rechazo (GA01-162).
 * Encapsula la decisión tomada por el administrador sobre una obra pendiente.
 * </p>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ModerationRequest {
    /**
     * Identificador del usuario administrador que está realizando la revisión.
     * <p>Este ID quedará registrado en el historial de auditoría.</p>
     */
    private Long adminId;

    /**
     * Motivo por el cual se rechaza el contenido.
     * <p>
     * <b>Validación:</b> Este campo es <u>obligatorio</u> si la acción es RECHAZAR.
     * Este texto será enviado al artista por correo o notificación push para que realice correcciones.
     * </p>
     */
    private String rejectionReason;

    /**
     * Notas o comentarios adicionales internos.
     * <p>
     * Opcional. Útil para dejar constancia de detalles específicos observados durante la revisión
     * (ej: "Audio con baja calidad en el segundo 30" o "Revisado bajo criterios de Copyright").
     * </p>
     */
    private String notes;
}
