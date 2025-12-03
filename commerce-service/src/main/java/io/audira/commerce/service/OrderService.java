package io.audira.commerce.service;

import io.audira.commerce.client.MusicCatalogClient;
import io.audira.commerce.dto.CreateOrderRequest;
import io.audira.commerce.dto.OrderDTO;
import io.audira.commerce.dto.OrderItemDTO;
import io.audira.commerce.model.Order;
import io.audira.commerce.model.OrderItem;
import io.audira.commerce.model.OrderStatus;
import io.audira.commerce.model.ItemType;
import io.audira.commerce.repository.OrderRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
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
 * */
@Service
@RequiredArgsConstructor
@Slf4j
public class OrderService {

    private final OrderRepository orderRepository;
    // Cliente inyectado para la comunicación con el microservicio de Catálogo
    private final MusicCatalogClient musicCatalogClient; 

    /**
     * Crea una nueva orden de compra a partir de una solicitud {@link CreateOrderRequest}.
     * <p>
     * PASO CLAVE: Consulta el catálogo para obtener el artistId de cada item y lo persiste en OrderItem.
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

        // Ahora creamos los order items con el order ID y obtenemos el artistId del catálogo
        final Long orderId = order.getId();
        
        List<OrderItem> orderItems = request.getItems().stream()
                .map(itemDTO -> {
                    // OBTENER EL ID DEL ARTISTA DEL CATÁLOGO (CORRECCIÓN)
                    Long artistId = getArtistIdFromCatalog(itemDTO); 
                    
                    // CONSTRUIR EL ORDERITEM con el artistId
                    return OrderItem.builder()
                            .orderId(orderId)
                            .itemType(itemDTO.getItemType())
                            .itemId(itemDTO.getItemId())
                            .quantity(itemDTO.getQuantity())
                            .price(itemDTO.getPrice())
                            .artistId(artistId) // <--- ASIGNACIÓN CRÍTICA
                            .build();
                })
                .collect(Collectors.toList());

        // Add items to order and save again
        order.setItems(orderItems);
        Order savedOrder = orderRepository.save(order);

        return mapToDTO(savedOrder);
    }
    
    // -----------------------------------------------------
    // MÉTODO AUXILIAR PARA OBTENER EL ID DEL ARTISTA
    // -----------------------------------------------------
    
    /**
     * Consulta el MusicCatalogClient (microservicio) para obtener el ID del artista asociado al ítem.
     * Utiliza la nueva ruta transaccional en el servicio de Catálogo.
     */
    private Long getArtistIdFromCatalog(OrderItemDTO itemDTO) {
        try {
            ItemType type = itemDTO.getItemType();
            Long itemId = itemDTO.getItemId();
            
            Map<String, Object> productDetails;
            
            if (type == ItemType.SONG) {
                // Llama al método del cliente HTTP que apunta a /api/songs/{id}/details/commerce
                productDetails = musicCatalogClient.getSongDetailsForCommerce(itemId);
            } else if (type == ItemType.ALBUM) {
                // Lógica de álbum pendiente: si existe un endpoint para álbumes, se usaría aquí.
                // Por ahora, usamos getAlbumById como fallback, si sabemos que devuelve artistId.
                productDetails = musicCatalogClient.getAlbumById(itemId); 
            } else {
                log.warn("ItemType {} no soportado para búsqueda de artista.", type);
                return null;
            }

            if (productDetails != null && productDetails.get("artistId") instanceof Number) {
                // Retorna el ID del artista
                return ((Number) productDetails.get("artistId")).longValue(); 
            }
            
        } catch (Exception e) {
            log.error("Failed to fetch artistId for item {} (Type: {}). Error: {}", itemDTO.getItemId(), itemDTO.getItemType(), e.getMessage());
        }
        return null;
    }

    // -----------------------------------------------------
    // MÉTODOS DE BÚSQUEDA Y AUXILIARES (Sin Cambios Lógicos)
    // -----------------------------------------------------
    
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
                        .artistId(item.getArtistId()) // Incluir el artistId en el DTO
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