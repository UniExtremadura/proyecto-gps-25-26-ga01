package io.audira.commerce.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

/**
 * Data Transfer Object (DTO) que representa la biblioteca completa de artículos comprados de un usuario, organizada por categoría.
 * <p>
 * Este objeto se utiliza para consolidar y transferir la lista de adquisiciones (canciones, álbumes, mercancía)
 * de un usuario a la capa de presentación (API), facilitando su visualización en el frontend.
 * </p>
 *
 * @author Grupo GA01
 * @see PurchasedItemDTO
 * 
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserLibraryDTO {

    /**
     * ID del usuario propietario de la biblioteca.
     */
    private Long userId;

    /**
     * Lista de artículos comprados de tipo Canción. Inicializada a una lista vacía.
     */
    private List<PurchasedItemDTO> songs = new ArrayList<>();

    /**
     * Lista de artículos comprados de tipo Álbum. Inicializada a una lista vacía.
     */
    private List<PurchasedItemDTO> albums = new ArrayList<>();

    /**
     * Lista de artículos comprados de tipo Mercancía. Inicializada a una lista vacía.
     */
    private List<PurchasedItemDTO> merchandise = new ArrayList<>();

    /**
     * Conteo total de artículos únicos en todas las listas de la biblioteca.
     */
    private Integer totalItems;

    /**
     * Constructor manual que inicializa el objeto con el ID de usuario y listas vacías.
     * <p>
     * Asegura que las colecciones no sean nulas al momento de la instanciación.
     * </p>
     *
     * @param userId El ID del usuario.
     */
    public UserLibraryDTO(Long userId) {
        this.userId = userId;
        this.songs = new ArrayList<>();
        this.albums = new ArrayList<>();
        this.merchandise = new ArrayList<>();
        this.totalItems = 0;
    }

    /**
     * Agrega un artículo de tipo Canción a la lista de canciones y actualiza el conteo total.
     *
     * @param song El objeto {@link PurchasedItemDTO} de tipo Canción a añadir.
     */
    public void addSong(PurchasedItemDTO song) {
        this.songs.add(song);
        this.totalItems++;
    }

    /**
     * Agrega un artículo de tipo Álbum a la lista de álbumes y actualiza el conteo total.
     *
     * @param album El objeto {@link PurchasedItemDTO} de tipo Álbum a añadir.
     */
    public void addAlbum(PurchasedItemDTO album) {
        this.albums.add(album);
        this.totalItems++;
    }

    /**
     * Agrega un artículo de tipo Mercancía a la lista de mercancía y actualiza el conteo total.
     *
     * @param item El objeto {@link PurchasedItemDTO} de tipo Mercancía a añadir.
     */
    public void addMerchandise(PurchasedItemDTO item) {
        this.merchandise.add(item);
        this.totalItems++;
    }
}