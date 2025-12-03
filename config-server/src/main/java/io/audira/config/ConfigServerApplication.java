package io.audira.config;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.config.server.EnableConfigServer;

/**
 * Punto de entrada principal para la aplicación del Servidor de Configuración.
 * <p>
 * Esta clase arranca una aplicación Spring Boot configurada específicamente para funcionar
 * como un servidor de configuración centralizado, distribuyendo propiedades a otros microservicios.
 * </p>
 * <p>
 * Hace uso de las siguientes anotaciones clave:
 * <ul>
 * <li>{@link SpringBootApplication} - Configura el escaneo de componentes y la autoconfiguración.</li>
 * <li>{@link EnableConfigServer} - Activa la implementación del servidor de configuración de Spring Cloud.</li>
 * </ul>
 * </p>
 */
@SpringBootApplication
@EnableConfigServer
public class ConfigServerApplication {

    /**
     * Inicializa y ejecuta la aplicación Spring Boot.
     *
     * @param args Argumentos de línea de comandos pasados durante el inicio de la JVM.
     * @see SpringApplication#run(Class, String...)
     */
    public static void main(String[] args) {
        SpringApplication.run(ConfigServerApplication.class, args);
    }
}
