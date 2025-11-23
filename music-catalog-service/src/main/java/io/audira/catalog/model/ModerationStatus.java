package io.audira.catalog.model;

/**
 * GA01-162: Estados de moderación para contenido (canciones/álbumes)
 *
 * PENDING: Contenido recién subido o modificado, esperando revisión
 * APPROVED: Contenido aprobado por administrador, puede publicarse
 * REJECTED: Contenido rechazado, requiere cambios antes de nueva revisión
 */
public enum ModerationStatus {
    PENDING("En revisión"),
    APPROVED("Aprobado"),
    REJECTED("Rechazado");

    private final String displayName;

    ModerationStatus(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
