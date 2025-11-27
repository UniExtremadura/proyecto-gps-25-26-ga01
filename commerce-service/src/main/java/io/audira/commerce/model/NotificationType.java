package io.audira.commerce.model;

public enum NotificationType {
    PURCHASE_NOTIFICATION,  // Notificación al artista de nueva compra
    ORDER_CONFIRMATION,     // Confirmación de pedido al comprador
    PAYMENT_SUCCESS,        // Pago exitoso
    PAYMENT_FAILED,         // Pago fallido
    NEW_FOLLOWER,           // Nuevo seguidor
    NEW_RATING,             // Nueva valoración
    SYSTEM_NOTIFICATION,    // Notificación del sistema
    NEW_PRODUCT,            // Nuevo producto de artista seguido
    TICKET_CREATED,         // Ticket creado (notificación al admin)
    TICKET_RESPONSE,        // Respuesta a ticket (notificación al usuario/artista)
    TICKET_RESOLVED,        // Ticket resuelto (notificación al usuario/artista)
    PRODUCT_PENDING_REVIEW, // Producto pendiente de revisión (notificación al admin)
    PRODUCT_APPROVED,       // Producto aprobado (notificación al artista)
    PRODUCT_REJECTED        // Producto rechazado (notificación al artista)
}
