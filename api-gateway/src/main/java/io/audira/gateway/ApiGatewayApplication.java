package io.audira.gateway;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.WebApplicationType;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

/**
 * Punto de entrada principal para el servicio de API Gateway del sistema Audira.
 *
 * @author Grupo GA01
 * 
 */
@SpringBootApplication
@EnableDiscoveryClient
public class ApiGatewayApplication {

    /**
     * Método principal que inicializa y ejecuta la aplicación Spring Boot.
     * <p>
     * Es crucial configurar el tipo de aplicación web como {@link WebApplicationType#REACTIVE}
     * para asegurar el funcionamiento no bloqueante del Gateway.
     * </p>
     *
     * @param args Argumentos de línea de comandos pasados al iniciar la aplicación.
     */
    public static void main(String[] args) {
        SpringApplication app = new SpringApplication(ApiGatewayApplication.class);
        app.setWebApplicationType(WebApplicationType.REACTIVE);
        app.run(args);
    }
}