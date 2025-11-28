package io.audira.commerce.service;

import io.audira.commerce.dto.CreateOrderRequest;
import io.audira.commerce.dto.OrderDTO;
import io.audira.commerce.dto.OrderItemDTO;
import io.audira.commerce.model.Order;
import io.audira.commerce.model.OrderItem;
import io.audira.commerce.model.OrderStatus;
import io.audira.commerce.repository.OrderRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Servicio de lógica de negocio responsable de la gestión de Órdenes de Compra (Order).
 * <p>
 * Implementa las operaciones transaccionales para la creación de órdenes, la generación
 * de identificadores únicos y los métodos de consulta por ID, número de orden y estado.
 * </p>
 *
 * @author Grupo GA01
 * @see OrderRepository
 * 
 */
@Service
@RequiredArgsConstructor
public class OrderService {

    private final OrderRepository orderRepository;

    /**
     * Crea una nueva orden de compra a partir de una solicitud {@link CreateOrderRequest}.
     * <p>
     * Pasos clave:
     * <ul>
     * <li>Genera un número de orden único.</li>
     * <li>Calcula el monto total.</li>
     * <li>Persiste la cabecera de la orden y luego asocia y persiste los artículos ({@link OrderItem}).</li>
     * <li>Establece el estado inicial como {@link OrderStatus#PENDING}.</li>
     * </ul>
     * </p>
     *
     * @param request La solicitud {@link CreateOrderRequest} validada.
     * @return El objeto {@link OrderDTO} de la orden recién creada.
     */
    @Transactional
    public OrderDTO createOrder(CreateOrderRequest request) {
        // Generate unique order number
        String orderNumber = generateOrderNumber();

        // Calculate total amount
        BigDecimal totalAmount = request.getItems().stream()
                .map(item -> item.getPrice().multiply(BigDecimal.valueOf(item.getQuantity())))
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // Create order without items first to get the ID
        Order order = Order.builder()
                .userId(request.getUserId())
                .orderNumber(orderNumber)
                .items(new ArrayList<>())
                .totalAmount(totalAmount)
                .status(OrderStatus.PENDING)
                .shippingAddress(request.getShippingAddress())
                .build();

        // Save to get the order ID
        order = orderRepository.save(order);

        // Now create order items with the order ID
        final Long orderId = order.getId();
        List<OrderItem> orderItems = request.getItems().stream()
                .map(itemDTO -> OrderItem.builder()
                        .orderId(orderId)
                        .itemType(itemDTO.getItemType())
                        .itemId(itemDTO.getItemId())
                        .quantity(itemDTO.getQuantity())
                        .price(itemDTO.getPrice())
                        .build())
                .collect(Collectors.toList());

        // Add items to order and save again
        order.setItems(orderItems);
        Order savedOrder = orderRepository.save(order);

        return mapToDTO(savedOrder);
    }

    /**
     * Genera un número de orden único utilizando el formato "ORD-" seguido de un segmento aleatorio de UUID.
     * <p>
     * Verifica la unicidad en la base de datos para evitar colisiones.
     * </p>
     *
     * @return El número de orden generado (tipo {@code String}).
     */
    private String generateOrderNumber() {
        String orderNumber;
        do {
            orderNumber = "ORD-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        } while (orderRepository.existsByOrderNumber(orderNumber));
        return orderNumber;
    }

    /**
     * Obtiene una orden por su ID primario.
     *
     * @param orderId El ID primario de la orden (tipo {@link Long}).
     * @return El objeto {@link OrderDTO}.
     * @throws RuntimeException si la orden no se encuentra.
     */
    public OrderDTO getOrderById(Long orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found with id: " + orderId));
        return mapToDTO(order);
    }

    /**
     * Obtiene una orden por su número de orden único.
     *
     * @param orderNumber El número de orden (tipo {@link String}).
     * @return El objeto {@link OrderDTO}.
     * @throws RuntimeException si la orden no se encuentra.
     */
    public OrderDTO getOrderByOrderNumber(String orderNumber) {
        Order order = orderRepository.findByOrderNumber(orderNumber)
                .orElseThrow(() -> new RuntimeException("Order not found with order number: " + orderNumber));
        return mapToDTO(order);
    }

    /**
     * Obtiene todas las órdenes registradas en el sistema.
     * <p>
     * Utilizado principalmente para propósitos administrativos o de consulta interna.
     * </p>
     *
     * @return Una {@link List} de todos los objetos {@link OrderDTO}.
     */
    public List<OrderDTO> getAllOrders() {
        return orderRepository.findAll().stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    /**
     * Obtiene todas las órdenes realizadas por un usuario específico.
     *
     * @param userId El ID del usuario.
     * @return Una {@link List} de {@link OrderDTO} del usuario.
     */
    public List<OrderDTO> getOrdersByUserId(Long userId) {
        return orderRepository.findByUserId(userId).stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    /**
     * Obtiene todas las órdenes que se encuentran en un estado específico.
     *
     * @param status El estado de la orden ({@link OrderStatus}).
     * @return Una {@link List} de {@link OrderDTO} que coinciden con el estado.
     */
    public List<OrderDTO> getOrdersByStatus(OrderStatus status) {
        return orderRepository.findByStatus(status).stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    /**
     * Obtiene todas las órdenes de un usuario que se encuentran en un estado específico.
     *
     * @param userId El ID del usuario.
     * @param status El estado de la orden ({@link OrderStatus}).
     * @return Una {@link List} de {@link OrderDTO} que cumplen ambas condiciones.
     */
    public List<OrderDTO> getOrdersByUserIdAndStatus(Long userId, OrderStatus status) {
        return orderRepository.findByUserIdAndStatus(userId, status).stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    /**
     * Mapea una entidad {@link Order} a su respectivo Data Transfer Object (DTO) {@link OrderDTO}.
     * <p>
     * Método auxiliar privado. Realiza la conversión de la lista de {@link OrderItem} a {@link OrderItemDTO}.
     * </p>
     *
     * @param order La entidad {@link Order} de origen.
     * @return El {@link OrderDTO} resultante.
     */
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
                .status(order.getStatus() != null ? order.getStatus().name() : null)
                .shippingAddress(order.getShippingAddress())
                .createdAt(order.getCreatedAt())
                .updatedAt(order.getUpdatedAt())
                .build();
    }
}