package io.audira.community.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.SuperBuilder;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

/**
 * Entidad de base de datos abstracta que representa el modelo base de usuario en el sistema.
 * <p>
 * Mapeada a la tabla {@code users}. Utiliza la estrategia de herencia {@code InheritanceType.JOINED}
 * donde los campos comunes se almacenan en esta tabla base y los campos específicos de las subclases (ej. {@code Artist}, {@code Admin})
 * se almacenan en tablas separadas unidas por la clave primaria.
 * </p>
 * <p>
 * {@code @DiscriminatorColumn} define la columna que diferencia los tipos de usuario (ej. 'USER', 'ADMIN', 'ARTIST').
 * </p>
 *
 * @author Grupo GA01
 * @see Entity
 * 
 */
@Entity
@Table(name = "users")
@Inheritance(strategy = InheritanceType.JOINED)
@DiscriminatorColumn(name = "user_type", discriminatorType = DiscriminatorType.STRING)
@Data
@SuperBuilder
@NoArgsConstructor
@AllArgsConstructor
public abstract class User {

    /**
     * ID primario y clave única de la entidad User. Generado automáticamente.
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Campo de versión para el control de concurrencia (Optimistic Locking).
     * Se incrementa automáticamente en cada actualización de la entidad, previniendo actualizaciones perdidas.
     */
    @Version
    private Long version;

    /**
     * ID único de Firebase (si se utiliza como proveedor de identidad).
     */
    @Column(nullable = false, unique = true)
    private String uid;

    /**
     * Dirección de correo electrónico del usuario. Debe ser única.
     */
    @Column(nullable = false, unique = true)
    private String email;

    /**
     * Nombre de usuario o alias. Debe ser único.
     */
    @Column(nullable = false, unique = true)
    private String username;

    /**
     * Contraseña hasheada del usuario.
     */
    @Column(nullable = false)
    private String password;

    /**
     * Nombre de pila o primer nombre del usuario.
     */
    @Column(nullable = false)
    private String firstName;

    /**
     * Apellido del usuario.
     */
    @Column(nullable = false)
    private String lastName;

    /**
     * Biografía o descripción del perfil.
     */
    private String bio;

    /**
     * URL de la imagen de perfil (avatar).
     */
    private String profileImageUrl;

    /**
     * URL de la imagen de banner del perfil.
     */
    private String bannerImageUrl;

    /**
     * Ubicación geográfica del usuario.
     */
    private String location;

    /**
     * Enlace a un sitio web personal.
     */
    private String website;

    // --- Enlaces a Redes Sociales ---
    
    /**
     * URL del perfil de Twitter/X.
     */
    private String twitterUrl;

    /**
     * URL del perfil de Instagram.
     */
    private String instagramUrl;

    /**
     * URL del perfil de Facebook.
     */
    private String facebookUrl;

    /**
     * URL del canal de YouTube.
     */
    private String youtubeUrl;

    /**
     * URL del perfil de Spotify.
     */
    private String spotifyUrl;

    /**
     * URL del perfil de TikTok.
     */
    private String tiktokUrl;

    /**
     * Rol de seguridad del usuario (ej. USER, ARTIST, ADMIN) utilizando el enumerador {@link UserRole}.
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private UserRole role;

    /**
     * Indica si la cuenta está activa y no suspendida.
     * <p>
     * Se inicializa a {@code true} en {@link #onCreate()}.
     * </p>
     */
    @Column(nullable = false)
    private Boolean isActive;

    /**
     * Indica si el correo electrónico del usuario ha sido verificado.
     * <p>
     * Se inicializa a {@code false} en {@link #onCreate()}.
     * </p>
     */
    @Column(nullable = false)
    private Boolean isVerified;

    /**
     * Conjunto de IDs de usuarios que siguen a este perfil (seguidores).
     * <p>
     * Mapeado a una tabla de colección separada ({@code user_followers}).
     * La relación se carga de forma eager ({@code FetchType.EAGER}).
     * </p>
     */
    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "user_followers", joinColumns = @JoinColumn(name = "user_id"))
    @Column(name = "follower_id")
    private Set<Long> followerIds = new HashSet<>();

    /**
     * Conjunto de IDs de usuarios a los que este perfil está siguiendo.
     * <p>
     * Mapeado a una tabla de colección separada ({@code user_following}).
     * La relación se carga de forma eager ({@code FetchType.EAGER}).
     * </p>
     */
    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "user_following", joinColumns = @JoinColumn(name = "user_id"))
    @Column(name = "following_id")
    private Set<Long> followingIds = new HashSet<>();

    /**
     * Marca de tiempo de la creación de la cuenta.
     */
    @Column(nullable = false)
    private LocalDateTime createdAt;

    /**
     * Marca de tiempo de la última actualización del perfil.
     */
    private LocalDateTime updatedAt;

    /**
     * Método de callback de JPA que se ejecuta antes de la persistencia (guardar por primera vez).
     * <p>
     * Inicializa {@code createdAt}, {@code updatedAt}, {@code isActive} y {@code isVerified}.
     * </p>
     */
    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
        if (this.isActive == null) {
            this.isActive = true;
        }
        if (this.isVerified == null) {
            this.isVerified = false;
        }
    }

    /**
     * Método de callback de JPA que se ejecuta antes de cualquier actualización.
     * <p>
     * Actualiza {@code updatedAt}.
     * </p>
     */
    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    /**
     * Método abstracto que debe ser implementado por las subclases para retornar el tipo específico de usuario (ej. "USER", "ADMIN", "ARTIST").
     *
     * @return El tipo de usuario como {@link String}.
     */
    public abstract String getUserType();
}