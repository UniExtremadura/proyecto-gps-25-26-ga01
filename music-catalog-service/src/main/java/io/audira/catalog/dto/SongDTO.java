package io.audira.catalog.dto;

import io.audira.catalog.model.Song;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Set;

/**
 * DTO for Song entity with artist name included
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SongDTO {
    private Long id;
    private String title;
    private Long artistId;
    private String artistName;
    private BigDecimal price;
    private String coverImageUrl;
    private String description;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private Long albumId;
    private Set<Long> genreIds;
    private Integer duration;
    private String audioUrl;
    private String lyrics;
    private Integer trackNumber;
    private Long plays;
    private String category;
    private boolean published;
    private String moderationStatus;
    private String rejectionReason;
    private Long moderatedBy;
    private LocalDateTime moderatedAt;

    /**
     * Create a SongDTO from a Song entity and artist name
     */
    public static SongDTO fromSong(Song song, String artistName) {
        return SongDTO.builder()
                .id(song.getId())
                .title(song.getTitle())
                .artistId(song.getArtistId())
                .artistName(artistName)
                .price(song.getPrice())
                .coverImageUrl(song.getCoverImageUrl())
                .description(song.getDescription())
                .createdAt(song.getCreatedAt())
                .updatedAt(song.getUpdatedAt())
                .albumId(song.getAlbumId())
                .genreIds(song.getGenreIds())
                .duration(song.getDuration())
                .audioUrl(song.getAudioUrl())
                .lyrics(song.getLyrics())
                .trackNumber(song.getTrackNumber())
                .plays(song.getPlays())
                .category(song.getCategory())
                .published(song.isPublished())
                .moderationStatus(song.getModerationStatus() != null ? song.getModerationStatus().name() : null)
                .rejectionReason(song.getRejectionReason())
                .moderatedBy(song.getModeratedBy())
                .moderatedAt(song.getModeratedAt())
                .build();
    }
}
