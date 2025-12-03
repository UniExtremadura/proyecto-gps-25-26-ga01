package io.audira.commerce.model;

/**
 * Enumerador que define el ciclo de vida o los posibles estados por los que puede pasar un registro de pago (Payment).
 * <p>
 * Estos estados son cruciales para determinar si una transacción fue exitosa y para gestionar flujos como reintentos y reembolsos.
 * </p>
 *
 * @author Grupo GA01
 * 
 */
public enum PaymentStatus {
    /**
     * El pago ha sido iniciado pero la confirmación de la pasarela aún está pendiente. Es el estado inicial.
     */
    PENDING,

    /**
     * El pago está siendo activamente procesado por la pasarela externa.
     */
    PROCESSING,

    /**
     * El pago ha sido completado y los fondos han sido confirmados como recibidos. (Estado final exitoso).
     */
    COMPLETED,

    /**
     * El pago ha sido rechazado o ha fallado por razones bancarias, de tarjeta o de la pasarela. (Estado final fallido).
     */
    FAILED,

    /**
     * El pago ha sido devuelto total o parcialmente al comprador. (Estado final de anulación).
     */
    REFUNDED,

    /**
     * El intento de pago ha sido anulado antes de ser enviado a la pasarela, típicamente por una acción del usuario o del sistema.
     */
    CANCELLED
}