package io.audira.catalog.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import com.fasterxml.jackson.annotation.JsonCreator;

import java.time.LocalDateTime;

/**
 * Entity for managing featured content on the homepage
 * GA01-156: Seleccionar/ordenar contenido destacado
 * GA01-157: Programación de destacados
 */
@Entity
@Table(
    name = "featured_content",
    uniqueConstraints = @UniqueConstraint(columnNames = {"content_type", "content_id"}),
    indexes = {
        @Index(name = "idx_active", columnList = "is_active"),
        @Index(name = "idx_dates", columnList = "start_date, end_date"),
        @Index(name = "idx_order", columnList = "display_order")
    }
)
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FeaturedContent {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "content_type", nullable = false, length = 20)
    @Enumerated(EnumType.STRING)
    private ContentType contentType;

    @Column(name = "content_id", nullable = false)
    private Long contentId;

    @Column(name = "display_order", nullable = false)
    @Builder.Default
    private Integer displayOrder = 0;

    @Column(name = "start_date")
    private LocalDateTime startDate;

    @Column(name = "end_date")
    private LocalDateTime endDate;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean isActive = true;

    // Denormalized fields for performance
    @Column(name = "content_title", length = 255)
    private String contentTitle;

    @Column(name = "content_image_url", columnDefinition = "TEXT")
    private String contentImageUrl;

    @Column(name = "content_artist", length = 255)
    private String contentArtist;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    /**
     * Types of content that can be featured
     */
    public enum ContentType {
        SONG,
        ALBUM;

        /**
         * Case-insensitive deserialization for JSON
         * Converts "song", "Song", "SONG" all to SONG enum value
         */
        @JsonCreator
        public static ContentType fromString(String value) {
            if (value == null) {
                return null;
            }
            return ContentType.valueOf(value.toUpperCase());
        }
    }

    /**
     * Checks if the featured content is currently active based on dates
     * GA01-157: Programación de destacados
     */
    @Transient
    public boolean isScheduledActive() {
        if (!isActive) {
            return false;
        }

        LocalDateTime now = LocalDateTime.now();

        // If start date exists and we haven't reached it yet
        if (startDate != null && now.isBefore(startDate)) {
            return false;
        }

        // If end date exists and we've passed it
        if (endDate != null && now.isAfter(endDate)) {
            return false;
        }

        return true;
    }

    /**
     * Gets the schedule status as text
     * GA01-157: Programación de destacados
     */
    @Transient
    public String getScheduleStatus() {
        if (!isActive) {
            return "INACTIVE";
        }

        LocalDateTime now = LocalDateTime.now();

        if (startDate != null && now.isBefore(startDate)) {
            return "SCHEDULED";
        }

        if (endDate != null && now.isAfter(endDate)) {
            return "FINISHED";
        }

        return "ACTIVE";
    }
}
