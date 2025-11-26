package io.audira.catalog.service;

import io.audira.catalog.client.UserServiceClient;
import io.audira.catalog.dto.AlbumCreateRequest;
import io.audira.catalog.dto.AlbumDTO;
import io.audira.catalog.dto.AlbumResponse;
import io.audira.catalog.dto.AlbumUpdateRequest;
import io.audira.catalog.model.Album;
import io.audira.catalog.model.ModerationStatus;
import io.audira.catalog.model.Song;
import io.audira.catalog.repository.AlbumRepository;
import io.audira.catalog.repository.SongRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class AlbumService {

    private final AlbumRepository albumRepository;
    private final SongRepository songRepository;
    private final UserServiceClient userServiceClient;

    public List<Album> getRecentAlbums() {
        return albumRepository.findRecentAlbums();
    }

    public Optional<Album> getAlbumById(Long id) {
        return albumRepository.findById(id);
    }

    public List<Album> getAllAlbums() {
        return albumRepository.findAll();
    }

    public List<Album> getAlbumsByArtist(Long artistId) {
        return albumRepository.findByArtistId(artistId);
    }

    /**
     * Get albums by artist with artist name included in DTO
     */
    public List<AlbumDTO> getAlbumsByArtistWithArtistName(Long artistId) {
        List<Album> albums = albumRepository.findByArtistId(artistId);

        // Get artist name once
        String artistName;
        try {
            artistName = userServiceClient.getUserById(artistId).getArtistName();
        } catch (Exception e) {
            log.warn("Failed to fetch artist name for artistId: {}, using fallback", artistId);
            artistName = "Artist #" + artistId;
        }

        // Convert all albums to DTOs with the artist name
        final String finalArtistName = artistName;
        return albums.stream()
                .map(album -> AlbumDTO.fromAlbum(album, finalArtistName))
                .collect(Collectors.toList());
    }

    @Transactional
    public AlbumResponse createAlbum(AlbumCreateRequest request) {
        // Calcular precio basado en las canciones del álbum
        BigDecimal totalSongPrice = BigDecimal.ZERO;

        if (request.getSongIds() != null && !request.getSongIds().isEmpty()) {
            for (Long songId : request.getSongIds()) {
                Optional<Song> songOpt = songRepository.findById(songId);
                if (songOpt.isPresent() && songOpt.get().getPrice() != null) {
                    totalSongPrice = totalSongPrice.add(songOpt.get().getPrice());
                }
            }
        }

        // Aplicar descuento al precio total de canciones
        double discountPercentage = request.getDiscountPercentage() != null ?
                request.getDiscountPercentage() : 0.15;

        BigDecimal finalPrice = totalSongPrice;
        if (discountPercentage > 0 && totalSongPrice.compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal discount = totalSongPrice.multiply(BigDecimal.valueOf(discountPercentage));
            finalPrice = totalSongPrice.subtract(discount);
        }

        // Si no se pudo calcular precio de canciones, usar el precio proporcionado
        if (finalPrice.compareTo(BigDecimal.ZERO) == 0 && request.getPrice() != null) {
            finalPrice = request.getPrice();
        }

        log.info("Album price calculation: totalSongPrice={}, discount={}%, finalPrice={}",
                totalSongPrice, discountPercentage * 100, finalPrice);

        // Crear el álbum
        Album album = Album.builder()
                .title(request.getTitle())
                .artistId(request.getArtistId())
                .description(request.getDescription())
                .price(finalPrice)
                .coverImageUrl(request.getCoverImageUrl())
                .genreIds(request.getGenreIds())
                .releaseDate(request.getReleaseDate())
                .discountPercentage(discountPercentage)
                .published(false) // Por defecto no publicado
                .moderationStatus(ModerationStatus.PENDING) // GA01-162: Estado inicial
                .build();

        album = albumRepository.save(album);

        // Asociar canciones al álbum
        if (request.getSongIds() != null && !request.getSongIds().isEmpty()) {
            int trackNumber = 1;
            for (Long songId : request.getSongIds()) {
                Optional<Song> songOpt = songRepository.findById(songId);
                if (songOpt.isPresent()) {
                    Song song = songOpt.get();
                    song.setAlbumId(album.getId());
                    song.setTrackNumber(trackNumber++);
                    song.setCategory("Album");
                    songRepository.save(song);
                }
            }
        }

        int songCount = songRepository.findByAlbumId(album.getId()).size();
        return AlbumResponse.fromAlbum(album, songCount);
    }

    /**
     * GA01-162: Al actualizar un álbum, vuelve a estado PENDING
     */
    @Transactional
    public Optional<AlbumResponse> updateAlbum(Long id, AlbumUpdateRequest request) {
        Optional<Album> albumOpt = albumRepository.findById(id);
        if (albumOpt.isEmpty()) {
            return Optional.empty();
        }

        Album album = albumOpt.get();
        if (request.getTitle() != null) album.setTitle(request.getTitle());
        if (request.getDescription() != null) album.setDescription(request.getDescription());
        if (request.getPrice() != null) album.setPrice(request.getPrice());
        if (request.getCoverImageUrl() != null) album.setCoverImageUrl(request.getCoverImageUrl());
        if (request.getGenreIds() != null) album.setGenreIds(request.getGenreIds());
        if (request.getReleaseDate() != null) album.setReleaseDate(request.getReleaseDate());
        if (request.getDiscountPercentage() != null)
            album.setDiscountPercentage(request.getDiscountPercentage());

        // GA01-162: Cualquier modificación requiere nueva moderación
        album.setModerationStatus(ModerationStatus.PENDING);
        album.setModeratedBy(null);
        album.setModeratedAt(null);
        album.setRejectionReason(null);
        album.setPublished(false); // Ocultar hasta nueva aprobación

        album = albumRepository.save(album);
        int songCount = songRepository.findByAlbumId(album.getId()).size();
        return Optional.of(AlbumResponse.fromAlbum(album, songCount));
    }

    /**
     * GA01-162: Publicar o ocultar un álbum
     * Solo se puede publicar si está aprobado
     */
    @Transactional
    public Optional<AlbumResponse> publishAlbum(Long id, boolean published) {
        Optional<Album> albumOpt = albumRepository.findById(id);
        if (albumOpt.isEmpty()) {
            return Optional.empty();
        }

        Album album = albumOpt.get();

        // GA01-162: Solo se puede publicar si está aprobado
        if (published && album.getModerationStatus() != ModerationStatus.APPROVED) {
            throw new IllegalArgumentException(
                "No se puede publicar un álbum que no está aprobado. Estado actual: " +
                album.getModerationStatus().getDisplayName());
        }

        album.setPublished(published);
        album = albumRepository.save(album);

        int songCount = songRepository.findByAlbumId(album.getId()).size();
        return Optional.of(AlbumResponse.fromAlbum(album, songCount));
    }

    @Transactional
    public boolean deleteAlbum(Long id) {
        Optional<Album> albumOpt = albumRepository.findById(id);
        if (albumOpt.isEmpty()) {
            return false;
        }

        // Desasociar canciones del álbum
        List<Song> songs = songRepository.findByAlbumId(id);
        for (Song song : songs) {
            song.setAlbumId(null);
            song.setTrackNumber(null);
            song.setCategory("Single");
            songRepository.save(song);
        }

        albumRepository.deleteById(id);
        return true;
    }

    public AlbumResponse getAlbumResponseById(Long id) {
        Optional<Album> albumOpt = albumRepository.findById(id);
        if (albumOpt.isEmpty()) {
            return null;
        }

        Album album = albumOpt.get();
        int songCount = songRepository.findByAlbumId(id).size();
        return AlbumResponse.fromAlbum(album, songCount);
    }

    // Métodos públicos que solo retornan contenido publicado
    public List<Album> getRecentPublishedAlbums() {
        return albumRepository.findTop20ByPublishedTrueOrderByCreatedAtDesc();
    }
}