package io.audira.catalog.model;

/**
 * Enumeración que define los estados posibles del ciclo de vida de una colaboración.
 * <p>
 * Soporta el requisito <b>GA01-154: Añadir/aceptar colaboradores</b>, permitiendo
 * gestionar el flujo desde que se envía la invitación hasta que el artista responde.
 * </p>
 */
public enum CollaborationStatus {
    /**
     * Estado inicial. La invitación ha sido enviada por el dueño del contenido
     * pero el artista invitado aún no ha respondido.
     */
    PENDING,

    /**
     * El artista invitado ha aceptado la colaboración.
     * En este estado, el colaborador aparece públicamente en los créditos y su porcentaje de regalías se activa.
     */
    ACCEPTED,

    /**
     * El artista invitado ha declinado la participación.
     * El registro se mantiene por motivos de auditoría o para evitar reenvíos de spam.
     */
    REJECTED
}