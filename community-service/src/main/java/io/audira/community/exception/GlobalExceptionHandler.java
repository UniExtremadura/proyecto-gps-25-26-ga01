package io.audira.community.exception;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * Clase de manejo de excepciones global (Global Exception Handler) para todos los controladores REST.
 * <p>
 * Anotada con {@link RestControllerAdvice}, esta clase centraliza la lógica para capturar
 * excepciones lanzadas por cualquier método {@code @RequestMapping} en la aplicación
 * y formatear la respuesta como un objeto {@link ErrorResponse} consistente.
 * </p>
 *
 * @author Grupo GA01
 * @see ErrorResponse
 * 
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger logger = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    /**
     * Maneja las excepciones lanzadas cuando la validación de un objeto {@code @Valid} falla.
     * <p>
     * Captura {@link MethodArgumentNotValidException} y extrae los errores de campo
     * para retornarlos en un mapa.
     * </p>
     *
     * @param ex La excepción {@link MethodArgumentNotValidException}.
     * @return {@link ResponseEntity} con estado HTTP 400 BAD REQUEST y el detalle de los errores de validación.
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidationExceptions(MethodArgumentNotValidException ex) {
        Map<String, String> errors = new HashMap<>();
        ex.getBindingResult().getAllErrors().forEach((error) -> {
            String fieldName = ((FieldError) error).getField();
            String errorMessage = error.getDefaultMessage();
            errors.put(fieldName, errorMessage);
        });

        logger.error("Validation error: {}", errors);

        ErrorResponse errorResponse = ErrorResponse.builder()
                .timestamp(LocalDateTime.now())
                .status(HttpStatus.BAD_REQUEST.value())
                .error("Error de validación")
                .message("Los datos proporcionados no son válidos. Por favor revisa los campos marcados.")
                .errors(errors)
                .build();

        return ResponseEntity.badRequest().body(errorResponse);
    }

    /**
     * Maneja las excepciones de credenciales incorrectas durante el proceso de autenticación.
     * <p>
     * Captura {@link BadCredentialsException} (lanzada típicamente al intentar iniciar sesión con credenciales erróneas).
     * </p>
     *
     * @param ex La excepción {@link BadCredentialsException}.
     * @return {@link ResponseEntity} con estado HTTP 401 UNAUTHORIZED.
     */
    @ExceptionHandler(BadCredentialsException.class)
    public ResponseEntity<ErrorResponse> handleBadCredentials(BadCredentialsException ex) {
        logger.error("Authentication failed: {}", ex.getMessage());

        ErrorResponse errorResponse = ErrorResponse.builder()
                .timestamp(LocalDateTime.now())
                .status(HttpStatus.UNAUTHORIZED.value())
                .error("Error de autenticación")
                .message("El email/usuario o la contraseña son incorrectos. Por favor verifica tus credenciales e intenta de nuevo.")
                .build();

        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(errorResponse);
    }

    /**
     * Maneja excepciones de tipo {@link RuntimeException} no controladas específicamente.
     * <p>
     * Se utiliza como un mecanismo de captura para errores de negocio personalizados
     * que no tienen su propio manejador específico. Retorna un 500 INTERNAL SERVER ERROR.
     * </p>
     *
     * @param ex La excepción {@link RuntimeException}.
     * @return {@link ResponseEntity} con estado HTTP 500 INTERNAL SERVER ERROR y el mensaje de la excepción.
     */
    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<ErrorResponse> handleRuntimeException(RuntimeException ex) {
        logger.error("Runtime error: {}", ex.getMessage(), ex);

        ErrorResponse errorResponse = ErrorResponse.builder()
                .timestamp(LocalDateTime.now())
                .status(HttpStatus.INTERNAL_SERVER_ERROR.value())
                .error("Error del servidor")
                .message(ex.getMessage())
                .build();

        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
    }

    /**
     * Maneja cualquier otra excepción de tipo {@link Exception} que no fue capturada por los manejadores específicos anteriores.
     * <p>
     * Actúa como un manejador de "último recurso".
     * </p>
     *
     * @param ex La excepción {@link Exception}.
     * @return {@link ResponseEntity} con estado HTTP 500 INTERNAL SERVER ERROR y un mensaje genérico.
     */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleGenericException(Exception ex) {
        logger.error("Unexpected error: {}", ex.getMessage(), ex);

        ErrorResponse errorResponse = ErrorResponse.builder()
                .timestamp(LocalDateTime.now())
                .status(HttpStatus.INTERNAL_SERVER_ERROR.value())
                .error("Error inesperado")
                .message("Ha ocurrido un error inesperado. Por favor intenta de nuevo más tarde.")
                .build();

        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
    }
}