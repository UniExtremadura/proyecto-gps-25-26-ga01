package io.audira.gateway.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.reactive.EnableWebFluxSecurity; 
import org.springframework.security.config.web.server.ServerHttpSecurity;
import org.springframework.security.web.server.SecurityWebFilterChain;

/**
 * Clase de configuración de seguridad para el API Gateway de Audira.
 * <p>
 * Utiliza Spring Security WebFlux para el manejo de seguridad en un entorno reactivo (no bloqueante).
 * La anotación {@link EnableWebFluxSecurity} habilita la configuración de seguridad para la web reactiva.
 * </p>
 * <p>
 * NOTA DE SEGURIDAD: Esta configuración establece un acceso totalmente permisivo (permitAll)
 * a todas las rutas. Esto es típico en un API Gateway que opera en conjunto con un
 * servicio de autenticación/autorización dedicado, delegando la validación del token al
 * microservicio posterior o a un filtro JWT independiente.
 * </p>
 *
 * @author Grupo GA01
 * 
 */
@Configuration
@EnableWebFluxSecurity
public class SecurityConfig {

    /**
     * Define la cadena de filtros de seguridad reactiva (SecurityWebFilterChain).
     * <p>
     * Este bean configura el comportamiento de seguridad para el API Gateway.
     * Deshabilita CSRF, HTTP Basic y Form Login, y permite el acceso a todas las peticiones.
     * </p>
     *
     * @param http El objeto {@link ServerHttpSecurity} utilizado para construir la cadena de filtros reactiva.
     * @return La {@link SecurityWebFilterChain} configurada.
     */
    @Bean
    public SecurityWebFilterChain springSecurityFilterChain(ServerHttpSecurity http) {
        
        http
            // Deshabilita la protección CSRF (Cross-Site Request Forgery). 
            // Esto es común para APIs que usan tokens (JWT, OAuth2) en lugar de sesiones.
            .csrf(csrf -> csrf.disable())
            
            // Deshabilita la autenticación HTTP Basic.
            .httpBasic(httpBasic -> httpBasic.disable())
            
            // Deshabilita la autenticación por formulario.
            .formLogin(formLogin -> formLogin.disable())
            
            // Reglas de autorización de intercambio de peticiones
            .authorizeExchange(exchange -> exchange
                // Permite el acceso a todas las rutas del API Gateway
                .pathMatchers("/**").permitAll()
                // Permite el acceso a cualquier otra petición.
                .anyExchange().permitAll()
            );
        
        return http.build();
    }
}