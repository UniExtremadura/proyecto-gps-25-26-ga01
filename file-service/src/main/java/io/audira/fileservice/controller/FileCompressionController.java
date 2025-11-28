package io.audira.fileservice.controller;

import io.audira.fileservice.service.FileCompressionService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Controlador REST para operaciones de compresión bajo demanda.
 * <p>
 * Permite agrupar múltiples archivos o comprimir uno individual en formato ZIP,
 * retornando estadísticas sobre la eficiencia de la compresión.
 * </p>
 */
@RestController
@RequestMapping("/api/files")
@RequiredArgsConstructor
public class FileCompressionController {

    private final FileCompressionService fileCompressionService;

    @Value("${file.base-url:http://172.16.0.4:9005}")
    private String baseUrl;

/**
     * Comprime una lista de archivos proporcionada en un único archivo ZIP.
     * <p>
     * Calcula estadísticas como el ratio de compresión para informar al cliente
     * del ahorro de espacio obtenido.
     * </p>
     *
     * @param request Cuerpo JSON que debe contener la clave {@code "filePaths"} con la lista de rutas.
     * @return JSON con la URL de descarga y estadísticas de compresión.
     */    
    @PostMapping("/compress")
    public ResponseEntity<?> compressFiles(@RequestBody Map<String, List<String>> request) {
        try {
            List<String> filePaths = request.get("filePaths");

            if (filePaths == null || filePaths.isEmpty()) {
                return ResponseEntity.badRequest().body(
                    createErrorResponse("Debe proporcionar al menos un archivo para comprimir")
                );
            }

            long totalSizeBefore = 0;
            for (String filePath : filePaths) {
                totalSizeBefore += fileCompressionService.getFileSize(filePath);
            }

            String zipFilePath = fileCompressionService.compressFiles(filePaths);
            String zipFileUrl = baseUrl + "/api/files/" + zipFilePath;

            long compressedSize = fileCompressionService.getFileSize(zipFilePath);
            double compressionRatio = ((double) (totalSizeBefore - compressedSize) / totalSizeBefore) * 100;

            Map<String, Object> response = new HashMap<>();
            response.put("message", "Archivos comprimidos exitosamente");
            response.put("zipFileUrl", zipFileUrl);
            response.put("zipFilePath", zipFilePath);
            response.put("filesCompressed", filePaths.size());
            response.put("originalSize", totalSizeBefore);
            response.put("compressedSize", compressedSize);
            response.put("compressionRatio", String.format("%.2f%%", compressionRatio));

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(
                createErrorResponse("Error al comprimir archivos: " + e.getMessage())
            );
        }
    }

/**
     * Comprime un único archivo.
     *
     * @param request Cuerpo JSON con la clave {@code "filePath"}.
     * @return JSON con la URL del archivo comprimido y ratio de reducción.
     */    
    @PostMapping("/compress/single")
    public ResponseEntity<?> compressSingleFile(@RequestBody Map<String, String> request) {
        try {
            String filePath = request.get("filePath");

            if (filePath == null || filePath.isEmpty()) {
                return ResponseEntity.badRequest().body(
                    createErrorResponse("Debe proporcionar la ruta del archivo")
                );
            }

            long originalSize = fileCompressionService.getFileSize(filePath);
            String zipFilePath = fileCompressionService.compressSingleFile(filePath);
            String zipFileUrl = baseUrl + "/api/files/" + zipFilePath;

            long compressedSize = fileCompressionService.getFileSize(zipFilePath);
            double compressionRatio = ((double) (originalSize - compressedSize) / originalSize) * 100;

            Map<String, Object> response = new HashMap<>();
            response.put("message", "Archivo comprimido exitosamente");
            response.put("zipFileUrl", zipFileUrl);
            response.put("zipFilePath", zipFilePath);
            response.put("originalSize", originalSize);
            response.put("compressedSize", compressedSize);
            response.put("compressionRatio", String.format("%.2f%%", compressionRatio));

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(
                createErrorResponse("Error al comprimir archivo: " + e.getMessage())
            );
        }
    }

/**
     * Crea una respuesta de error JSON estandarizada.
     *
     * @param message Descripción del error.
     * @return Mapa con el error.
     */    
    private Map<String, String> createErrorResponse(String message) {
        Map<String, String> error = new HashMap<>();
        error.put("error", message);
        return error;
    }
}
