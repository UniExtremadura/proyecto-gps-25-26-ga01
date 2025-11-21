package io.audira.catalog.service;

import io.audira.catalog.client.CommerceServiceClient;
import io.audira.catalog.client.RatingServiceClient;
import io.audira.catalog.client.UserServiceClient;
import io.audira.catalog.dto.*;
import io.audira.catalog.model.Album;
import io.audira.catalog.model.Collaborator;
import io.audira.catalog.model.CollaborationStatus;
import io.audira.catalog.model.Song;
import io.audira.catalog.repository.AlbumRepository;
import io.audira.catalog.repository.CollaboratorRepository;
import io.audira.catalog.repository.SongRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Service for calculating artist and song metrics
 * GA01-108: Resumen rápido (plays, valoraciones, ventas, comentarios, evolución)
 */
@Service
@RequiredArgsConstructor
public class MetricsService {

    private static final Logger logger = LoggerFactory.getLogger(MetricsService.class);

    private final SongRepository songRepository;
    private final AlbumRepository albumRepository;
    private final CollaboratorRepository collaboratorRepository;
    private final UserServiceClient userServiceClient;
    private final RatingServiceClient ratingServiceClient;
    private final CommerceServiceClient commerceServiceClient;

    /**
     * Get summary metrics for an artist
     * GA01-108: Resumen rápido
     */
    public ArtistMetricsSummary getArtistMetricsSummary(Long artistId) {
        logger.info("Calculating metrics summary for artist {}", artistId);

        // Get artist's songs
        List<Song> artistSongs = songRepository.findByArtistId(artistId);

        // Get artist's albums
        List<Album> artistAlbums = albumRepository.findByArtistId(artistId);

        // Get collaborations
        List<Collaborator> collaborations = collaboratorRepository.findByArtistIdAndStatus(
                artistId, CollaborationStatus.ACCEPTED
        );

        // Calculate plays metrics
        Long totalPlays = artistSongs.stream()
                .mapToLong(Song::getPlays)
                .sum();

        // Find most played song
        Optional<Song> mostPlayedSong = artistSongs.stream()
                .max(Comparator.comparing(Song::getPlays));

        // Calculate growth (mock data - in real implementation, query historical data)
        // TODO: Implement historical tracking for accurate growth calculations
        Double playsGrowth = calculateMockGrowth(totalPlays);

        // TODO: Integrate with community-service for real ratings data
        // Example integration:
        // RatingsResponse ratingsData = ratingService.getArtistRatings(artistId);
        // Double averageRating = ratingsData.getAverageRating();
        // Long totalRatings = ratingsData.getTotalCount();
        Double averageRating = 4.2; // Mock data
        Long totalRatings = (long) (artistSongs.size() * 15); // Mock data
        Double ratingsGrowth = 5.3; // Mock data

        // TODO: Integrate with commerce-service for real sales data
        // Example integration:
        // SalesResponse salesData = orderService.getArtistSales(artistId);
        // Long totalSales = salesData.getTotalSales();
        // BigDecimal totalRevenue = salesData.getTotalRevenue();
        Long totalSales = totalPlays / 10; // Mock: 10% conversion
        BigDecimal totalRevenue = BigDecimal.valueOf(totalSales * 0.99); // Mock: $0.99 per sale
        Long salesLast30Days = totalSales / 12; // Mock
        BigDecimal revenueLast30Days = totalRevenue.divide(BigDecimal.valueOf(12), 2, RoundingMode.HALF_UP);
        Double salesGrowth = 8.7; // Mock data
        Double revenueGrowth = 8.7; // Mock data

        // TODO: Integrate with community-service for real comments data
        // Example integration:
        // CommentsResponse commentsData = commentService.getArtistComments(artistId);
        // Long totalComments = commentsData.getTotalCount();
        Long totalComments = (long) (artistSongs.size() * 8); // Mock data
        Long commentsLast30Days = totalComments / 6; // Mock
        Double commentsGrowth = 12.4; // Mock data

        return ArtistMetricsSummary.builder()
                .artistId(artistId)
                .artistName("Artist #" + artistId) // TODO: Get from user service
                .generatedAt(LocalDateTime.now())
                // Plays
                .totalPlays(totalPlays)
                .playsLast30Days(totalPlays / 4) // Mock: 25% in last 30 days
                .playsGrowthPercentage(playsGrowth)
                // Ratings
                .averageRating(averageRating)
                .totalRatings(totalRatings)
                .ratingsGrowthPercentage(ratingsGrowth)
                // Sales
                .totalSales(totalSales)
                .totalRevenue(totalRevenue)
                .salesLast30Days(salesLast30Days)
                .revenueLast30Days(revenueLast30Days)
                .salesGrowthPercentage(salesGrowth)
                .revenueGrowthPercentage(revenueGrowth)
                // Comments
                .totalComments(totalComments)
                .commentsLast30Days(commentsLast30Days)
                .commentsGrowthPercentage(commentsGrowth)
                // Content
                .totalSongs((long) artistSongs.size())
                .totalAlbums((long) artistAlbums.size())
                .totalCollaborations((long) collaborations.size())
                // Top performing
                .mostPlayedSongId(mostPlayedSong.map(Song::getId).orElse(null))
                .mostPlayedSongName(mostPlayedSong.map(Song::getTitle).orElse("N/A"))
                .mostPlayedSongPlays(mostPlayedSong.map(Song::getPlays).orElse(0L))
                .build();
    }

    /**
     * Get metrics for a specific song
     */
    public SongMetrics getSongMetrics(Long songId) {
        Song song = songRepository.findById(songId)
                .orElseThrow(() -> new RuntimeException("Song not found: " + songId));

        // Get artist's all songs to calculate rank
        List<Song> artistSongs = songRepository.findByArtistId(song.getArtistId());
        List<Song> sortedByPlays = artistSongs.stream()
                .sorted(Comparator.comparing(Song::getPlays).reversed())
                .collect(Collectors.toList());

        int rank = sortedByPlays.indexOf(song) + 1;

        // TODO: Integrate with other services for real data
        Long mockSales = song.getPlays() / 10;
        Double mockRevenue = mockSales * 0.99;

        return SongMetrics.builder()
                .songId(song.getId())
                .songName(song.getTitle())
                .artistName("Artist #" + song.getArtistId())
                .totalPlays(song.getPlays())
                .averageRating(4.1) // Mock
                .totalRatings(45L) // Mock
                .totalComments(12L) // Mock
                .totalSales(mockSales)
                .totalRevenue(mockRevenue)
                .rankInArtistCatalog(rank)
                .build();
    }

    /**
     * Calculate mock growth percentage
     * TODO: Replace with real calculation from historical data
     */
    private Double calculateMockGrowth(Long currentValue) {
        if (currentValue == 0) return 0.0;
        // Mock: growth between 0% and 20%
        Random random = new Random(currentValue);
        return random.nextDouble() * 20.0;
    }
}