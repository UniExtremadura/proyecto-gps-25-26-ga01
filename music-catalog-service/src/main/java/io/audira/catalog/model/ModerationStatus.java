package io.audira.catalog.model;

/**
 * Enumeración que define la máquina de estados para el flujo de moderación de contenido.
 * <p>
 * Controla la visibilidad y el ciclo de vida de {@link Song} y {@link Album} dentro de la plataforma.
 * Soporta el requisito <b>GA01-162: Moderación de contenido</b>.
 * </p>
 */
public enum ModerationStatus {
    /**
     * Estado inicial por defecto.
     * <p>
     * El contenido ha sido subido por el artista o modificado recientemente.
     * En este estado, la obra <b>no es visible</b> para el público general y espera acción de un administrador.
     * </p>
     */
    PENDING("En revisión"),

    /**
     * El contenido ha superado los criterios de calidad y copyright.
     * <p>
     * Solo las obras en este estado pueden tener el flag {@code published = true} y ser consumidas por los usuarios.
     * </p>
     */
    APPROVED("Aprobado"),

    /**
     * El contenido ha sido devuelto al artista.
     * <p>
     * Implica que existen problemas (calidad de audio, metadatos incorrectos, infracción de derechos)
     * que deben ser corregidos. Se requiere una razón de rechazo adjunta.
     * </p>
     */
    REJECTED("Rechazado");

    private final String displayName;

    /**
     * Constructor del enum.
     * @param displayName Nombre legible para mostrar en la interfaz de usuario.
     */
    ModerationStatus(String displayName) {
        this.displayName = displayName;
    }

    /**
     * Obtiene el nombre legible del estado.
     * @return Cadena de texto (ej: "En revisión").
     */
    public String getDisplayName() {
        return displayName;
    }
}
