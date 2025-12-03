package io.audira.commerce;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

/**
 * Clase principal de la aplicación que arranca el microservicio de Comercio (Commerce Service).
 * <p>
 * Esta clase configura el entorno Spring Boot y habilita la funcionalidad esencial de Spring Cloud:
 * <ul>
 * <li>{@link SpringBootApplication}: Habilita la autoconfiguración de Spring Boot y el escaneo de componentes.</li>
 * <li>{@link EnableDiscoveryClient}: Permite que este servicio se registre y sea descubierto por otros microservicios
 * a través de un servidor de descubrimiento (ej. Eureka, Consul).</li>
 * </ul>
 * </p>
 *
 * @author Grupo GA01
 * 
 */
@SpringBootApplication
@EnableDiscoveryClient
public class CommerceServiceApplication {

    /**
     * Método principal que inicia la aplicación Spring Boot.
     *
     * @param args Argumentos de línea de comandos pasados durante la ejecución de la aplicación.
     */
    public static void main(String[] args) {
        SpringApplication.run(CommerceServiceApplication.class, args);
    }
}