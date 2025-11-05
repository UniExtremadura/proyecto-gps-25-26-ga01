package io.audira.catalog.service;

import io.audira.catalog.model.Album;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AlbumService {
    public List<Album> getRecentAlbums() {
        return albumRepository.findRecentAlbums();
    }
}
