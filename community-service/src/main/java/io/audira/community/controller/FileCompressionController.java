package io.audira.community.controller;

import io.audira.community.service.FileCompressionService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/files")
@RequiredArgsConstructor
public class FileCompressionController {

    private final FileCompressionService fileCompressionService;

    @Value("${file.base-url:http://158.49.191.109:9001}")
    private String baseUrl;

    /**
     * Endpoint para comprimir múltiples archivos en un ZIP
     * POST /api/files/compress
     * Body: { "filePaths": ["audio-files/abc.mp3", "images/def.jpg"] }
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

            // Obtener tamaño total antes de comprimir
            long totalSizeBefore = 0;
            for (String filePath : filePaths) {
                totalSizeBefore += fileCompressionService.getFileSize(filePath);
            }

            // Comprimir archivos
            String zipFilePath = fileCompressionService.compressFiles(filePaths);
            String zipFileUrl = baseUrl + "/api/files/" + zipFilePath;

            // Obtener tamaño del archivo comprimido
            long compressedSize = fileCompressionService.getFileSize(zipFilePath);

            // Calcular porcentaje de compresión
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
     * Endpoint para comprimir un solo archivo
     * POST /api/files/compress/single
     * Body: { "filePath": "audio-files/abc.mp3" }
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

            // Obtener tamaño antes de comprimir
            long originalSize = fileCompressionService.getFileSize(filePath);

            // Comprimir archivo
            String zipFilePath = fileCompressionService.compressSingleFile(filePath);
            String zipFileUrl = baseUrl + "/api/files/" + zipFilePath;

            // Obtener tamaño del archivo comprimido
            long compressedSize = fileCompressionService.getFileSize(zipFilePath);

            // Calcular porcentaje de compresión
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

    private Map<String, String> createErrorResponse(String message) {
        Map<String, String> error = new HashMap<>();
        error.put("error", message);
        return error;
    }
}
