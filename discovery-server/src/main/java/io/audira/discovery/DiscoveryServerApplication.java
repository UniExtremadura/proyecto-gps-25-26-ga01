package io.audira.discovery;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.netflix.eureka.server.EnableEurekaServer;

/**
 * La aplicación del Servidor de Descubrimiento (Service Registry).
 * <p>
 * Esta clase levanta una instancia de <b>Netflix Eureka Server</b>. Actúa como una guía telefónica
 * o registro central donde todos los demás microservicios de la arquitectura ("clientes")
 * deben registrarse al iniciar.
 * </p>
 * <p>
 * Su función principal es permitir la comunicación entre servicios sin acoplamiento a
 * direcciones IP físicas, facilitando el balanceo de carga del lado del cliente.
 * </p>
 *
 * @see EnableEurekaServer
 */
@SpringBootApplication
@EnableEurekaServer
public class DiscoveryServerApplication {

    /**
     * Punto de entrada principal (Entry Point).
     *
     * @param args Argumentos de la línea de comandos.
     */
    public static void main(String[] args) {
        SpringApplication.run(DiscoveryServerApplication.class, args);
    }
}
