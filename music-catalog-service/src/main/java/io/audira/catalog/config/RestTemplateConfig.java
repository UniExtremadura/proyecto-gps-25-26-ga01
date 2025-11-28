package io.audira.catalog.config;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.ClientHttpRequestInterceptor;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.List;
/**
 * Clase de configuración para los clientes REST de la aplicación.
 * <p>
 * Define y configura los beans necesarios para realizar peticiones HTTP sincrónicas
 * a otros servicios, asegurando que la seguridad (JWT) se propague correctamente.
 * </p>
 */
@Configuration
@RequiredArgsConstructor

public class RestTemplateConfig {
    private final JwtForwardingInterceptor jwtForwardingInterceptor;

    /**
     * Crea y configura un bean de {@link RestTemplate}.
     * <p>
     * Este {@code RestTemplate} está preconfigurado con el {@link JwtForwardingInterceptor},
     * lo que significa que cualquier clase que inyecte este bean y haga una petición
     * enviará automáticamente el token de autenticación del usuario actual.
     * </p>
     *
     * @return Una instancia de {@code RestTemplate} lista para ser inyectada y usada.
     */
    @Bean
    public RestTemplate restTemplate() {
        RestTemplate restTemplate = new RestTemplate();

        List<ClientHttpRequestInterceptor> interceptors = new ArrayList<>();
        interceptors.add(jwtForwardingInterceptor);
        restTemplate.setInterceptors(interceptors);

        return restTemplate;
    }
}