package io.audira.community.exception;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * Data Transfer Object (DTO) que representa una respuesta de error estandarizada devuelta por la API.
 * <p>
 * Este objeto encapsula información clave sobre el error, como el código de estado HTTP,
 * la marca de tiempo y mensajes detallados, facilitando el manejo de errores en el lado del cliente.
 * </p>
 *
 * @author Grupo GA01
 * 
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ErrorResponse {

    /**
     * Marca de tiempo de la fecha y hora en que ocurrió el error.
     */
    private LocalDateTime timestamp;

    /**
     * Código de estado HTTP de la respuesta de error (ej. 400, 404, 500).
     */
    private int status;

    /**
     * Descripción corta del tipo de error HTTP (ej. "Bad Request", "Not Found").
     */
    private String error;

    /**
     * Mensaje detallado del error, legible por el usuario o el desarrollador.
     */
    private String message;

    /**
     * Mapa opcional de errores de validación de campo, donde la clave es el nombre del campo
     * y el valor es el mensaje de error de validación (utilizado para errores 400 BAD REQUEST).
     */
    private Map<String, String> errors;
}