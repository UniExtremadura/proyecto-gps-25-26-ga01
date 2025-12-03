package io.audira.community.security;

import io.audira.community.model.User;
import lombok.AllArgsConstructor;
import lombok.Data;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import java.util.Collection;
import java.util.Collections;

/**
 * Clase principal que representa los detalles del usuario autenticado en Spring Security.
 * <p>
 * Implementa la interfaz {@link UserDetails}, que actúa como un contenedor para la información
 * esencial del usuario (ID, credenciales, roles/autoridades) requerida por Spring Security
 * para realizar la autenticación y los chequeos de autorización.
 * </p>
 *
 * @author Grupo GA01
 * @see UserDetails
 * 
 */
@Data
@AllArgsConstructor
public class UserPrincipal implements UserDetails {

    /**
     * Identificador único del usuario.
     */
    private Long id;

    /**
     * Correo electrónico del usuario (utilizado a menudo como identificador principal).
     */
    private String email;

    /**
     * Nombre de usuario (username) del usuario.
     */
    private String username;

    /**
     * Contraseña codificada del usuario.
     */
    private String password;

    /**
     * Colección de autoridades (roles) concedidas al usuario.
     */
    private Collection<? extends GrantedAuthority> authorities;

    /**
     * Método estático de fábrica para crear una instancia de {@code UserPrincipal}
     * a partir de una entidad {@link User} de la base de datos.
     * <p>
     * Convierte el {@code UserRole} del usuario en un objeto {@link SimpleGrantedAuthority}
     * con el prefijo "ROLE_".
     * </p>
     *
     * @param user La entidad {@link User} de la base de datos.
     * @return Una nueva instancia de {@code UserPrincipal}.
     */
    public static UserPrincipal create(User user) {
        // Asume que el rol se almacena en user.getRole() (ej. UserRole.ADMIN)
        Collection<GrantedAuthority> authorities = Collections.singletonList(
                new SimpleGrantedAuthority("ROLE_" + user.getRole().name())
        );

        return new UserPrincipal(
                user.getId(),
                user.getEmail(),
                user.getUsername(),
                user.getPassword(),
                authorities
        );
    }

    /**
     * Retorna las autoridades (roles) otorgadas al usuario.
     *
     * @return Una colección de objetos {@link GrantedAuthority}.
     */
    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return authorities;
    }

    /**
     * Retorna la contraseña utilizada para autenticar al usuario.
     *
     * @return La contraseña del usuario.
     */
    @Override
    public String getPassword() {
        return password;
    }

    /**
     * Retorna el nombre de usuario utilizado para autenticar al usuario.
     *
     * @return El nombre de usuario (o el campo que actúa como tal, como el email).
     */
    @Override
    public String getUsername() {
        return username;
    }

    /**
     * Indica si la cuenta del usuario no ha expirado.
     * <p>
     * Por defecto, retorna {@code true} (asumiendo que la lógica de expiración se maneja externamente).
     * </p>
     *
     * @return {@code true} si la cuenta es válida (no ha expirado).
     */
    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    /**
     * Indica si el usuario no está bloqueado o inhabilitado.
     * <p>
     * Por defecto, retorna {@code true}.
     * </p>
     *
     * @return {@code true} si la cuenta no está bloqueada.
     */
    @Override
    public boolean isAccountNonLocked() {
        return true;
    }

    /**
     * Indica si las credenciales (contraseña) del usuario no han expirado.
     * <p>
     * Por defecto, retorna {@code true}.
     * </p>
     *
     * @return {@code true} si las credenciales son válidas.
     */
    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    /**
     * Indica si el usuario está habilitado o deshabilitado.
     * <p>
     * Por defecto, retorna {@code true}.
     * </p>
     *
     * @return {@code true} si el usuario está habilitado.
     */
    @Override
    public boolean isEnabled() {
        return true;
    }
}