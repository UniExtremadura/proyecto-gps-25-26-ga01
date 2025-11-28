package io.audira.community.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.UUID;

/**
 * Servicio responsable de gestionar el almacenamiento físico de archivos en el sistema de archivos local.
 * <p>
 * Implementa métodos para inicializar el directorio de subida, almacenar archivos de forma segura
 * (generando nombres únicos y previniendo ataques de recorrido de ruta) y validar los tipos de archivo.
 * </p>
 *
 * @author Grupo GA01
 * 
 */
@Service
public class FileStorageService {

    private final Path fileStorageLocation;

    /**
     * Constructor que inicializa el directorio de almacenamiento de archivos.
     * <p>
     * Obtiene la ruta del directorio de subida de la configuración (por defecto: {@code uploads})
     * y crea el directorio si no existe.
     * </p>
     *
     * @param uploadDir La ruta del directorio de subida, inyectada desde {@code ${file.upload-dir}}.
     * @throws RuntimeException si no se puede crear el directorio.
     */
    public FileStorageService(@Value("${file.upload-dir:uploads}") String uploadDir) {
        this.fileStorageLocation = Paths.get(uploadDir).toAbsolutePath().normalize();
        try {
            Files.createDirectories(this.fileStorageLocation);
        } catch (Exception ex) {
            throw new RuntimeException("No se pudo crear el directorio de subida de archivos.", ex);
        }
    }

    /**
     * Almacena un archivo {@link MultipartFile} en la ubicación de almacenamiento, dentro de un subdirectorio especificado.
     * <p>
     * Garantiza un nombre de archivo único para evitar colisiones y realiza validaciones de seguridad básicas.
     * </p>
     *
     * @param file El archivo multipart a almacenar.
     * @param subDirectory El subdirectorio de destino (ej. "perfiles", "banners").
     * @return La ruta relativa del archivo almacenado (ej. "subdirectorio/nombre_unico.ext").
     * @throws RuntimeException si el archivo está vacío, contiene una ruta inválida o falla la operación de E/S.
     */
    public String storeFile(MultipartFile file, String subDirectory) {
        // Normalizar nombre del archivo original
        String originalFileName = StringUtils.cleanPath(file.getOriginalFilename());

        try {
            // 1. Verificar que el archivo no esté vacío
            if (file.isEmpty()) {
                throw new RuntimeException("El archivo está vacío: " + originalFileName);
            }

            // 2. Verificar que el nombre del archivo no contenga caracteres inválidos (ataque de recorrido de ruta)
            if (originalFileName.contains("..")) {
                throw new RuntimeException("El nombre del archivo contiene una secuencia de ruta inválida: " + originalFileName);
            }

            // 3. Generar un nombre único para el archivo
            String fileExtension = "";
            int dotIndex = originalFileName.lastIndexOf('.');
            if (dotIndex > 0) {
                fileExtension = originalFileName.substring(dotIndex);
            }
            String fileName = UUID.randomUUID().toString() + fileExtension;

            // 4. Crear subdirectorio si es necesario
            Path targetLocation = this.fileStorageLocation.resolve(subDirectory);
            Files.createDirectories(targetLocation);

            // 5. Copiar archivo a la ubicación de destino
            Path destinationFile = targetLocation.resolve(fileName);
            Files.copy(file.getInputStream(), destinationFile, StandardCopyOption.REPLACE_EXISTING);

            return subDirectory + "/" + fileName;
        } catch (IOException ex) {
            throw new RuntimeException("No se pudo almacenar el archivo " + originalFileName + ". Por favor, intente nuevamente.", ex);
        }
    }

    /**
     * Elimina un archivo del sistema de archivos local utilizando su ruta relativa.
     *
     * @param filePath La ruta relativa del archivo (ej. "perfiles/nombre_unico.jpg").
     * @throws RuntimeException si falla la operación de E/S al intentar eliminar el archivo.
     */
    public void deleteFile(String filePath) {
        try {
            // Resuelve la ruta absoluta y la normaliza para prevenir ataques de recorrido de ruta
            Path file = this.fileStorageLocation.resolve(filePath).normalize();
            Files.deleteIfExists(file);
        } catch (IOException ex) {
            throw new RuntimeException("No se pudo eliminar el archivo: " + filePath, ex);
        }
    }

    /**
     * Verifica si un archivo es una imagen válida basándose en su Content-Type y/o su extensión.
     * <p>
     * Acepta tipos comunes de imagen (JPEG, PNG, GIF, WEBP).
     * </p>
     *
     * @param file El archivo {@link MultipartFile} a validar.
     * @return {@code true} si se considera un archivo de imagen válido.
     */
    public boolean isValidImageFile(MultipartFile file) {
        String contentType = file.getContentType();
        String fileName = file.getOriginalFilename();

        // Verificar por content-type
        boolean validContentType = contentType != null && (
                contentType.equals("image/jpeg") ||
                contentType.equals("image/jpg") ||
                contentType.equals("image/png") ||
                contentType.equals("image/gif") ||
                contentType.equals("image/webp") ||
                contentType.equals("application/octet-stream") // Permitir este tipo genérico como fallback
        );

        // Verificar por extensión del archivo como fallback
        boolean validExtension = false;
        if (fileName != null) {
            String extension = fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase();
            validExtension = extension.equals("jpg") ||
                             extension.equals("jpeg") ||
                             extension.equals("png") ||
                             extension.equals("gif") ||
                             extension.equals("webp");
        }

        // Aceptar si el content-type O la extensión son válidos
        return validContentType || validExtension;
    }

    /**
     * Verifica si un archivo es un archivo de audio válido basándose en su Content-Type y/o su extensión.
     * <p>
     * Acepta tipos comunes de audio (MP3, WAV, FLAC, OGG, AAC).
     * </p>
     *
     * @param file El archivo {@link MultipartFile} a validar.
     * @return {@code true} si se considera un archivo de audio válido.
     */
    public boolean isValidAudioFile (MultipartFile file) {
        String contentType = file.getContentType();
        String fileName = file.getOriginalFilename();

        // Verificar por content-type
        boolean validContentType = contentType != null && (
                contentType.equals("audio/mpeg") ||        // .mp3
                contentType.equals("audio/mp3") ||         // Variante para .mp3
                contentType.equals("audio/wav") ||         // .wav
                contentType.equals("audio/wave") ||        // Variante común
                contentType.equals("audio/x-wav") ||       // Variante común para .wav
                contentType.equals("audio/flac") ||        // .flac
                contentType.equals("audio/x-flac") ||      // Variante común para .flac
                contentType.equals("audio/midi") ||        // .midi
                contentType.equals("audio/x-midi") ||      // Variante común para .midi
                contentType.equals("audio/ogg") ||         // .ogg
                contentType.equals("audio/aac") ||         // .aac
                contentType.equals("application/octet-stream") // Tipo genérico permitido
        );

        // Verificar por extensión del archivo como fallback
        boolean validExtension = false;
        if (fileName != null) {
            String extension = fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase();
            validExtension = extension.equals("mp3") ||
                             extension.equals("wav") ||
                             extension.equals("flac") ||
                             extension.equals("midi") ||
                             extension.equals("mid") ||
                             extension.equals("ogg") ||
                             extension.equals("aac");
        }

        return validContentType || validExtension;
    }
}