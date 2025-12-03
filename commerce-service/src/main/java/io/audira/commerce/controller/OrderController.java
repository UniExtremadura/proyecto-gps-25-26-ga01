package io.audira.commerce.controller;

import io.audira.commerce.dto.CreateOrderRequest;
import io.audira.commerce.dto.OrderDTO;
import io.audira.commerce.service.OrderService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Controlador REST para manejar todas las operaciones relacionadas con la creación y consulta de Órdenes de Compra (Orders).
 * <p>
 * Los endpoints base se mapean a {@code /api/orders}. Este controlador gestiona la recepción
 * de solicitudes de creación de órdenes y proporciona varios métodos de consulta por ID,
 * número de orden y usuario.
 * </p>
 *
 * @author Grupo GA01
 * @see OrderService
 * 
 */
@RestController
@RequestMapping("/api/orders")
@RequiredArgsConstructor
public class OrderController {

    /**
     * Servicio que contiene la lógica de negocio para la gestión de órdenes.
     * Se inyecta automáticamente gracias a {@link RequiredArgsConstructor} de Lombok.
     */
    private final OrderService orderService;

    /**
     * Crea una nueva orden de compra a partir de una solicitud.
     * <p>
     * Mapeo: {@code POST /api/orders}
     * La solicitud {@link CreateOrderRequest} debe ser válida y contener los detalles de la compra (ej. ID de usuario, artículos).
     * </p>
     *
     * @param request La solicitud {@link CreateOrderRequest} validada con los detalles de la orden.
     * @return {@link ResponseEntity} que contiene el objeto {@link OrderDTO} creado, con estado HTTP 201 (CREATED).
     */
    @PostMapping
    public ResponseEntity<OrderDTO> createOrder(@Valid @RequestBody CreateOrderRequest request) {
        OrderDTO order = orderService.createOrder(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(order);
    }

    /**
     * Obtiene una lista de todas las órdenes en el sistema.
     * <p>
     * Mapeo: {@code GET /api/orders}
     * Nota: Este endpoint está destinado principalmente a la comunicación interna entre servicios (servicio-a-servicio)
     * o a propósitos administrativos, no para consumo directo por el frontend en producción.
     * </p>
     *
     * @return {@link ResponseEntity} que contiene una {@link List} de todos los objetos {@link OrderDTO} con estado HTTP 200 (OK).
     */
    @GetMapping
    public ResponseEntity<List<OrderDTO>> getAllOrders() {
        return ResponseEntity.ok(orderService.getAllOrders());
    }

    /**
     * Obtiene una lista de todas las órdenes realizadas por un usuario específico.
     * <p>
     * Mapeo: {@code GET /api/orders/user/{userId}}
     * </p>
     *
     * @param userId El ID del usuario (tipo {@link Long}) cuyas órdenes se desean obtener.
     * @return {@link ResponseEntity} que contiene una {@link List} de objetos {@link OrderDTO} asociados al usuario, con estado HTTP 200 (OK).
     */
    @GetMapping("/user/{userId}")
    public ResponseEntity<List<OrderDTO>> getOrdersByUserId(@PathVariable Long userId) {
        return ResponseEntity.ok(orderService.getOrdersByUserId(userId));
    }

    /**
     * Obtiene una orden de compra específica por su ID primario.
     * <p>
     * Mapeo: {@code GET /api/orders/{orderId}}
     * </p>
     *
     * @param orderId El ID primario (tipo {@link Long}) de la orden a buscar.
     * @return {@link ResponseEntity} que contiene el objeto {@link OrderDTO} con estado HTTP 200 (OK). Retorna 404 si no se encuentra.
     */
    @GetMapping("/{orderId}")
    public ResponseEntity<OrderDTO> getOrderById(@PathVariable Long orderId) {
        return ResponseEntity.ok(orderService.getOrderById(orderId));
    }

    /**
     * Obtiene una orden de compra específica usando su número de orden (identificador externo).
     * <p>
     * Mapeo: {@code GET /api/orders/order-number/{orderNumber}}
     * </p>
     *
     * @param orderNumber El número de orden (tipo {@link String}) utilizado para identificar la transacción.
     * @return {@link ResponseEntity} que contiene el objeto {@link OrderDTO} con estado HTTP 200 (OK). Retorna 404 si no se encuentra.
     */
    @GetMapping("/order-number/{orderNumber}")
    public ResponseEntity<OrderDTO> getOrderByOrderNumber(@PathVariable String orderNumber) {
        return ResponseEntity.ok(orderService.getOrderByOrderNumber(orderNumber));
    }
}