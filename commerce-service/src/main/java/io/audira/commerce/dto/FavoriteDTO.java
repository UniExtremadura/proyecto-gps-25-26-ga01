package io.audira.commerce.dto;

import io.audira.commerce.model.Favorite;
import io.audira.commerce.model.ItemType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FavoriteDTO {

    private Long id;
    private Long userId;
    private ItemType itemType;
    private Long itemId;
    private LocalDateTime createdAt;

    public static FavoriteDTO fromEntity(Favorite favorite) {
        return FavoriteDTO.builder()
            .id(favorite.getId())
            .userId(favorite.getUserId())
            .itemType(favorite.getItemType())
            .itemId(favorite.getItemId())
            .createdAt(favorite.getCreatedAt())
            .build();
    }

    public Favorite toEntity() {
        return Favorite.builder()
            .id(this.id)
            .userId(this.userId)
            .itemType(this.itemType)
            .itemId(this.itemId)
            .createdAt(this.createdAt)
            .build();
    }
}
