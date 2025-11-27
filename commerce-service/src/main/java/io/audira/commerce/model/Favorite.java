package io.audira.commerce.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "favorites",
    uniqueConstraints = {
        @UniqueConstraint(columnNames = {"user_id", "item_type", "item_id"})
    },
    indexes = {
        @Index(name = "idx_favorites_user", columnList = "user_id"),
        @Index(name = "idx_favorites_item", columnList = "item_type, item_id")
    }
)
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Favorite {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Enumerated(EnumType.STRING)
    @Column(name = "item_type", nullable = false, length = 20)
    private ItemType itemType;

    @Column(name = "item_id", nullable = false)
    private Long itemId;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    public Favorite(Long userId, ItemType itemType, Long itemId) {
        this.userId = userId;
        this.itemType = itemType;
        this.itemId = itemId;
    }
}
