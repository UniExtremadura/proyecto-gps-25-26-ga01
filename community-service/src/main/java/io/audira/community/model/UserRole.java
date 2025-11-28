package io.audira.community.model;

/**
 * Enumeración que define los diferentes roles de usuario disponibles en el sistema.
 * <p>
 * Se utiliza para la gestión de permisos y la diferenciación de tipos de cuentas
 * dentro de la plataforma (ej. un usuario regular, un artista registrado o un administrador).
 * </p>
 *
 * @author Grupo GA01
 * 
 */
public enum UserRole {
    /**
     * Rol para un usuario estándar o regular, que consume contenido.
     */
    USER,

    /**
     * Rol para una cuenta de artista verificada, que produce contenido.
     */
    ARTIST,

    /**
     * Rol para un usuario con privilegios administrativos, encargado de la gestión
     * interna de la plataforma.
     */
    ADMIN
}