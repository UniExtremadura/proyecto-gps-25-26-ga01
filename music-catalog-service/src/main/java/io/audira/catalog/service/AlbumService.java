package io.audira.catalog.service;

import io.audira.catalog.model.Album;
import io.audira.catalog.repository.AlbumRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AlbumService {

    private final AlbumRepository albumRepository;
    
    public List<Album> getRecentAlbums() {
        return albumRepository.findRecentAlbums();
    }
}
