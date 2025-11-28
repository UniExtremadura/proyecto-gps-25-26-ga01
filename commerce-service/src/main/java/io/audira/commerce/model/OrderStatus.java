package io.audira.commerce.model;

/**
 * Enumerador que define el ciclo de vida o los posibles estados por los que puede pasar una {@link Order} de compra.
 *
 * @author Grupo GA01
 * 
 */
public enum OrderStatus {
    /**
     * Estado inicial de la orden. La orden ha sido creada pero el pago o el procesamiento no han comenzado.
     */
    PENDING,

    /**
     * La orden ha sido confirmada y se está preparando para su cumplimiento (ej. verificando pago, recogiendo artículos).
     */
    PROCESSING,

    /**
     * El pedido ha salido del almacén o la biblioteca digital ha sido liberada para el usuario (si es digital).
     */
    SHIPPED,

    /**
     * El pedido ha sido recibido por el cliente o el acceso al contenido digital ha sido verificado como entregado.
     */
    DELIVERED,

    /**
     * La orden ha sido anulada, ya sea por el usuario, el sistema o el vendedor.
     */
    CANCELLED
}