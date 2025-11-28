package io.audira.commerce.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

/**
 * Data Transfer Object (DTO) que representa la colección completa de artículos favoritos de un usuario, organizados por categoría.
 * <p>
 * Este objeto se utiliza para transferir la lista de deseos consolidada de un usuario a la capa de presentación (API),
 * facilitando la visualización categorizada en el frontend.
 * </p>
 *
 * @author Grupo GA01
 * @see FavoriteDTO
 * 
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserFavoritesDTO {

    /**
     * ID del usuario al que pertenece esta colección de favoritos.
     */
    private Long userId;

    /**
     * Lista de favoritos de tipo Canción (Song).
     * <p>
     * Inicializada a una lista vacía por defecto ({@code @Builder.Default}).
     * </p>
     */
    @Builder.Default
    private List<FavoriteDTO> songs = new ArrayList<>();

    /**
     * Lista de favoritos de tipo Álbum (Album).
     * <p>
     * Inicializada a una lista vacía por defecto ({@code @Builder.Default}).
     * </p>
     */
    @Builder.Default
    private List<FavoriteDTO> albums = new ArrayList<>();

    /**
     * Lista de favoritos de tipo Mercancía (Merchandise).
     * <p>
     * Inicializada a una lista vacía por defecto ({@code @Builder.Default}).
     * </p>
     */
    @Builder.Default
    private List<FavoriteDTO> merchandise = new ArrayList<>();

    /**
     * Constructor manual que inicializa el objeto con el ID de usuario y listas vacías.
     * <p>
     * Útil cuando se crea el objeto sin usar el constructor {@code @Builder} de Lombok.
     * </p>
     *
     * @param userId El ID del usuario.
     */
    public UserFavoritesDTO(Long userId) {
        this.userId = userId;
        this.songs = new ArrayList<>();
        this.albums = new ArrayList<>();
        this.merchandise = new ArrayList<>();
    }

    /**
     * Agrega un objeto {@link FavoriteDTO} a la lista de canciones.
     *
     * @param favorite El objeto favorito de tipo Canción a añadir.
     */
    public void addSong(FavoriteDTO favorite) {
        this.songs.add(favorite);
    }

    /**
     * Agrega un objeto {@link FavoriteDTO} a la lista de álbumes.
     *
     * @param favorite El objeto favorito de tipo Álbum a añadir.
     */
    public void addAlbum(FavoriteDTO favorite) {
        this.albums.add(favorite);
    }

    /**
     * Agrega un objeto {@link FavoriteDTO} a la lista de mercancía.
     *
     * @param favorite El objeto favorito de tipo Mercancía a añadir.
     */
    public void addMerchandise(FavoriteDTO favorite) {
        this.merchandise.add(favorite);
    }

    /**
     * Calcula la suma total de todos los artículos favoritos en todas las categorías.
     *
     * @return El número total de favoritos del usuario.
     */
    public int getTotalFavorites() {
        return songs.size() + albums.size() + merchandise.size();
    }
}