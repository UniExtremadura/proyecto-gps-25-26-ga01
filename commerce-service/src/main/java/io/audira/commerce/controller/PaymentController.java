package io.audira.commerce.controller;

import io.audira.commerce.dto.PaymentDTO;
import io.audira.commerce.dto.PaymentResponse;
import io.audira.commerce.dto.ProcessPaymentRequest;
import io.audira.commerce.service.PaymentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Controlador REST para manejar todas las operaciones relacionadas con el procesamiento y consulta de Pagos.
 * <p>
 * Los endpoints base se mapean a {@code /api/payments}. Este controlador actúa como la interfaz
 * principal para iniciar transacciones (cobros, reintentos, reembolsos) y consultar el historial
 * de pagos.
 * </p>
 *
 * @author Grupo GA01
 * @see PaymentService
 * 
 */
@RestController
@RequestMapping("/api/payments")
@RequiredArgsConstructor
public class PaymentController {

    /**
     * Servicio que contiene la lógica de negocio para la gestión de pagos y la interacción con pasarelas.
     * Se inyecta automáticamente gracias a {@link RequiredArgsConstructor} de Lombok.
     */
    private final PaymentService paymentService;

    /**
     * Inicia el proceso de pago para una orden de compra.
     * <p>
     * Mapeo: {@code POST /api/payments/process}
     * El estado de la respuesta HTTP depende del resultado de la transacción (200 OK si es exitoso, 400 BAD REQUEST si falla).
     * </p>
     *
     * @param request La solicitud {@link ProcessPaymentRequest} validada con los detalles de la transacción.
     * @return {@link ResponseEntity} que contiene el objeto {@link PaymentResponse} con el resultado del intento de pago.
     */
    @PostMapping("/process")
    public ResponseEntity<PaymentResponse> processPayment(
            @Valid @RequestBody ProcessPaymentRequest request) {
        PaymentResponse response = paymentService.processPayment(request);
        return ResponseEntity.status(response.isSuccess() ? HttpStatus.OK : HttpStatus.BAD_REQUEST)
                .body(response);
    }

    /**
     * Reintenta el procesamiento de un pago previamente fallido, identificado por su ID.
     * <p>
     * Mapeo: {@code POST /api/payments/{paymentId}/retry}
     * </p>
     *
     * @param paymentId El ID (tipo {@link Long}) del registro de pago fallido a reintentar.
     * @return {@link ResponseEntity} que contiene el nuevo {@link PaymentResponse} con el resultado del reintento (200 OK) o un 400 BAD REQUEST si la operación no es posible.
     */
    @PostMapping("/{paymentId}/retry")
    public ResponseEntity<PaymentResponse> retryPayment(@PathVariable Long paymentId) {
        try {
            PaymentResponse response = paymentService.retryPayment(paymentId);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(PaymentResponse.builder()
                            .success(false)
                            .message(e.getMessage())
                            .build());
        }
    }

    /**
     * Obtiene una lista de todos los pagos asociados a un usuario específico.
     * <p>
     * Mapeo: {@code GET /api/payments/user/{userId}}
     * </p>
     *
     * @param userId El ID del usuario (tipo {@link Long}) cuyas transacciones se desean obtener.
     * @return {@link ResponseEntity} que contiene una {@link List} de objetos {@link PaymentDTO} con estado HTTP 200 (OK).
     */
    @GetMapping("/user/{userId}")
    public ResponseEntity<List<PaymentDTO>> getPaymentsByUserId(@PathVariable Long userId) {
        return ResponseEntity.ok(paymentService.getPaymentsByUserId(userId));
    }

    /**
     * Obtiene una lista de todos los pagos asociados a una orden de compra específica.
     * <p>
     * Mapeo: {@code GET /api/payments/order/{orderId}}
     * </p>
     *
     * @param orderId El ID de la orden (tipo {@link Long}) cuyas transacciones se desean obtener.
     * @return {@link ResponseEntity} que contiene una {@link List} de objetos {@link PaymentDTO} con estado HTTP 200 (OK).
     */
    @GetMapping("/order/{orderId}")
    public ResponseEntity<List<PaymentDTO>> getPaymentsByOrderId(@PathVariable Long orderId) {
        return ResponseEntity.ok(paymentService.getPaymentsByOrderId(orderId));
    }

    /**
     * Obtiene un registro de pago utilizando el ID de transacción único de la pasarela.
     * <p>
     * Mapeo: {@code GET /api/payments/transaction/{transactionId}}
     * </p>
     *
     * @param transactionId El ID de la transacción (tipo {@link String}) proporcionado por la pasarela de pago.
     * @return {@link ResponseEntity} que contiene el objeto {@link PaymentDTO} con estado HTTP 200 (OK) o 404 (NOT FOUND) si no existe.
     */
    @GetMapping("/transaction/{transactionId}")
    public ResponseEntity<PaymentDTO> getPaymentByTransactionId(@PathVariable String transactionId) {
        try {
            return ResponseEntity.ok(paymentService.getPaymentByTransactionId(transactionId));
        } catch (Exception e) {
            return ResponseEntity.notFound().build();
        }
    }

    /**
     * Obtiene un registro de pago específico utilizando su ID primario.
     * <p>
     * Mapeo: {@code GET /api/payments/{paymentId}}
     * </p>
     *
     * @param paymentId El ID primario (tipo {@link Long}) del registro de pago.
     * @return {@link ResponseEntity} que contiene el objeto {@link PaymentDTO} con estado HTTP 200 (OK) o 404 (NOT FOUND) si no existe.
     */
    @GetMapping("/{paymentId}")
    public ResponseEntity<PaymentDTO> getPaymentById(@PathVariable Long paymentId) {
        try {
            return ResponseEntity.ok(paymentService.getPaymentById(paymentId));
        } catch (Exception e) {
            return ResponseEntity.notFound().build();
        }
    }

    /**
     * Inicia un proceso de reembolso para un pago exitoso previamente realizado.
     * <p>
     * Mapeo: {@code POST /api/payments/{paymentId}/refund}
     * </p>
     *
     * @param paymentId El ID (tipo {@link Long}) del pago original a reembolsar.
     * @return {@link ResponseEntity} que contiene el objeto {@link PaymentResponse} con el resultado del reembolso (200 OK) o un 400 BAD REQUEST si falla.
     */
    @PostMapping("/{paymentId}/refund")
    public ResponseEntity<PaymentResponse> refundPayment(@PathVariable Long paymentId) {
        try {
            PaymentResponse response = paymentService.refundPayment(paymentId);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(PaymentResponse.builder()
                            .success(false)
                            .message(e.getMessage())
                            .build());
        }
    }
}