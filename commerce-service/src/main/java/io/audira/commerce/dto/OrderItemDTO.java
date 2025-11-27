package io.audira.commerce.dto;

import io.audira.commerce.model.ItemType;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OrderItemDTO {
    private Long id;

    private Long orderId;
    
    @NotNull(message = "ItemType cannot be null")
    private ItemType itemType;

    @NotNull(message = "ItemId cannot be null")
    private Long itemId;

    @NotNull(message = "ArtistId cannot be null")
    private Long artistId;

    @Positive(message = "Quantity must be positive")
    private int quantity;

    @NotNull(message = "Price cannot be null")
    @Positive(message = "Price must be positive")
    private BigDecimal price;
}