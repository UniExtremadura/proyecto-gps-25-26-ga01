package io.audira.commerce.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

/**
 * Clase de configuración para beans de infraestructura relacionados con la comunicación HTTP.
 * <p>
 * Esta clase está anotada con {@link Configuration} y se encarga de definir
 * la instancia de {@link RestTemplate} que será utilizada por los clientes (clients)
 * de microservicios para realizar llamadas síncronas a otros servicios.
 * </p>
 *
 * @author Grupo GA01
 * @see RestTemplate
 * 
 */
@Configuration
public class RestTemplateConfig {

    /**
     * Define el bean de {@link RestTemplate} por defecto para el contexto de Spring.
     * <p>
     * Esta instancia es utilizada para el consumo de APIs REST, permitiendo a otros
     * componentes (como los clientes en el paquete {@code io.audira.commerce.client})
     * realizar peticiones HTTP salientes de forma síncrona.
     * </p>
     *
     * @return Una nueva instancia básica de {@link RestTemplate}.
     */
    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }
}