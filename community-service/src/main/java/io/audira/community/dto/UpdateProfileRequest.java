package io.audira.community.dto;

import lombok.Data;

@Data
public class UpdateProfileRequest {
    private String firstName;
    private String lastName;
    private String bio;
    private String profileImageUrl;
    private String bannerImageUrl;
    private String location;
    private String website;
}
