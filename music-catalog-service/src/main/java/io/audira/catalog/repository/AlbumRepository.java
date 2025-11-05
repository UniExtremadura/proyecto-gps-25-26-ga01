package io.audira.catalog.repository;

import io.audira.catalog.model.Album;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public class AlbumRepository {
    @Query("SELECT a FROM Album a ORDER BY a.createdAt DESC")
    List<Album> findRecentAlbums();
}
