package io.audira.commerce.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserFavoritesDTO {

    private Long userId;

    @Builder.Default
    private List<FavoriteDTO> songs = new ArrayList<>();

    @Builder.Default
    private List<FavoriteDTO> albums = new ArrayList<>();

    @Builder.Default
    private List<FavoriteDTO> merchandise = new ArrayList<>();

    public UserFavoritesDTO(Long userId) {
        this.userId = userId;
        this.songs = new ArrayList<>();
        this.albums = new ArrayList<>();
        this.merchandise = new ArrayList<>();
    }

    public void addSong(FavoriteDTO favorite) {
        this.songs.add(favorite);
    }

    public void addAlbum(FavoriteDTO favorite) {
        this.albums.add(favorite);
    }

    public void addMerchandise(FavoriteDTO favorite) {
        this.merchandise.add(favorite);
    }

    public int getTotalFavorites() {
        return songs.size() + albums.size() + merchandise.size();
    }
}
