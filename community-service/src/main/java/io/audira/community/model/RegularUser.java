package io.audira.community.model;

import jakarta.persistence.DiscriminatorValue;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import lombok.experimental.SuperBuilder;

/**
 * Entidad que representa a un **Usuario Regular** dentro de la plataforma.
 * <p>
 * Hereda de la clase base {@code User} y es el tipo de cuenta estándar. Añade atributos
 * específicos para un usuario consumidor, como su género musical favorito.
 * Se utiliza en el contexto de la estrategia de herencia Single Table con la columna
 * discriminadora 'REGULAR'.
 * </p>
 *
 * @author Grupo GA01
 * @see User
 * 
 */
@Entity
@Table(name = "regular_users")
@DiscriminatorValue("REGULAR")
@Data
@EqualsAndHashCode(callSuper = true)
@SuperBuilder
@NoArgsConstructor
@AllArgsConstructor
public class RegularUser extends User {

    /**
     * Género musical favorito declarado por el usuario.
     * <p>
     * Este campo puede usarse para personalizar recomendaciones o contenido.
     * </p>
     */
    private String favoriteGenre;

    /**
     * Proporciona el tipo de usuario específico de esta entidad.
     *
     * @return La cadena "REGULAR".
     */
    @Override
    public String getUserType() {
        return "REGULAR";
    }
}