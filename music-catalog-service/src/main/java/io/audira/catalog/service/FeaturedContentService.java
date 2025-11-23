package io.audira.catalog.service;

import io.audira.catalog.client.UserServiceClient;
import io.audira.catalog.dto.FeaturedContentRequest;
import io.audira.catalog.dto.FeaturedContentResponse;
import io.audira.catalog.dto.ReorderRequest;
import io.audira.catalog.dto.UserDTO;
import io.audira.catalog.model.Album;
import io.audira.catalog.model.FeaturedContent;
import io.audira.catalog.model.FeaturedContent.ContentType;
import io.audira.catalog.model.Song;
import io.audira.catalog.repository.AlbumRepository;
import io.audira.catalog.repository.FeaturedContentRepository;
import io.audira.catalog.repository.SongRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Service for managing featured content
 * GA01-156: Seleccionar/ordenar contenido destacado
 * GA01-157: Programación de destacados
 */
@Service
@RequiredArgsConstructor
public class FeaturedContentService {

    private final FeaturedContentRepository featuredContentRepository;
    private final SongRepository songRepository;
    private final AlbumRepository albumRepository;
    private final UserServiceClient userServiceClient;

    /**
     * Get all featured content (admin)
     * GA01-156
     */
    public List<FeaturedContentResponse> getAllFeaturedContent() {
        return featuredContentRepository.findAllByOrderByDisplayOrderAsc()
                .stream()
                .map(FeaturedContentResponse::fromEntity)
                .collect(Collectors.toList());
    }

    /**
     * Get active scheduled featured content (public)
     * GA01-157
     */
    public List<FeaturedContentResponse> getActiveFeaturedContent() {
        return featuredContentRepository.findActiveScheduledContent(LocalDateTime.now())
                .stream()
                .map(FeaturedContentResponse::fromEntity)
                .collect(Collectors.toList());
    }

    /**
     * Get featured content by ID
     * GA01-156
     */
    public FeaturedContentResponse getFeaturedContentById(Long id) {
        FeaturedContent entity = featuredContentRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Featured content not found with id: " + id));
        return FeaturedContentResponse.fromEntity(entity);
    }

    /**
     * Create new featured content
     * GA01-156, GA01-157
     */
    @Transactional
    public FeaturedContentResponse createFeaturedContent(FeaturedContentRequest request) {
        // Validate content type and ID
        if (request.getContentType() == null) {
            throw new IllegalArgumentException("Content type is required");
        }
        if (request.getContentId() == null) {
            throw new IllegalArgumentException("Content ID is required");
        }

        // Check if content already exists as featured
        if (featuredContentRepository.existsByContentTypeAndContentId(
                request.getContentType(), request.getContentId())) {
            throw new IllegalArgumentException("This content is already featured");
        }

        // Verify the content exists and is published
        String title = null;
        String imageUrl = null;
        String artist = null;

        if (request.getContentType() == ContentType.SONG) {
            Song song = songRepository.findById(request.getContentId())
                    .orElseThrow(() -> new IllegalArgumentException("Song not found with id: " + request.getContentId()));

            if (!song.isPublished()) {
                throw new IllegalArgumentException("Cannot feature unpublished song");
            }

            title = song.getTitle();
            imageUrl = song.getCoverImageUrl();

            // Fetch artist name from User service
            UserDTO artistUser = userServiceClient.getUserById(song.getArtistId());
            artist = artistUser.getArtistName() != null ? artistUser.getArtistName() : artistUser.getUsername();
        } else if (request.getContentType() == ContentType.ALBUM) {
            Album album = albumRepository.findById(request.getContentId())
                    .orElseThrow(() -> new IllegalArgumentException("Album not found with id: " + request.getContentId()));

            if (!album.isPublished()) {
                throw new IllegalArgumentException("Cannot feature unpublished album");
            }

            title = album.getTitle();
            imageUrl = album.getCoverImageUrl();

            // Fetch artist name from User service
            UserDTO artistUser = userServiceClient.getUserById(album.getArtistId());
            artist = artistUser.getArtistName() != null ? artistUser.getArtistName() : artistUser.getUsername();
        }

        // Set display order if not provided
        Integer displayOrder = request.getDisplayOrder();
        if (displayOrder == null || displayOrder > 900) {
            Integer maxOrder = featuredContentRepository.findMaxDisplayOrder();
            displayOrder = (maxOrder != null ? maxOrder + 1 : 0);
        }

        // Create entity
        FeaturedContent entity = FeaturedContent.builder()
                .contentType(request.getContentType())
                .contentId(request.getContentId())
                .displayOrder(displayOrder)
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .isActive(request.getIsActive() != null ? request.getIsActive() : true)
                .contentTitle(title)
                .contentImageUrl(imageUrl)
                .contentArtist(artist)
                .build();

        FeaturedContent saved = featuredContentRepository.save(entity);
        return FeaturedContentResponse.fromEntity(saved);
    }

    /**
     * Update featured content
     * GA01-156, GA01-157
     */
    @Transactional
    public FeaturedContentResponse updateFeaturedContent(Long id, FeaturedContentRequest request) {
        FeaturedContent entity = featuredContentRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Featured content not found with id: " + id));

        // Update fields if provided
        if (request.getStartDate() != null) {
            entity.setStartDate(request.getStartDate());
        }
        if (request.getEndDate() != null) {
            entity.setEndDate(request.getEndDate());
        }
        if (request.getIsActive() != null) {
            entity.setIsActive(request.getIsActive());
        }
        if (request.getDisplayOrder() != null) {
            entity.setDisplayOrder(request.getDisplayOrder());
        }

        FeaturedContent saved = featuredContentRepository.save(entity);
        return FeaturedContentResponse.fromEntity(saved);
    }

    /**
     * Delete featured content
     * GA01-156
     */
    @Transactional
    public void deleteFeaturedContent(Long id) {
        if (!featuredContentRepository.existsById(id)) {
            throw new IllegalArgumentException("Featured content not found with id: " + id);
        }
        featuredContentRepository.deleteById(id);
    }

    /**
     * Reorder featured content
     * GA01-156
     */
    @Transactional
    public List<FeaturedContentResponse> reorderFeaturedContent(ReorderRequest request) {
        if (request.getItems() == null || request.getItems().isEmpty()) {
            throw new IllegalArgumentException("Items list is required for reordering");
        }

        // Update display order for each item
        for (ReorderRequest.ReorderItem item : request.getItems()) {
            FeaturedContent entity = featuredContentRepository.findById(item.getId())
                    .orElseThrow(() -> new IllegalArgumentException("Featured content not found with id: " + item.getId()));
            entity.setDisplayOrder(item.getDisplayOrder());
            featuredContentRepository.save(entity);
        }

        // Return all items in new order
        return getAllFeaturedContent();
    }

    /**
     * Toggle active status
     * GA01-156
     */
    @Transactional
    public FeaturedContentResponse toggleActive(Long id, boolean isActive) {
        FeaturedContent entity = featuredContentRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Featured content not found with id: " + id));

        entity.setIsActive(isActive);
        FeaturedContent saved = featuredContentRepository.save(entity);
        return FeaturedContentResponse.fromEntity(saved);
    }
}
