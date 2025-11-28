package io.audira.community.model;

/**
 * Enumerador que define el ciclo de vida y los estados de procesamiento de un mensaje de contacto (ticket de soporte).
 * <p>
 * Estos estados son utilizados por el equipo de administración/soporte para rastrear el progreso de una consulta.
 * </p>
 *
 * @author Grupo GA01
 * 
 */
public enum ContactStatus {
    /**
     * El mensaje o ticket ha sido recibido pero aún no ha sido asignado ni revisado.
     */
    PENDING, 

    /**
     * Un administrador o agente de soporte ha comenzado a trabajar en el mensaje.
     */
    IN_PROGRESS, 

    /**
     * La consulta ha sido respondida y la solución ha sido proporcionada al usuario, pero el ticket aún está visible.
     */
    RESOLVED, 

    /**
     * El ciclo de vida del mensaje ha finalizado (ya sea por resolución, cancelación o por antigüedad).
     */
    CLOSED 
}