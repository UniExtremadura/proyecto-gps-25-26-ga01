package io.audira.commerce.model;

public enum NotificationType {
    PURCHASE_NOTIFICATION,  // Notificación al artista de nueva compra
    ORDER_CONFIRMATION,     // Confirmación de pedido al comprador
    PAYMENT_SUCCESS,        // Pago exitoso
    PAYMENT_FAILED,         // Pago fallido
    NEW_FOLLOWER,           // Nuevo seguidor
    NEW_RATING,             // Nueva valoración
    SYSTEM_NOTIFICATION     // Notificación del sistema
}
