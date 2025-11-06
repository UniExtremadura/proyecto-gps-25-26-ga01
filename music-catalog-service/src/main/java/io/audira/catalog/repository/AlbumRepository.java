package io.audira.catalog.repository;

import io.audira.catalog.model.Album;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface AlbumRepository extends JpaRepository<Album, Long>{
    @Query("SELECT a FROM Album a ORDER BY a.createdAt DESC")
    List<Album> findRecentAlbums();
}
