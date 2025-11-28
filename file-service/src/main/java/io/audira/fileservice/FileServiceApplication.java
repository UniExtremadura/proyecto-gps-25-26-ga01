package io.audira.fileservice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

/**
 * Punto de entrada principal para el microservicio de Gestión de Archivos (File Service).
 * <p>
 * Esta aplicación es responsable de todo el ciclo de vida de los archivos multimedia dentro
 * de la plataforma Audira, incluyendo:
 * <ul>
 * <li>Ingesta y validación de subidas (Uploads).</li>
 * <li>Almacenamiento físico en disco.</li>
 * <li>Compresión y optimización (ZIP).</li>
 * <li>Distribución y streaming de contenido (Range requests).</li>
 * </ul>
 * </p>
 * <p>
 * Utiliza las siguientes anotaciones de infraestructura:
 * <ul>
 * <li>{@link SpringBootApplication}: Configura el contexto de Spring, incluyendo el escaneo de
 * los controladores y servicios definidos en el paquete {@code io.audira.fileservice}.</li>
 * <li>{@link EnableDiscoveryClient}: Habilita el cliente de descubrimiento (Eureka Client),
 * permitiendo que este servicio se registre automáticamente en el {@code DiscoveryServer}
 * para ser localizado por otros microservicios (como el backend principal).</li>
 * </ul>
 * </p>
 *
 * @author Audira Team
 * @version 1.0
 * @see io.audira.fileservice.controller.FileUploadController
 * @see io.audira.fileservice.controller.FileServeController
 */
@SpringBootApplication
@EnableDiscoveryClient
public class FileServiceApplication {

    /**
     * Inicializa el contexto de Spring Boot y arranca el servidor web embebido (Tomcat).
     *
     * @param args Argumentos de la línea de comandos (ej: perfiles de configuración activos).
     * @see SpringApplication#run(Class, String...)
     */
    public static void main(String[] args) {
        SpringApplication.run(FileServiceApplication.class, args);
    }
}
