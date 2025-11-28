package io.audira.community.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;

/**
 * Entidad JPA que representa una **Pregunta Frecuente (FAQ)**.
 * <p>
 * Este objeto almacena tanto la pregunta como su respuesta asociada, junto con metadatos
 * como la categoría, el orden de visualización y métricas de utilidad para la gestión del contenido.
 * </p>
 *
 * @author Grupo GA01
 * 
 */
@Entity
@Table(name = "faqs")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FAQ {

    /**
     * Identificador único de la Pregunta Frecuente (FAQ).
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * El texto de la pregunta.
     * <p>
     * Campo requerido, con una longitud máxima de 500 caracteres.
     * </p>
     */
    @Column(nullable = false, length = 500)
    private String question;

    /**
     * El texto de la respuesta a la pregunta.
     * <p>
     * Campo requerido, se almacena como {@code TEXT} para respuestas detalladas.
     * </p>
     */
    @Column(nullable = false, columnDefinition = "TEXT")
    private String answer;

    /**
     * Categoría a la que pertenece esta FAQ (ej. "General", "Pagos", "Cuenta").
     * <p>
     * Campo requerido, con una longitud máxima de 100 caracteres.
     * </p>
     */
    @Column(nullable = false, length = 100)
    private String category;

    /**
     * Número que define el orden de visualización de la FAQ dentro de su categoría.
     * <p>
     * Valor por defecto es 0.
     * </p>
     */
    @Column(name = "display_order")
    @Builder.Default
    private Integer displayOrder = 0;

    /**
     * Indicador de si la FAQ está visible o activa para el público.
     * <p>
     * {@code true} si está activa, {@code false} en caso contrario. Valor por defecto es {@code true}.
     * </p>
     */
    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean isActive = true;

    /**
     * Contador de veces que se ha visto la FAQ.
     * <p>
     * Se utiliza para medir la popularidad del contenido. Valor por defecto es 0.
     * </p>
     */
    @Column(name = "view_count")
    @Builder.Default
    private Integer viewCount = 0;

    /**
     * Contador de votos de "útil" recibidos para esta respuesta.
     * <p>
     * Valor por defecto es 0.
     * </p>
     */
    @Column(name = "helpful_count")
    @Builder.Default
    private Integer helpfulCount = 0;

    /**
     * Contador de votos de "no útil" recibidos para esta respuesta.
     * <p>
     * Valor por defecto es 0.
     * </p>
     */
    @Column(name = "not_helpful_count")
    @Builder.Default
    private Integer notHelpfulCount = 0;

    /**
     * Marca de tiempo que indica la fecha y hora de creación de la FAQ.
     * <p>
     * Se establece automáticamente antes de la persistencia.
     * </p>
     */
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    /**
     * Marca de tiempo que indica la última fecha y hora de modificación de la FAQ.
     * <p>
     * Se actualiza automáticamente antes de cada operación de actualización.
     * </p>
     */
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    /**
     * Método invocado justo antes de que la entidad sea persistida (insertada) en la base de datos.
     * <p>
     * Establece {@code createdAt} y {@code updatedAt} a la hora actual, utilizando la zona horaria
     * "Europe/Madrid" y convirtiéndola a {@code LocalDateTime}.
     * </p>
     * @see PrePersist
     */
    @PrePersist
    protected void onCreate() {
        ZonedDateTime now = ZonedDateTime.now(ZoneId.of("Europe/Madrid"));
        this.createdAt = now.toLocalDateTime();
        this.updatedAt = now.toLocalDateTime();
    }

    /**
     * Método invocado justo antes de que la entidad sea actualizada en la base de datos.
     * <p>
     * Actualiza el campo {@code updatedAt} a la hora actual, utilizando la zona horaria
     * "Europe/Madrid" y convirtiéndola a {@code LocalDateTime}.
     * </p>
     * @see PreUpdate
     */
    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = ZonedDateTime.now(ZoneId.of("Europe/Madrid")).toLocalDateTime();
    }
}