package io.audira.community.client;

import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

/**
 * Cliente REST para la comunicación con el Microservicio de Archivos (File Service).
 * <p>
 * Este componente es responsable de orquestar la subida de archivos (especialmente imágenes)
 * utilizando el formato {@code multipart/form-data} y manejar las respuestas y errores
 * de comunicación entre microservicios.
 * </p>
 *
 * @author Grupo GA01
 * @see RestTemplate
 * 
 */
@Component
@RequiredArgsConstructor
public class FileServiceClient {

    private static final Logger logger = LoggerFactory.getLogger(FileServiceClient.class);
    private final RestTemplate restTemplate;

    /**
     * URL base del microservicio de Archivos.
     * El valor por defecto es {@code http://file-service:9005}.
     */
    @Value("${file.service.url:http://file-service:9005}")
    private String fileServiceUrl;

    /**
     * Sube un archivo de imagen al servicio de archivos mediante una solicitud POST {@code multipart/form-data}.
     * <p>
     * Llama al endpoint {@code /api/files/upload/image}.
     * </p>
     *
     * @param file El archivo {@link MultipartFile} a subir.
     * @return La URL (tipo {@link String}) del archivo subido proporcionada por el servicio.
     * @throws RuntimeException Si ocurre un error de comunicación HTTP (cliente o servidor) o un error de E/S.
     */
    public String uploadImage(MultipartFile file) throws Exception {
        String uploadUrl = fileServiceUrl + "/api/files/upload/image";

        logger.info("Uploading image {} to file service at {}", file.getOriginalFilename(), uploadUrl);

        try {
            HttpHeaders headers = new HttpHeaders();
            // Establece el tipo de contenido como MULTIPART_FORM_DATA
            headers.setContentType(MediaType.MULTIPART_FORM_DATA);

            // Prepara el cuerpo de la solicitud con el archivo
            MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
            body.add("file", new MultipartFileResource(file));

            HttpEntity<MultiValueMap<String, Object>> requestEntity = new HttpEntity<>(body, headers);

            // Ejecuta la solicitud REST
            ResponseEntity<Map<String, Object>> response = restTemplate.exchange(
                uploadUrl,
                HttpMethod.POST,
                requestEntity,
                // Define el tipo de retorno esperado (Map<String, Object>)
                new ParameterizedTypeReference<Map<String, Object>>() {} 
            );

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                String fileUrl = (String) response.getBody().get("fileUrl");
                logger.info("Successfully uploaded image to file service: {}", fileUrl);
                return fileUrl;
            } else {
                String errorMsg = "Failed to upload image to file service: received status " + response.getStatusCode();
                logger.error(errorMsg);
                throw new RuntimeException(errorMsg);
            }
        } catch (HttpClientErrorException e) {
            String errorMsg = "Client error uploading image to file service: " + e.getStatusCode() + " - " + e.getResponseBodyAsString();
            logger.error(errorMsg, e);
            throw new RuntimeException(errorMsg, e);
        } catch (HttpServerErrorException e) {
            String errorMsg = "Server error uploading image to file service: " + e.getStatusCode() + " - " + e.getResponseBodyAsString();
            logger.error(errorMsg, e);
            throw new RuntimeException(errorMsg, e);
        } catch (Exception e) {
            String errorMsg = "Error uploading image to file service: " + e.getMessage();
            logger.error(errorMsg, e);
            throw new RuntimeException(errorMsg, e);
        }
    }

    /**
     * Clase auxiliar privada y estática para adaptar un objeto {@link MultipartFile}
     * a un {@link ByteArrayResource}, permitiendo que {@link RestTemplate} lo envíe
     * correctamente como parte de una solicitud {@code multipart/form-data}.
     *
     * @author TuNombre o Audira Team
     */
    private static class MultipartFileResource extends ByteArrayResource {

        private final String filename;

        /**
         * Constructor que lee los bytes del {@link MultipartFile} y almacena el nombre del archivo original.
         *
         * @param multipartFile El archivo de origen.
         * @throws Exception Si ocurre un error al leer los bytes del archivo.
         */
        public MultipartFileResource(MultipartFile multipartFile) throws Exception {
            super(multipartFile.getBytes());
            this.filename = multipartFile.getOriginalFilename();
        }

        /**
         * Retorna el nombre del archivo original, necesario para que el servicio REST de destino
         * pueda manejar el archivo correctamente.
         *
         * @return El nombre del archivo.
         */
        @Override
        public String getFilename() {
            return this.filename;
        }
    }
}