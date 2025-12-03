package io.audira.commerce.model;

/**
 * Enumerador que define los métodos o instrumentos de pago aceptados para procesar las transacciones de compra.
 * <p>
 * Estos métodos pueden ser directos (tarjetas) o pasarelas de pago intermedias (ej. Stripe, PayPal).
 * </p>
 *
 * @author Grupo GA01
 * 
 */
public enum PaymentMethod {
    /**
     * Pago realizado mediante tarjeta de crédito (Visa, Mastercard, etc.).
     */
    CREDIT_CARD,
    
    /**
     * Pago realizado mediante tarjeta de débito.
     */
    DEBIT_CARD,
    
    /**
     * Pago procesado a través de la pasarela de pago Stripe.
     */
    STRIPE,
    
    /**
     * Pago procesado a través de la plataforma de pagos PayPal.
     */
    PAYPAL,
    
    /**
     * Pago realizado mediante transferencia bancaria directa (ej. SEPA o ACH).
     */
    BANK_TRANSFER
}