package io.audira.community.exception;

/**
 * Excepción personalizada de tipo {@link RuntimeException} utilizada para errores específicos dentro de las operaciones de Valoración (Rating).
 * <p>
 * Agrupa varias excepciones comunes (ej. recurso no encontrado, acceso no autorizado) para una mejor gestión y diferenciación en la capa de controlador.
 * </p>
 * Requisitos asociados: GA01-128, GA01-129, GA01-130.
 *
 * @author Grupo GA01
 * 
 */
public class RatingException extends RuntimeException {

    /**
     * Constructor base que acepta un mensaje de error.
     *
     * @param message El mensaje de error detallado.
     */
    public RatingException(String message) {
        super(message);
    }

    /**
     * Constructor que acepta un mensaje y la causa subyacente de la excepción.
     *
     * @param message El mensaje de error detallado.
     * @param cause La causa original de la excepción.
     */
    public RatingException(String message, Throwable cause) {
        super(message, cause);
    }

    // --- Subclases de Excepción ---

    /**
     * Se lanza cuando no se encuentra un registro de valoración (Rating) con el ID especificado.
     */
    public static class RatingNotFoundException extends RatingException {
        /**
         * Inicializa la excepción con un mensaje que indica qué ID de valoración no se encontró.
         *
         * @param ratingId El ID de la valoración que no se pudo localizar.
         */
        public RatingNotFoundException(Long ratingId) {
            super("Rating with ID " + ratingId + " not found");
        }
    }

    /**
     * Se lanza cuando un usuario intenta modificar o eliminar una valoración que no le pertenece.
     */
    public static class UnauthorizedRatingAccessException extends RatingException {
        /**
         * Inicializa la excepción con un mensaje de acceso no autorizado.
         */
        public UnauthorizedRatingAccessException() {
            super("You are not authorized to modify this rating");
        }
    }

    /**
     * Se lanza cuando un usuario intenta crear una nueva valoración para una entidad que ya ha valorado.
     */
    public static class DuplicateRatingException extends RatingException {
        /**
         * Inicializa la excepción con un mensaje que indica la entidad duplicada.
         *
         * @param entityType El tipo de entidad (ej. "SONG").
         * @param entityId El ID de la entidad.
         */
        public DuplicateRatingException(String entityType, Long entityId) {
            super("You have already rated this " + entityType.toLowerCase() + " (ID: " + entityId + ")");
        }
    }

    /**
     * Se lanza cuando la puntuación (estrellas) proporcionada está fuera del rango permitido (1 a 5).
     */
    public static class InvalidRatingValueException extends RatingException {
        /**
         * Inicializa la excepción con un mensaje de valoración inválida.
         */
        public InvalidRatingValueException() {
            super("Rating value must be between 1 and 5 stars");
        }
    }

    /**
     * Se lanza cuando el comentario de la valoración excede la longitud máxima permitida (500 caracteres).
     */
    public static class InvalidCommentLengthException extends RatingException {
        /**
         * Inicializa la excepción con un mensaje de longitud de comentario inválida.
         */
        public InvalidCommentLengthException() {
            super("Comment cannot exceed 500 characters");
        }
    }

    /**
     * Se lanza cuando se requiere que el producto haya sido comprado antes de poder ser valorado (regla de negocio).
     */
    public static class ProductNotPurchasedException extends RatingException {
        /**
         * Inicializa la excepción con un mensaje de producto no comprado.
         *
         * @param entityType El tipo de entidad.
         * @param entityId El ID de la entidad.
         */
        public ProductNotPurchasedException(String entityType, Long entityId) {
            super("You must purchase this " + entityType.toLowerCase() + " before rating it (ID: " + entityId + ")");
        }
    }
}