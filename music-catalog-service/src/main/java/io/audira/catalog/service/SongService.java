package io.audira.catalog.service;

import io.audira.catalog.client.UserServiceClient;
import io.audira.catalog.dto.SongDTO;
import io.audira.catalog.model.ModerationStatus;
import io.audira.catalog.model.Song;
import io.audira.catalog.repository.SongRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class SongService {

    private final SongRepository songRepository;
    private final UserServiceClient userServiceClient;

    @Transactional
    public Song createSong(Song song) {
        // Validate required fields
        if (song.getTitle() == null || song.getTitle().trim().isEmpty()) {
            throw new IllegalArgumentException("Song title is required");
        }
        if (song.getArtistId() == null) {
            throw new IllegalArgumentException("Artist ID is required");
        }
        if (song.getDuration() == null || song.getDuration() <= 0) {
            throw new IllegalArgumentException("Valid duration is required");
        }
        if (song.getGenreIds() == null || song.getGenreIds().isEmpty()) {
            throw new IllegalArgumentException("At least one genre is required");
        }

        // GA01-162: Forzar estado inicial de moderación
        // Todas las canciones nuevas deben estar en PENDING y ocultas
        song.setModerationStatus(ModerationStatus.PENDING);
        song.setPublished(false);
        song.setModeratedBy(null);
        song.setModeratedAt(null);
        song.setRejectionReason(null);

        return songRepository.save(song);
    }

    public List<Song> getAllSongs() {
        return songRepository.findAll();
    }

    public Song getSongById(Long id) {
        return songRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Song not found with id: " + id));
    }

    public List<Song> getSongsByArtist(Long artistId) {
        return songRepository.findByArtistId(artistId);
    }

    /**
     * Get songs by artist with artist name included in DTO
     */
    public List<SongDTO> getSongsByArtistWithArtistName(Long artistId) {
        List<Song> songs = songRepository.findByArtistId(artistId);

        // Get artist name once
        String artistName;
        try {
            artistName = userServiceClient.getUserById(artistId).getArtistName();
        } catch (Exception e) {
            log.warn("Failed to fetch artist name for artistId: {}, using fallback", artistId);
            artistName = "Artist #" + artistId;
        }

        // Convert all songs to DTOs with the artist name
        final String finalArtistName = artistName;
        return songs.stream()
                .map(song -> SongDTO.fromSong(song, finalArtistName))
                .collect(Collectors.toList());
    }

    public List<Song> getSongsByAlbum(Long albumId) {
        return songRepository.findByAlbumId(albumId);
    }

    public List<Song> getSongsByGenre(Long genreId) {
        return songRepository.findByGenreId(genreId);
    }

    public List<Song> getRecentSongs() {
        return songRepository.findTop20ByOrderByCreatedAtDesc();
    }

    public List<Song> getTopSongsByPlays() {
        return songRepository.findTopByPlays();
    }

    public List<Song> searchSongs(String query) {
        return songRepository.searchByTitleOrArtist(query);
    }

    /**
     * GA01-162: Al actualizar una canción, vuelve a estado PENDING
     */
    @Transactional
    public Song updateSong(Long id, Song songDetails) {
        Song song = songRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Song not found with id: " + id));

        if (songDetails.getTitle() != null) {
            song.setTitle(songDetails.getTitle());
        }
        if (songDetails.getDescription() != null) {
            song.setDescription(songDetails.getDescription());
        }
        if (songDetails.getPrice() != null) {
            song.setPrice(songDetails.getPrice());
        }
        if (songDetails.getCoverImageUrl() != null) {
            song.setCoverImageUrl(songDetails.getCoverImageUrl());
        }
        if (songDetails.getAudioUrl() != null) {
            song.setAudioUrl(songDetails.getAudioUrl());
        }
        if (songDetails.getLyrics() != null) {
            song.setLyrics(songDetails.getLyrics());
        }
        if (songDetails.getDuration() != null) {
            song.setDuration(songDetails.getDuration());
        }
        if (songDetails.getGenreIds() != null && !songDetails.getGenreIds().isEmpty()) {
            song.setGenreIds(songDetails.getGenreIds());
        }
        if (songDetails.getCategory() != null) {
            song.setCategory(songDetails.getCategory());
        }
        if (songDetails.getAlbumId() != null) {
            song.setAlbumId(songDetails.getAlbumId());
        }
        if (songDetails.getTrackNumber() != null) {
            song.setTrackNumber(songDetails.getTrackNumber());
        }

        // GA01-162: Cualquier modificación requiere nueva moderación
        song.setModerationStatus(ModerationStatus.PENDING);
        song.setModeratedBy(null);
        song.setModeratedAt(null);
        song.setRejectionReason(null);
        song.setPublished(false); // Ocultar hasta nueva aprobación

        return songRepository.save(song);
    }

    @Transactional
    public void deleteSong(Long id) {
        if (!songRepository.existsById(id)) {
            throw new IllegalArgumentException("Song not found with id: " + id);
        }
        songRepository.deleteById(id);
    }

    @Transactional
    public Song incrementPlays(Long id) {
        Song song = getSongById(id);
        song.setPlays(song.getPlays() + 1);
        return songRepository.save(song);
    }

    /**
     * GA01-152 + GA01-162: Publicar o ocultar una canción
     * Solo se puede publicar si está aprobada
     */
    @Transactional
    public Song publishSong(Long id, boolean published) {
        Song song = songRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Song not found with id: " + id));

        // GA01-162: Solo se puede publicar si está aprobada
        if (published && song.getModerationStatus() != ModerationStatus.APPROVED) {
            throw new IllegalArgumentException(
                "No se puede publicar una canción que no está aprobada. Estado actual: " +
                song.getModerationStatus().getDisplayName());
        }

        song.setPublished(published);
        return songRepository.save(song);
    }

    // Métodos públicos que solo retornan contenido publicado
    public List<Song> getRecentPublishedSongs() {
        return songRepository.findTop20ByPublishedTrueOrderByCreatedAtDesc();
    }

    public List<Song> getTopPublishedSongsByPlays() {
        return songRepository.findTopPublishedByPlays();
    }
    
    public List<Song> searchPublishedSongs(String query) {
        return songRepository.searchPublishedByTitleOrArtist(query);
    }

    public List<Song> getPublishedSongsByGenre(Long genreId) {
       return songRepository.findPublishedByGenreId(genreId);
    }
     
    /**
     * Helper method to convert a Song to SongDTO with artist name
     */
    private SongDTO convertToDTO(Song song) {
        try {
            String fetchedName = userServiceClient.getUserById(song.getArtistId()).getArtistName();
            
            song.setArtistName(fetchedName);
            
        } catch (Exception e) {
            log.warn("Failed to fetch artist name for artistId: {}, using fallback", song.getArtistId());
            song.setArtistName("Artista #" + song.getArtistId());
        }

        if (song.getArtistName() == null || song.getArtistName().trim().isEmpty()) {
            song.setArtistName("Artista #" + song.getArtistId());
        }

        return SongDTO.fromSong(song, song.getArtistName());
    }
 
    /**
     * Helper method to convert a list of Songs to SongDTOs with artist names
     */
    private List<SongDTO> convertToDTOs(List<Song> songs) {
        return songs.stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }
 
    // DTO versions of methods - these include artist names
    public List<SongDTO> getAllSongsWithArtistName() {
        return convertToDTOs(songRepository.findAll());
    }
 
    public SongDTO getSongByIdWithArtistName(Long id) {
        Song song = songRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Song not found with id: " + id));
        return convertToDTO(song);
    }
 
    public List<SongDTO> getSongsByAlbumWithArtistName(Long albumId) {
        return convertToDTOs(songRepository.findByAlbumId(albumId));
    }
 
    public List<SongDTO> getSongsByGenreWithArtistName(Long genreId) {
        return convertToDTOs(songRepository.findByGenreId(genreId));
    }
 
    public List<SongDTO> getRecentSongsWithArtistName() {
        return convertToDTOs(songRepository.findTop20ByOrderByCreatedAtDesc());
    }
 
    public List<SongDTO> getTopSongsByPlaysWithArtistName() {
        return convertToDTOs(songRepository.findTopByPlays());
    }

    public List<SongDTO> searchSongsWithArtistName(String query) {
        return convertToDTOs(songRepository.searchByTitleOrArtist(query));
    }

    public List<SongDTO> getRecentPublishedSongsWithArtistName() {
        return convertToDTOs(songRepository.findTop20ByPublishedTrueOrderByCreatedAtDesc());
    }
    public List<SongDTO> getTopPublishedSongsByPlaysWithArtistName() {
        return convertToDTOs(songRepository.findTopPublishedByPlays());
    }

    public List<SongDTO> searchPublishedSongsWithArtistName(String query) {
        return convertToDTOs(songRepository.searchPublishedByTitleOrArtist(query));
    }

    public List<SongDTO> getPublishedSongsByGenreWithArtistName(Long genreId) {
        return convertToDTOs(songRepository.findPublishedByGenreId(genreId));
    }
}
