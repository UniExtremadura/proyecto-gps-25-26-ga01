package io.audira.commerce.service;

import io.audira.commerce.dto.OrderDTO; 
import io.audira.commerce.dto.OrderItemDTO;
import io.audira.commerce.model.Order;
import io.audira.commerce.model.OrderStatus;
import io.audira.commerce.repository.OrderRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class OrderService {

    private final OrderRepository orderRepository;
    public OrderDTO getOrderById(Long orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found with id: " + orderId));
        return mapToDTO(order);
    }

    public OrderDTO getOrderByOrderNumber(String orderNumber) {
        Order order = orderRepository.findByOrderNumber(orderNumber)
                .orElseThrow(() -> new RuntimeException("Order not found with order number: " + orderNumber));
        return mapToDTO(order);
    }

    public List<OrderDTO> getAllOrders() {
        return orderRepository.findAll().stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    public List<OrderDTO> getOrdersByUserId(Long userId) {
        return orderRepository.findByUserId(userId).stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    public List<OrderDTO> getOrdersByStatus(OrderStatus status) {
        return orderRepository.findByStatus(status).stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    public List<OrderDTO> getOrdersByUserIdAndStatus(Long userId, OrderStatus status) {
        return orderRepository.findByUserIdAndStatus(userId, status).stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    private OrderDTO mapToDTO(Order order) {
        List<OrderItemDTO> itemDTOs = order.getItems().stream()
                .map(item -> OrderItemDTO.builder()
                        .id(item.getId())
                        .itemType(item.getItemType())
                        .itemId(item.getItemId())
                        .quantity(item.getQuantity())
                        .price(item.getPrice())
                        .build())
                .collect(Collectors.toList());

        return OrderDTO.builder()
                .id(order.getId())
                .userId(order.getUserId())
                .orderNumber(order.getOrderNumber())
                .items(itemDTOs)
                .totalAmount(order.getTotalAmount())
                .status(order.getStatus())
                .shippingAddress(order.getShippingAddress())
                .createdAt(order.getCreatedAt())
                .updatedAt(order.getUpdatedAt())
                .build();
    }
}
