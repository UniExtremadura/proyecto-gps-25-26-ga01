package io.audira.community.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;
import java.util.List;

/**
 * Clase de configuración de Spring que define la política global de Intercambio de Recursos de Origen Cruzado (CORS).
 * <p>
 * Esta configuración es vital para permitir que aplicaciones cliente de frontend (ej. React, Vue, Angular)
 * que se ejecutan en un dominio diferente al del backend accedan a los endpoints REST.
 * La configuración actual es altamente permisiva para facilitar el desarrollo y la integración.
 * </p>
 *
 * @author Grupo GA01
 * 
 */
@Configuration
public class CorsConfig {

    /**
     * Define el bean {@link CorsConfigurationSource} que establece las reglas de CORS.
     *
     * @return El {@link CorsConfigurationSource} configurado.
     */
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();

        /**
         * Permitir todos los orígenes (para desarrollo).
         * Nota: En producción, se recomienda reemplazar "*" con los dominios específicos del frontend.
         */
        configuration.setAllowedOriginPatterns(List.of("*"));

        /**
         * Permitir todos los métodos HTTP estándar (GET, POST, PUT, DELETE, OPTIONS, PATCH).
         */
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"));

        /**
         * Permitir todos los headers en la solicitud (Content-Type, Authorization, etc.).
         */
        configuration.setAllowedHeaders(Arrays.asList("*"));

        /**
         * Permitir el envío de cookies o credenciales de autenticación.
         */
        configuration.setAllowCredentials(true);

        /**
         * Headers que el navegador puede exponer a la aplicación cliente.
         */
        configuration.setExposedHeaders(Arrays.asList("Authorization", "Content-Type"));

        /**
         * Tiempo máximo (en segundos) que la respuesta de pre-flight (OPTIONS) puede ser almacenada en caché por el navegador.
         */
        configuration.setMaxAge(3600L);

        // Aplicar esta configuración a todos los paths (/**)
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);

        return source;
    }
}