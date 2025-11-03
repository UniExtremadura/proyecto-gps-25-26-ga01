package io.audira.community.dto;

import io.audira.community.model.UserRole;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;
import java.util.Set;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserDTO {
    private Long id;
    private String email;
    private String username;
    private String firstName;
    private String lastName;
    private String bio;
    private String profileImageUrl;
    private String bannerImageUrl;
    private String location;
    private String website;
    private UserRole role;
    private Boolean isActive;
    private Boolean isVerified;
    private Set<Long> followerIds;
    private Set<Long> followingIds;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
