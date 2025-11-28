package io.audira.catalog.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * DTO detallado que representa la evolución temporal de las métricas de un artista.
 * <p>
 * Diseñado para cumplir con el requisito <b>GA01-109: Vista detallada</b>.
 * Contiene tanto los totales para un rango de fechas específico como una lista
 * de puntos de datos diarios ({@link DailyMetric}) optimizada para renderizar
 * gráficos de líneas o barras en el frontend.
 * </p>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ArtistMetricsDetailed {

    // --- Contexto del Reporte ---
    /** ID del artista consultado. */
    private Long artistId;

    /** Nombre del artista. */
    private String artistName;

    /** Fecha de inicio del rango del reporte (inclusive). */
    private LocalDate startDate;

    /** Fecha de fin del rango del reporte (inclusive). */
    private LocalDate endDate;

    // --- Datos para Gráficos ---

    /**
     * Lista cronológica de métricas diarias.
     * <p>
     * Cada elemento representa un punto en el eje X (Fecha) con sus valores Y (Plays, Ventas, etc.).
     * Ideal para librerías de gráficos como Chart.js o Recharts.
     * </p>
     */
    private List<DailyMetric> dailyMetrics;

    // --- Resumen del Periodo Seleccionado ---
    /** Suma total de reproducciones dentro del rango [startDate, endDate]. */
    private Long totalPlays;

    /** Suma total de ventas dentro del rango. */
    private Long totalSales;

    /** Ingresos totales generados dentro del rango. */
    private BigDecimal totalRevenue;

    /** Total de comentarios recibidos dentro del rango. */
    private Long totalComments;

    /** Promedio de valoración ponderado durante este periodo. */
    private Double averageRating;

    /**
     * Clase interna estática que representa un punto de datos diario.
     * <p>
     * Se utiliza para granularidad diaria en gráficos de evolución.
     * </p>
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DailyMetric {
        /**
         * Fecha del dato (Eje X).
         */
        private LocalDate date;

        /** Cantidad de reproducciones en este día específico. */
        private Long plays;

        /** Cantidad de ventas realizadas en este día. */
        private Long sales;

        /** Ingresos generados en este día. */
        private BigDecimal revenue;

        /** Nuevos comentarios recibidos en este día. */
        private Long comments;

        /**
         * Promedio de valoración calculado solo con los votos de este día.
         * <p>Si no hubo votos, puede ser null o 0.0 dependiendo de la implementación.</p>
         */
        private Double averageRating;
    }
}
