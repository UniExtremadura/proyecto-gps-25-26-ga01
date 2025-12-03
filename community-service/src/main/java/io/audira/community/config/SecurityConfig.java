package io.audira.community.config;

import io.audira.community.security.CustomUserDetailsService;
import io.audira.community.security.JwtAuthenticationEntryPoint;
import io.audira.community.security.JwtAuthenticationFilter;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfigurationSource;

/**
 * Clase de configuración principal de Spring Security.
 * <p>
 * Habilita la seguridad web ({@link EnableWebSecurity}) y la seguridad a nivel de método ({@link EnableMethodSecurity})
 * para configurar un esquema de seguridad basado en tokens JWT y sin estado (stateless).
 * </p>
 *
 * @author Grupo GA01
 * @see JwtAuthenticationFilter
 * 
 */
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final CustomUserDetailsService customUserDetailsService;
    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final CorsConfigurationSource corsConfigurationSource;
    private final JwtAuthenticationEntryPoint jwtAuthenticationEntryPoint;

    /**
     * Define el filtro principal de la cadena de seguridad HTTP (Security Filter Chain).
     * <p>
     * Configuración clave:
     * <ul>
     * <li>Deshabilita CSRF (típico en APIs REST sin estado).</li>
     * <li>Configura la gestión de sesiones como {@link SessionCreationPolicy#STATELESS} (sin estado), obligatorio para JWT.</li>
     * <li>Define {@link JwtAuthenticationEntryPoint} para manejar errores de autenticación (ej. token inválido o ausente).</li>
     * <li>Define las rutas de acceso público ({@code permitAll()}) y asegura que el resto requiera autenticación ({@code authenticated()}).</li>
     * <li>Añade {@link JwtAuthenticationFilter} antes del filtro estándar de autenticación de usuario/contraseña.</li>
     * </ul>
     * </p>
     *
     * @param http El objeto {@link HttpSecurity} para construir las reglas de seguridad.
     * @return La cadena de filtros de seguridad.
     * @throws Exception Si ocurre un error durante la configuración.
     */
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .cors(cors -> cors.configurationSource(corsConfigurationSource))
                .csrf(csrf -> csrf.disable())
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .exceptionHandling(exception -> exception
                        .authenticationEntryPoint(jwtAuthenticationEntryPoint)
                )
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(
                                // Rutas de autenticación
                                "/api/auth/**",
                                // Rutas de datos públicos de usuario (consulta)
                                "/api/users",
                                "/api/users/{id}",
                                "/api/users/{userId}/followers",
                                "/api/users/{userId}/following",
                                "/api/users/{userId}/following/artists",
                                "/api/users/{userId}/follow/{targetUserId}", // Permitir el follow/unfollow sin autenticación (si la lógica del servicio lo permite)
                                // Rutas de archivos (subida y acceso)
                                "/api/files/**", 
                                // Rutas de consulta de valoraciones
                                "/api/ratings/user/{userId}",
                                "/api/ratings/entity/{entityType}/{entityId}",
                                "/api/ratings/entity/{entityType}/{entityId}/with-comments",
                                "/api/ratings/entity/{entityType}/{entityId}/stats",
                                "/api/ratings/user/{userId}/entity/{entityType}/{entityId}",
                                // Rutas de FAQs y contacto (acceso público)
                                "/api/faqs/**", 
                                "/api/contact/**", 
                                // Rutas de notificaciones (comunicación inter-servicio)
                                "/api/notifications/**",
                                // Otras rutas públicas
                                "/public/**",
                                "/actuator/**",
                                "/error"
                        ).permitAll()
                        .anyRequest().authenticated()
                )
                .authenticationProvider(authenticationProvider())
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    /**
     * Define el proveedor de autenticación de datos (DAO Authentication Provider).
     * <p>
     * Utiliza {@link CustomUserDetailsService} para cargar los detalles del usuario
     * y {@link PasswordEncoder} para la verificación de la contraseña.
     * </p>
     *
     * @return El proveedor de autenticación configurado.
     */
    @Bean
    public AuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider authProvider = new DaoAuthenticationProvider();
        authProvider.setUserDetailsService(customUserDetailsService);
        authProvider.setPasswordEncoder(passwordEncoder());
        return authProvider;
    }

    /**
     * Define el gestor de autenticación (Authentication Manager).
     * <p>
     * Es responsable de coordinar la autenticación de usuarios.
     * </p>
     *
     * @param config La configuración de autenticación.
     * @return El gestor de autenticación.
     * @throws Exception Si no se puede obtener el gestor.
     */
    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    /**
     * Define el bean del codificador de contraseñas.
     * <p>
     * Se utiliza {@link BCryptPasswordEncoder} para almacenar las contraseñas de manera segura (hashing).
     * </p>
     *
     * @return El codificador de contraseñas.
     */
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}