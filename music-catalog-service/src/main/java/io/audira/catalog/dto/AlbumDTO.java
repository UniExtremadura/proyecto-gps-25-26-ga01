package io.audira.catalog.dto;

import io.audira.catalog.model.Album;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Set;

/**
 * DTO for Album entity with artist name included
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AlbumDTO {
    private Long id;
    private String title;
    private Long artistId;
    private String artistName;
    private BigDecimal price;
    private String coverImageUrl;
    private String description;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private Set<Long> genreIds;
    private LocalDate releaseDate;
    private Double discountPercentage;
    private boolean published;
    private String moderationStatus;
    private String rejectionReason;
    private Long moderatedBy;
    private LocalDateTime moderatedAt;

    /**
     * Create an AlbumDTO from an Album entity and artist name
     */
    public static AlbumDTO fromAlbum(Album album, String artistName) {
        return AlbumDTO.builder()
                .id(album.getId())
                .title(album.getTitle())
                .artistId(album.getArtistId())
                .artistName(artistName)
                .price(album.getPrice())
                .coverImageUrl(album.getCoverImageUrl())
                .description(album.getDescription())
                .createdAt(album.getCreatedAt())
                .updatedAt(album.getUpdatedAt())
                .genreIds(album.getGenreIds())
                .releaseDate(album.getReleaseDate())
                .discountPercentage(album.getDiscountPercentage())
                .published(album.isPublished())
                .moderationStatus(album.getModerationStatus() != null ? album.getModerationStatus().name() : null)
                .rejectionReason(album.getRejectionReason())
                .moderatedBy(album.getModeratedBy())
                .moderatedAt(album.getModeratedAt())
                .build();
    }
}
