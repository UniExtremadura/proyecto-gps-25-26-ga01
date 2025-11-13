package io.audira.catalog.repository;

import io.audira.catalog.model.Album;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface AlbumRepository extends JpaRepository<Album, Long>{
    List<Album> findTop20ByOrderByCreatedAtDesc();
    
    List<Album> findByArtistId(Long artistId);
    
    @Query("SELECT a FROM Album a ORDER BY a.releaseDate DESC")
    List<Album> findRecentAlbums();

}
