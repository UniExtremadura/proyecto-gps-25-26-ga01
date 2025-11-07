package io.audira.community.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.nio.file.Path;
import java.nio.file.Paths;

@RestController
@RequestMapping("/api/files")
@RequiredArgsConstructor
public class FileServeController {

    @Value("${file.upload-dir:uploads}")
    private String uploadDir;

    @GetMapping("/{subDirectory}/{fileName:.+}")
    public ResponseEntity<Resource> serveFile(
            @PathVariable String subDirectory,
            @PathVariable String fileName) {

        try {
            Path fileStorageLocation = Paths.get(uploadDir).toAbsolutePath().normalize();
            Path filePath = fileStorageLocation.resolve(subDirectory).resolve(fileName).normalize();
            Resource resource = new UrlResource(filePath.toUri());

            if (resource.exists() && resource.isReadable()) {
                String contentType = "application/octet-stream";

                // Determinar el tipo de contenido basado en la extensión
                String fileExtension = fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase();
                switch (fileExtension) {
                    case "jpg":
                    case "jpeg":
                        contentType = "image/jpeg";
                        break;
                    case "png":
                        contentType = "image/png";
                        break;
                    case "gif":
                        contentType = "image/gif";
                        break;
                    case "webp":
                        contentType = "image/webp";
                        break;
                    case "mp3":
                        contentType = "audio/mpeg";
                        break;
                    case "wav":
                        contentType = "audio/wav";
                        break;
                    case "flac":
                        contentType = "audio/flac";
                        break;
                    case "midi":
                    case "mid":
                        contentType = "audio/midi";
                        break;
                }
                return ResponseEntity.ok()
                        .contentType(MediaType.parseMediaType(contentType))
                        .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + resource.getFilename() + "\"")
                        .body(resource);
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    private boolean isAudioFile(String fileName) {
        String extension = fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase();
        return extension.equals("mp3") || extension.equals("wav") ||
            extension.equals("flac") || extension.equals("midi") ||
            extension.equals("mid");
    }
}
