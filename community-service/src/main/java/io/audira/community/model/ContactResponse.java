package io.audira.community.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;

@Entity
@Table(name = "contact_responses")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ContactResponse {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "contact_message_id", nullable = false)
    private Long contactMessageId;

    @Column(name = "admin_id", nullable = false)
    private Long adminId;

    @Column(name = "admin_name", nullable = false, length = 255)
    private String adminName;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String response;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        ZonedDateTime now = ZonedDateTime.now(ZoneId.of("Europe/Madrid"));
        this.createdAt = now.toLocalDateTime();
        this.updatedAt = now.toLocalDateTime();
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = ZonedDateTime.now(ZoneId.of("Europe/Madrid")).toLocalDateTime();
    }
}
