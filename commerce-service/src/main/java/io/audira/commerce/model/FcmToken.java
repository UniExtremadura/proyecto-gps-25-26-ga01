package io.audira.commerce.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/**
 * Entidad de base de datos que representa un Token de Firebase Cloud Messaging (FCM) asociado a un usuario.
 * <p>
 * Mapeada a la tabla {@code fcm_tokens}. Esta entidad es esencial para el envío de notificaciones
 * push, ya que almacena el identificador único del dispositivo o navegador del usuario.
 * </p>
 *
 * @author Grupo GA01
 * @see Platform
 * @see Entity
 * 
 */
@Entity
@Table(name = "fcm_tokens", indexes = {
    @Index(name = "idx_user_id", columnList = "userId"),
    @Index(name = "idx_token", columnList = "token")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FcmToken {

    /**
     * ID primario y clave única de la entidad FcmToken. Generado automáticamente.
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * ID del usuario (tipo {@link Long}) al que pertenece este token.
     * <p>
     * Se crea un índice ({@code idx_user_id}) sobre esta columna para acelerar las consultas por usuario.
     * </p>
     */
    @Column(nullable = false)
    private Long userId;

    /**
     * El token FCM único del dispositivo o navegador.
     * <p>
     * Es único en la base de datos y se le asigna una longitud máxima de 500 caracteres.
     * Se crea un índice ({@code idx_token}) para búsquedas rápidas por token.
     * </p>
     */
    @Column(nullable = false, unique = true, length = 500)
    private String token;

    /**
     * Plataforma del dispositivo asociado al token (ej. ANDROID, IOS, WEB) utilizando el enumerador {@link Platform}.
     * <p>
     * Mapeado como String en la base de datos ({@code @Enumerated(EnumType.STRING)}).
     * </p>
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Platform platform;

    /**
     * Marca de tiempo de la creación inicial del registro.
     */
    @Column(nullable = false)
    private LocalDateTime createdAt;

    /**
     * Marca de tiempo de la última actualización del registro (ej. al actualizar la hora de registro).
     */
    @Column(nullable = false)
    private LocalDateTime updatedAt;

    /**
     * Método de callback de JPA que se ejecuta antes de la persistencia (guardar por primera vez).
     * <p>
     * Inicializa {@code createdAt} y {@code updatedAt}.
     * </p>
     */
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    /**
     * Método de callback de JPA que se ejecuta antes de cualquier actualización.
     * <p>
     * Actualiza {@code updatedAt}.
     * </p>
     */
    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}