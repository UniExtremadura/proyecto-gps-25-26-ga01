package io.audira.community.security;

import io.audira.community.model.User;
import io.audira.community.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Servicio personalizado de carga de detalles de usuario para la autenticación de Spring Security.
 * <p>
 * Implementa la interfaz {@link UserDetailsService} y se encarga de recuperar la información
 * de un usuario desde la base de datos, convirtiéndola en un objeto {@link UserDetails}
 * (específicamente {@link UserPrincipal}) que Spring Security puede utilizar para la autenticación
 * y la autorización.
 * </p>
 *
 * @author Grupo GA01
 * @see UserDetailsService
 * @see UserPrincipal
 * 
 */
@Service
@RequiredArgsConstructor
public class CustomUserDetailsService implements UserDetailsService {

    /**
     * Repositorio utilizado para acceder a la información de los usuarios en la base de datos.
     */
    private final UserRepository userRepository;

    /**
     * Carga los detalles del usuario basándose en el nombre de usuario o correo electrónico.
     * <p>
     * Este es el método principal requerido por la interfaz {@link UserDetailsService}
     * para el proceso de autenticación.
     * </p>
     *
     * @param usernameOrEmail El nombre de usuario o la dirección de correo electrónico utilizada para la autenticación.
     * @return Un objeto {@link UserDetails} (en este caso, {@link UserPrincipal}) que contiene los detalles del usuario.
     * @throws UsernameNotFoundException Si no se encuentra ningún usuario con el nombre/email proporcionado.
     */
    @Override
    @Transactional
    public UserDetails loadUserByUsername(String usernameOrEmail) throws UsernameNotFoundException {
        User user = userRepository.findByEmailOrUsername(usernameOrEmail, usernameOrEmail)
                .orElseThrow(() -> new UsernameNotFoundException("User not found with email or username: " + usernameOrEmail));

        return UserPrincipal.create(user);
    }

    /**
     * Carga los detalles del usuario basándose en el ID del usuario.
     * <p>
     * Este método se utiliza típicamente en escenarios donde la autenticación se realiza
     * a través de un token (como JWT) que solo contiene el ID del usuario.
     * </p>
     *
     * @param id El ID único del usuario.
     * @return Un objeto {@link UserDetails} ({@link UserPrincipal}) que contiene los detalles del usuario.
     * @throws UsernameNotFoundException Si no se encuentra ningún usuario con el ID proporcionado.
     */
    @Transactional
    public UserDetails loadUserById(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new UsernameNotFoundException("User not found with id: " + id));

        return UserPrincipal.create(user);
    }
}