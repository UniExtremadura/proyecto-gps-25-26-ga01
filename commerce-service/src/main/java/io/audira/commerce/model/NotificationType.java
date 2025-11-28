package io.audira.commerce.model;

/**
 * Enumerador que define las categorías o tipos de notificaciones que el sistema puede generar y enviar a los usuarios.
 * <p>
 * Los tipos se utilizan para clasificar y manejar las notificaciones según su propósito (transaccional, social, o del sistema).
 * </p>
 *
 * @author Grupo GA01
 * 
 */
public enum NotificationType {
    /**
     * Notificación dirigida al **Artista/Vendedor** para informar sobre una nueva compra de su producto. (Transaccional)
     */
    PURCHASE_NOTIFICATION, 

    /**
     * Notificación dirigida al **Comprador** para confirmar que la orden de compra ha sido registrada. (Transaccional)
     */
    ORDER_CONFIRMATION, 

    /**
     * Notificación dirigida al **Comprador** para informar que el proceso de pago se ha completado con éxito. (Transaccional)
     */
    PAYMENT_SUCCESS, 

    /**
     * Notificación dirigida al **Comprador** para informar que el intento de pago ha fallado. (Transaccional)
     */
    PAYMENT_FAILED, 

    /**
     * Notificación dirigida al **Artista** cuando un usuario comienza a seguir su perfil. (Social)
     */
    NEW_FOLLOWER, 

    /**
     * Notificación dirigida al **Artista** cuando un usuario ha dejado una nueva valoración o reseña sobre su producto. (Social)
     */
    NEW_RATING, 

    /**
     * Notificación general generada por procesos internos del sistema, no relacionados con transacciones directas o interacciones sociales.
     */
    SYSTEM_NOTIFICATION, 

    /**
     * Notificación dirigida a los **Seguidores** de un artista cuando este lanza o aprueba un nuevo producto.
     */
    NEW_PRODUCT, 

    /**
     * Notificación dirigida al **Administrador** cuando un nuevo ticket de soporte ha sido creado por un usuario o artista. (Soporte)
     */
    TICKET_CREATED, 

    /**
     * Notificación dirigida al **Usuario/Artista** cuando hay una respuesta del soporte a su ticket. (Soporte)
     */
    TICKET_RESPONSE, 

    /**
     * Notificación dirigida al **Usuario/Artista** para informar que su ticket de soporte ha sido cerrado o resuelto. (Soporte)
     */
    TICKET_RESOLVED, 

    /**
     * Notificación dirigida al **Administrador** para indicar que un nuevo producto ha sido subido por un artista y está pendiente de moderación. (Moderación)
     */
    PRODUCT_PENDING_REVIEW, 

    /**
     * Notificación dirigida al **Artista** para confirmar que su producto ha sido revisado y aprobado para su venta. (Moderación)
     */
    PRODUCT_APPROVED, 

    /**
     * Notificación dirigida al **Artista** para informar que su producto ha sido revisado y rechazado. (Moderación)
     */
    PRODUCT_REJECTED
}