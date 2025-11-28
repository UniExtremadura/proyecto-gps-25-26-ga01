package io.audira.community.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.UUID;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

/**
 * Servicio encargado de las operaciones de compresión de archivos,
 * creando archivos ZIP a partir de uno o múltiples archivos almacenados en el sistema.
 * <p>
 * Gestiona las rutas de almacenamiento y utiliza la funcionalidad de {@code java.util.zip}
 * para generar los archivos comprimidos.
 * </p>
 *
 * @author Grupo GA01
 * 
 */
@Service
public class FileCompressionService {

    /**
     * Directorio base donde se almacenan todos los archivos cargados, configurado
     * mediante la propiedad {@code file.upload-dir}. Por defecto es "uploads".
     */
    @Value("${file.upload-dir:uploads}")
    private String uploadDir;

    /**
     * Comprime una lista de archivos en un único archivo ZIP.
     * <p>
     * El archivo ZIP se guarda en el subdirectorio {@code compressed/} con un nombre
     * generado aleatoriamente (UUID).
     * </p>
     *
     * @param filePaths Lista de rutas relativas de archivos (ej: "audio-files/abc.mp3").
     * @return Ruta relativa del archivo ZIP generado (ej: "compressed/UUID.zip").
     * @throws IOException Si ocurre un error de I/O durante la compresión o si un archivo fuente no es encontrado.
     * @throws FileNotFoundException Si alguna de las rutas en {@code filePaths} no corresponde a un archivo existente.
     */
    public String compressFiles(List<String> filePaths) throws IOException {
        Path fileStorageLocation = Paths.get(uploadDir).toAbsolutePath().normalize();

        // Crear directorio para archivos comprimidos
        Path compressedDir = fileStorageLocation.resolve("compressed");
        Files.createDirectories(compressedDir);

        // Generar nombre único para el archivo ZIP
        String zipFileName = UUID.randomUUID().toString() + ".zip";
        Path zipFilePath = compressedDir.resolve(zipFileName);

        try (FileOutputStream fos = new FileOutputStream(zipFilePath.toFile());
             ZipOutputStream zos = new ZipOutputStream(fos)) {

            for (String filePath : filePaths) {
                Path sourceFile = fileStorageLocation.resolve(filePath).normalize();

                if (!Files.exists(sourceFile)) {
                    throw new FileNotFoundException("Archivo no encontrado: " + filePath);
                }

                // Agregar archivo al ZIP
                addFileToZip(sourceFile, zos, sourceFile.getFileName().toString());
            }
        }

        return "compressed/" + zipFileName;
    }

    /**
     * Comprime un solo archivo en un archivo ZIP.
     * <p>
     * El archivo ZIP generado incluye parte del nombre original del archivo y un sufijo
     * de UUID corto para asegurar la unicidad. Se almacena en {@code compressed/}.
     * </p>
     *
     * @param filePath Ruta relativa del archivo a comprimir.
     * @return Ruta relativa del archivo ZIP generado (ej: "compressed/archivo_UUID.zip").
     * @throws IOException Si ocurre un error de I/O durante la compresión.
     * @throws FileNotFoundException Si el archivo en la ruta especificada no existe.
     */
    public String compressSingleFile(String filePath) throws IOException {
        Path fileStorageLocation = Paths.get(uploadDir).toAbsolutePath().normalize();
        Path sourceFile = fileStorageLocation.resolve(filePath).normalize();

        if (!Files.exists(sourceFile)) {
            throw new FileNotFoundException("Archivo no encontrado: " + filePath);
        }

        // Crear directorio para archivos comprimidos
        Path compressedDir = fileStorageLocation.resolve("compressed");
        Files.createDirectories(compressedDir);

        // Generar nombre único para el archivo ZIP
        String originalFileName = sourceFile.getFileName().toString();
        int dotIndex = originalFileName.lastIndexOf('.');
        String baseName = (dotIndex > 0) ? originalFileName.substring(0, dotIndex) : originalFileName;

        String zipFileName = baseName + "_" +
                             UUID.randomUUID().toString().substring(0, 8) + ".zip";
        Path zipFilePath = compressedDir.resolve(zipFileName);

        try (FileOutputStream fos = new FileOutputStream(zipFilePath.toFile());
             ZipOutputStream zos = new ZipOutputStream(fos)) {

            addFileToZip(sourceFile, zos, originalFileName);
        }

        return "compressed/" + zipFileName;
    }

    /**
     * Agrega un archivo al flujo de salida ZIP.
     * <p>
     * Crea una nueva entrada en el ZIP y escribe el contenido del archivo fuente en el flujo.
     * </p>
     *
     * @param sourceFile La ruta absoluta del archivo fuente a incluir.
     * @param zos El {@link ZipOutputStream} donde se escribirá el archivo.
     * @param entryName El nombre que tendrá el archivo dentro del ZIP.
     * @throws IOException Si ocurre un error de I/O al leer o escribir el archivo.
     */
    private void addFileToZip(Path sourceFile, ZipOutputStream zos, String entryName) throws IOException {
        ZipEntry zipEntry = new ZipEntry(entryName);
        zos.putNextEntry(zipEntry);

        try (FileInputStream fis = new FileInputStream(sourceFile.toFile())) {
            byte[] buffer = new byte[1024];
            int length;
            while ((length = fis.read(buffer)) > 0) {
                zos.write(buffer, 0, length);
            }
        }

        zos.closeEntry();
    }

    /**
     * Obtiene el tamaño en bytes de un archivo específico.
     *
     * @param filePath Ruta relativa del archivo.
     * @return El tamaño del archivo en bytes.
     * @throws IOException Si ocurre un error de I/O al acceder al archivo.
     * @throws FileNotFoundException Si el archivo en la ruta especificada no existe.
     */
    public long getFileSize(String filePath) throws IOException {
        Path fileStorageLocation = Paths.get(uploadDir).toAbsolutePath().normalize();
        Path file = fileStorageLocation.resolve(filePath).normalize();

        if (!Files.exists(file)) {
            throw new FileNotFoundException("Archivo no encontrado: " + filePath);
        }

        return Files.size(file);
    }
}