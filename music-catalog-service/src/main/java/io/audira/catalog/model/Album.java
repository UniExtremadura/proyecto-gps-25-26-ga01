package io.audira.catalog.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import lombok.experimental.SuperBuilder;

import java.time.LocalDate;
import java.util.HashSet;
import java.util.Set;

/**
 * Entidad que representa un Álbum musical.
 * <p>
 * Extiende de la clase base {@code Product} utilizando la estrategia de herencia
 * {@code JOINED} o {@code SINGLE_TABLE} (según configuración de {@code Product}),
 * identificándose con el discriminador "ALBUM".
 * </p>
 */
@Entity
@Table(name = "albums")
@DiscriminatorValue("ALBUM")
@Data
@EqualsAndHashCode(callSuper = true)
@SuperBuilder
@NoArgsConstructor
@AllArgsConstructor
public class Album extends Product {
 
    /**
     * Conjunto de IDs de géneros asociados al álbum.
     * <p>
     * Se almacena en una tabla secundaria {@code album_genres}.
     * Se carga de manera {@code EAGER} (ansiosa) para tener los géneros disponibles inmediatamente.
     * </p>
     */
    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "album_genres", joinColumns = @JoinColumn(name = "album_id"))
    @Column(name = "genre_id")
    @Builder.Default
    private Set<Long> genreIds = new HashSet<>();

    /**
     * Fecha oficial de lanzamiento al mercado.
     */
    @Column(name = "release_date")
    private LocalDate releaseDate;

    /**
     * Porcentaje de descuento aplicado.
     * <p>
     * Marcado como {@code @Transient}, lo que significa que <b>no se guarda en la base de datos</b>.
     * Este valor se calcula en tiempo de ejecución o se establece por defecto (15%) para lógica de negocio
     * temporal. Si se necesita persistir ofertas, este campo debería dejar de ser transitorio.
     * </p>
     */
    @Transient
    @Builder.Default
    private Double discountPercentage = 0.15;

    /**
     * Indica si el álbum es visible para el público general.
     * <p>
     * {@code false} implica que el álbum está en borrador, en moderación o retirado.
     * </p>
     */
    @Column(nullable = false)
    @Builder.Default
    private boolean published = false;

    /**
     * Implementación del método abstracto de la clase padre {@code Product}.
     * <p>Permite identificar el tipo de producto en lógica polimórfica.</p>
     *
     * @return La cadena constante "ALBUM".
     */
    @Override
    public String getProductType() {
        return "ALBUM";
    }
}
