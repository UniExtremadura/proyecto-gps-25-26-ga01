package io.audira.catalog.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * DTO de entrada para actualizar el porcentaje de regalías (Revenue Share) de una colaboración.
 * <p>
 * Implementa el requisito <b>GA01-155: Definir porcentaje de ganancias</b>.
 * Se utiliza para especificar qué fracción de los ingresos generados por una obra
 * le corresponde a un colaborador específico.
 * </p>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateRevenueRequest {

    /**
     * El nuevo porcentaje a asignar.
     * <p>
     * <b>Reglas de Validación:</b>
     * <ul>
     * <li>No puede ser nulo.</li>
     * <li>Mínimo: <b>0.00%</b> (Colaboración sin fines de lucro o solo créditos).</li>
     * <li>Máximo: <b>100.00%</b> (Totalidad de las ganancias).</li>
     * </ul>
     * Se utiliza {@link BigDecimal} para garantizar la precisión financiera y evitar errores de redondeo.
     * </p>
     */
    @NotNull(message = "Revenue percentage is required")
    @DecimalMin(value = "0.00", message = "Revenue percentage must be at least 0")
    @DecimalMax(value = "100.00", message = "Revenue percentage cannot exceed 100")
    private BigDecimal revenuePercentage;
}
