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
 * Entidad de base de datos que representa un mensaje de contacto, una consulta general o un ticket de soporte enviado por un usuario.
 * <p>
 * Mapeada a la tabla {@code contact_messages}. Almacena los detalles del remitente, el contenido del mensaje
 * y el estado actual de procesamiento (ej. {@link ContactStatus#PENDING}, {@link ContactStatus#RESOLVED}).
 * </p>
 *
 * @author Grupo GA01
 * @see ContactStatus
 * @see Entity
 * 
 */
@Entity
@Table(name = "contact_messages")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ContactMessage {

    /**
     * ID primario y clave única de la entidad ContactMessage. Generado automáticamente.
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Nombre del remitente del mensaje.
     */
    @Column(nullable = false, length = 255)
    private String name;

    /**
     * Dirección de correo electrónico del remitente.
     */
    @Column(nullable = false, length = 255)
    private String email;

    /**
     * Asunto o título del mensaje de contacto.
     */
    @Column(nullable = false, length = 500)
    private String subject;

    /**
     * Contenido detallado del mensaje.
     * <p>
     * Utiliza {@code columnDefinition = "TEXT"} para permitir cuerpos de mensaje largos.
     * </p>
     */
    @Column(nullable = false, columnDefinition = "TEXT")
    private String message;

    /**
     * ID del usuario autenticado que envió el mensaje (opcional, nulo si lo envía un visitante).
     */
    @Column(name = "user_id")
    private Long userId;

    /**
     * ID de la canción a la que hace referencia la consulta (opcional).
     */
    @Column(name = "song_id")
    private Long songId;

    /**
     * ID del álbum al que hace referencia la consulta (opcional).
     */
    @Column(name = "album_id")
    private Long albumId;

    /**
     * Indica si el mensaje ha sido revisado por el equipo de administración/soporte.
     * <p>
     * Valor por defecto: {@code false}.
     * </p>
     */
    @Column(name = "is_read", nullable = false)
    @Builder.Default
    private Boolean isRead = false;

    /**
     * Estado actual del procesamiento del mensaje (ej. PENDING, IN_PROGRESS, RESOLVED).
     * <p>
     * Mapeado como String en la base de datos ({@code @Enumerated(EnumType.STRING)}).
     * Valor por defecto: {@code PENDING}.
     * </p>
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private ContactStatus status = ContactStatus.PENDING;

    /**
     * Marca de tiempo de la creación inicial del mensaje.
     */
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    /**
     * Marca de tiempo de la última actualización del mensaje (ej. al cambiar el estado o marcar como leído).
     */
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    /**
     * Método de callback de JPA que se ejecuta antes de la persistencia (guardar por primera vez).
     * <p>
     * Inicializa {@code createdAt} y {@code updatedAt} utilizando la zona horaria "Europe/Madrid".
     * </p>
     */
    @PrePersist
    protected void onCreate() {
        ZonedDateTime now = ZonedDateTime.now(ZoneId.of("Europe/Madrid"));
        this.createdAt = now.toLocalDateTime();
        this.updatedAt = now.toLocalDateTime();
    }

    /**
     * Método de callback de JPA que se ejecuta antes de cualquier actualización.
     * <p>
     * Actualiza {@code updatedAt} utilizando la zona horaria "Europe/Madrid".
     * </p>
     */
    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = ZonedDateTime.now(ZoneId.of("Europe/Madrid")).toLocalDateTime();
    }
}