package io.audira.commerce.dto;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PurchaseNotificationRequest {

    @NotNull(message = "Order ID is required")
    private Long orderId;

    @NotNull(message = "Payment ID is required")
    private Long paymentId;

    @NotNull(message = "Buyer ID is required")
    private Long buyerId;

    private String buyerName;

    @NotNull(message = "Total amount is required")
    private BigDecimal totalAmount;

    @NotNull(message = "Purchased items are required")
    private List<PurchasedItemInfo> purchasedItems;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PurchasedItemInfo {
        private Long itemId;
        private String itemType; // SONG, ALBUM
        private String itemName;
        private Long artistId;
        private BigDecimal price;
        private Integer quantity;
    }
}