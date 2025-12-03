package io.audira.community.model;

import jakarta.persistence.Column;
import jakarta.persistence.DiscriminatorValue;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import lombok.experimental.SuperBuilder;

/**
 * Entidad que representa a un **Artista** dentro de la plataforma.
 * <p>
 * Hereda de la clase base {@code User} y añade atributos específicos
 * para un perfil de artista, como el nombre artístico, la biografía
 * y el sello discográfico. Se utiliza en el contexto de la estrategia
 * de herencia Single Table con la columna discriminadora 'ARTIST'.
 * </p>
 *
 * @author Grupo GA01
 * @see User
 * 
 */
@Entity
@Table(name = "artists")
@DiscriminatorValue("ARTIST")
@Data
@EqualsAndHashCode(callSuper = true)
@SuperBuilder
@NoArgsConstructor
@AllArgsConstructor
public class Artist extends User {

    /**
     * Nombre artístico o nombre de la banda.
     * <p>
     * Este es el nombre público utilizado en el escenario y en la plataforma.
     * </p>
     */
    @Column(name = "artist_name")
    private String artistName; // Stage name

    /**
     * Indicador de si el perfil del artista ha sido verificado.
     * <p>
     * Un valor de {@code true} indica que el artista ha pasado por el proceso
     * de verificación de la plataforma.
     * </p>
     */
    @Column(name = "verified_artist")
    private Boolean verifiedArtist;

    /**
     * Biografía del artista o de la banda.
     * <p>
     * Se almacena como texto largo (TEXT) para permitir descripciones detalladas.
     * </p>
     */
    @Column(columnDefinition = "TEXT")
    private String artistBio;

    /**
     * Sello discográfico o disquera a la que pertenece el artista (opcional).
     */
    private String recordLabel;

    /**
     * Proporciona el tipo de usuario específico de esta entidad.
     *
     * @return La cadena "ARTIST".
     */
    @Override
    public String getUserType() {
        return "ARTIST";
    }
}