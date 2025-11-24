package io.audira.commerce.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OrderDTO {
    private Long id;
    private Long userId;
    private String orderNumber;
    private List<OrderItemDTO> items;
    private BigDecimal totalAmount;
    private String status; // Changed from OrderStatus enum to String for better inter-service compatibility
    private String shippingAddress;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
