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
 * Entidad JPA que representa la respuesta de un administrador a un mensaje de contacto ({@code ContactMessage})
 * enviado por un usuario.
 * <p>
 * Este objeto almacena el contenido de la respuesta, quién la envió (administrador) y la vinculación
 * con el mensaje original.
 * </p>
 *
 * @author Grupo GA01
 * 
 */
@Entity
@Table(name = "contact_responses")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ContactResponse {

    /**
     * Identificador único de la respuesta.
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * ID del mensaje de contacto original al que se está respondiendo.
     * <p>
     * Campo requerido, esencial para vincular la respuesta al mensaje inicial.
     * </p>
     */
    @Column(name = "contact_message_id", nullable = false)
    private Long contactMessageId;

    /**
     * ID del usuario administrador que creó la respuesta.
     * <p>
     * Campo requerido.
     * </p>
     */
    @Column(name = "admin_id", nullable = false)
    private Long adminId;

    /**
     * Nombre del administrador que respondió (para referencia rápida, evita una consulta de unión).
     * <p>
     * Campo requerido con una longitud máxima de 255 caracteres.
     * </p>
     */
    @Column(name = "admin_name", nullable = false, length = 255)
    private String adminName;

    /**
     * Contenido textual de la respuesta proporcionada por el administrador.
     * <p>
     * Se almacena como {@code TEXT} para permitir respuestas detalladas.
     * </p>
     */
    @Column(nullable = false, columnDefinition = "TEXT")
    private String response;

    /**
     * Marca de tiempo que indica la fecha y hora de creación de la respuesta.
     * <p>
     * Se establece automáticamente al momento de la persistencia inicial.
     * </p>
     */
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    /**
     * Marca de tiempo que indica la última fecha y hora de modificación de la respuesta.
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