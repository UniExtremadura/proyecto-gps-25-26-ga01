package io.audira.community.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import lombok.experimental.SuperBuilder;
import lombok.Builder;

/**
 * Entidad de base de datos que representa a un usuario con rol de Administrador (ADMIN).
 * <p>
 * Esta clase extiende la entidad base {@link User} y añade campos específicos de administración,
 * como el nivel de privilegio ({@link AdminLevel}) y el departamento.
 * Utiliza {@code @DiscriminatorValue("ADMIN")} para el mapeo por herencia de tabla única o de tipo.
 * </p>
 *
 * @author Grupo GA01
 * @see User
 * @see Entity
 * 
 */
@Entity
@Table(name = "admins") // Aunque se mapee en una tabla base, esta es la entidad conceptual
@DiscriminatorValue("ADMIN")
@Data
@EqualsAndHashCode(callSuper = true) // Incluye los campos de la clase padre (User) en la lógica de igualdad/hash
@SuperBuilder // Permite la construcción del objeto con campos propios y de la clase padre
@NoArgsConstructor
@AllArgsConstructor
public class Admin extends User {

    /**
     * Nivel de privilegios del administrador.
     * <p>
     * Mapeado como String en la base de datos ({@code @Enumerated(EnumType.STRING)}).
     * El valor por defecto es {@code MODERATOR}.
     * </p>
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "admin_level")
    @Builder.Default
    private AdminLevel adminLevel = AdminLevel.MODERATOR;

    /**
     * Departamento o área funcional a la que pertenece el administrador.
     */
    @Column(name = "department")
    private String department;

    /**
     * Sobrescribe el método de la clase padre para retornar explícitamente el tipo de usuario como "ADMIN".
     *
     * @return La cadena "ADMIN".
     */
    @Override
    public String getUserType() {
        return "ADMIN";
    }

    /**
     * Enumerador que define los posibles niveles de privilegios para un administrador.
     */
    public enum AdminLevel {
        /**
         * Nivel de privilegio base, típicamente para tareas de moderación de contenido.
         */
        MODERATOR,
        
        /**
         * Nivel de administrador estándar con permisos amplios.
         */
        ADMIN,
        
        /**
         * Nivel de administrador con acceso completo y privilegios de alto riesgo.
         */
        SUPER_ADMIN
    }
}