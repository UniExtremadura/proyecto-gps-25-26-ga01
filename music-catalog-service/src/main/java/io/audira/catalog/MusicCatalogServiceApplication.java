package io.audira.catalog;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

/**
 * Punto de entrada principal para el microservicio de Catálogo Musical (Music Catalog Service).
 * <p>
 * Este servicio constituye el <b>núcleo del dominio</b> de la plataforma Audira. Es responsable de
 * centralizar y gestionar toda la información referente a:
 * <ul>
 * <li>Metadatos de Canciones y Álbumes.</li>
 * <li>Perfiles de Artistas y Colaboradores.</li>
 * <li>Listas de reproducción (Playlists) y Géneros musicales.</li>
 * <li>Lógica de moderación y descubrimiento de contenido.</li>
 * </ul>
 * </p>
 * <p>
 * Integra las siguientes capacidades de infraestructura:
 * <ul>
 * <li>{@link SpringBootApplication}: Configura el contexto de Spring, la conexión a base de datos (JPA) y los controladores REST.</li>
 * <li>{@link EnableDiscoveryClient}: Habilita el registro automático en el servidor Eureka (Discovery Server),
 * permitiendo que el API Gateway y otros servicios (como File Service o Commerce) localicen este catálogo.</li>
 * </ul>
 * </p>
 *
 * @version 1.0
 */
@SpringBootApplication
@EnableDiscoveryClient
public class MusicCatalogServiceApplication {

    /**
     * Inicializa el contexto de Spring Boot y levanta el servidor web embebido (Tomcat).
     *
     * @param args Argumentos de la línea de comandos (utilizados para definir perfiles activos o configuraciones al vuelo).
     * @see SpringApplication#run(Class, String...)
     */
    public static void main(String[] args) {
        SpringApplication.run(MusicCatalogServiceApplication.class, args);
    }
}
