package io.audira.catalog.controller;

import io.audira.catalog.dto.SongDTO;
import io.audira.catalog.model.Song;
import io.audira.catalog.service.SongService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/songs")
@RequiredArgsConstructor
@Slf4j
public class SongController {

    private final SongService songService;

    @PostMapping
    public ResponseEntity<?> createSong(@RequestBody Song song) {
        try {
            Song createdSong = songService.createSong(song);
            return ResponseEntity.status(HttpStatus.CREATED).body(createdSong);
        } catch (IllegalArgumentException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @GetMapping
    public ResponseEntity<List<SongDTO>> getAllSongs() {
        return ResponseEntity.ok(songService.getAllSongsWithArtistName());
    }
 
    @GetMapping("/{id}")
    public ResponseEntity<?> getSongById(@PathVariable Long id) {
        try {
            return ResponseEntity.ok(songService.getSongByIdWithArtistName(id));
        } catch (IllegalArgumentException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }
 
    @GetMapping("/artist/{artistId}")
    public ResponseEntity<List<SongDTO>> getSongsByArtist(@PathVariable Long artistId) {
        return ResponseEntity.ok(songService.getSongsByArtistWithArtistName(artistId));
    }
 
    @GetMapping("/album/{albumId}")
    public ResponseEntity<List<SongDTO>> getSongsByAlbum(@PathVariable Long albumId) {
        return ResponseEntity.ok(songService.getSongsByAlbumWithArtistName(albumId));
    }
 
    @GetMapping("/genre/{genreId}")
    public ResponseEntity<List<SongDTO>> getSongsByGenre(@PathVariable Long genreId) {
        return ResponseEntity.ok(songService.getSongsByGenreWithArtistName(genreId));
    }
 
    @GetMapping("/recent")
    public ResponseEntity<List<SongDTO>> getRecentSongs() {
        return ResponseEntity.ok(songService.getRecentSongsWithArtistName());
    }
 
    @GetMapping("/top")
    public ResponseEntity<List<SongDTO>> getTopSongs() {
        return ResponseEntity.ok(songService.getTopSongsByPlaysWithArtistName());
    }
 
    @GetMapping("/search")
    public ResponseEntity<List<SongDTO>> searchSongs(@RequestParam String query) {
        return ResponseEntity.ok(songService.searchSongsWithArtistName(query));
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateSong(@PathVariable Long id, @RequestBody Song song) {
        try {
            return ResponseEntity.ok(songService.updateSong(id, song));
        } catch (IllegalArgumentException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteSong(@PathVariable Long id) {
        try {
            songService.deleteSong(id);
            return ResponseEntity.noContent().build();
        } catch (IllegalArgumentException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }

    @PostMapping("/{id}/play")
    public ResponseEntity<Song> incrementPlays(@PathVariable Long id) {
        try {
            log.info("📊 Incrementing play count for song ID: {}", id);
            Song updatedSong = songService.incrementPlays(id);
            log.info("✅ Play count incremented successfully - Song: '{}', New count: {}",
                    updatedSong.getTitle(), updatedSong.getPlays());
            return ResponseEntity.ok(updatedSong);
        } catch (IllegalArgumentException e) {
            log.warn("❌ Failed to increment play count for song ID {}: {}", id, e.getMessage());
            return ResponseEntity.notFound().build();
        }
    }

    @PatchMapping("/{id}/publish")
    public ResponseEntity<Song> publishSong(@PathVariable Long id, @RequestParam boolean published) {
        try {
            return ResponseEntity.ok(songService.publishSong(id, published));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        }
    }

    // Endpoints públicos que solo retornan contenido publicado
    @GetMapping("/public/recent")
    public ResponseEntity<List<SongDTO>> getRecentPublishedSongs() {
        return ResponseEntity.ok(songService.getRecentPublishedSongsWithArtistName());
    }
 
    @GetMapping("/public/top")
    public ResponseEntity<List<SongDTO>> getTopPublishedSongs() {
        return ResponseEntity.ok(songService.getTopPublishedSongsByPlaysWithArtistName());
    }
 
    @GetMapping("/public/search")
    public ResponseEntity<List<SongDTO>> searchPublishedSongs(@RequestParam String query) {
        return ResponseEntity.ok(songService.searchPublishedSongsWithArtistName(query));
    }
 
    @GetMapping("/public/genre/{genreId}")
    public ResponseEntity<List<SongDTO>> getPublishedSongsByGenre(@PathVariable Long genreId) {
        return ResponseEntity.ok(songService.getPublishedSongsByGenreWithArtistName(genreId));
    }
}
