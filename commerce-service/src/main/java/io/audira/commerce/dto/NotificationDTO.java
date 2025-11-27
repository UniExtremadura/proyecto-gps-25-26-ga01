package io.audira.commerce.dto;

import io.audira.commerce.model.NotificationType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificationDTO {
    private Long id;
    private Long userId;
    private NotificationType type;
    private String title;
    private String message;
    private Long referenceId;
    private String referenceType;
    private Boolean isRead;
    private Boolean isSent;
    private LocalDateTime sentAt;
    private LocalDateTime readAt;
    private LocalDateTime createdAt;
    private String metadata;
}