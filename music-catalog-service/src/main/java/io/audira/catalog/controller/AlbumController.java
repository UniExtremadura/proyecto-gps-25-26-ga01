package io.audira.catalog.controller;

import io.audira.catalog.model.Album;
import io.audira.catalog.service.AlbumService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/albums")
@RequiredArgsConstructor
public class AlbumController {
    
    private final AlbumService albumService;

    @GetMapping("/latest-releases")
    public ResponseEntity<List<Album>> getLatestReleases(@RequestParam(defaultValue = "20") int limit) {
        List<Album> albums = albumService.getRecentAlbums();
        return ResponseEntity.ok(albums.stream().limit(limit).toList());
    }
}
