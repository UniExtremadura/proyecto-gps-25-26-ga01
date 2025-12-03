package io.audira.community.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

/**
 * Clase de configuración de Spring que define los beans de infraestructura relacionados con clientes REST.
 * <p>
 * Esta clase, anotada con {@link Configuration}, es responsable de proveer una instancia
 * de {@link RestTemplate} al contexto de la aplicación, permitiendo a los clientes REST
 * (como {@code CommerceClient} o {@code FileServiceClient}) realizar llamadas HTTP síncronas a otros microservicios.
 * </p>
 *
 * @author Grupo GA01
 * @see RestTemplate
 * 
 */
@Configuration
public class RestTemplateConfig {

    /**
     * Define y expone la instancia de {@link RestTemplate} al contenedor de Spring como un bean.
     * <p>
     * Se utiliza la configuración por defecto, adecuada para la comunicación síncrona simple entre servicios.
     * </p>
     *
     * @return Una nueva instancia básica de {@link RestTemplate}.
     */
    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }
}