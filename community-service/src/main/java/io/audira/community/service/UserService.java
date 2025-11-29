package io.audira.community.service;

import io.audira.community.dto.*;
import io.audira.community.model.*;
import io.audira.community.repository.UserRepository;
import io.audira.community.security.JwtTokenProvider;
import io.audira.community.security.UserPrincipal;
import io.audira.community.client.FileServiceClient;
import io.audira.community.util.SocialMediaValidator;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Servicio principal de lógica de negocio responsable de la gestión de usuarios, la autenticación,
 * las interacciones sociales (follow/unfollow) y la administración de perfiles.
 * <p>
 * Este servicio orquesta la persistencia, la seguridad y la comunicación con el microservicio de archivos.
 * </p>
 *
 * @author Grupo GA01
 * @see UserRepository
 * @see JwtTokenProvider
 * 
 */
@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtTokenProvider tokenProvider;
    private final FileServiceClient fileServiceClient;


    private static final Logger logger = LoggerFactory.getLogger(UserService.class);

    // --- Métodos de Autenticación y Perfil ---

    /**
     * Registra un nuevo usuario en el sistema.
     * <p>
     * 1. Verifica la unicidad de email y nombre de usuario.
     * 2. Hashea la contraseña.
     * 3. Crea la entidad específica ({@link Artist} o {@link RegularUser}) basada en el rol.
     * 4. Autentica al nuevo usuario inmediatamente y genera un JWT.
     * </p>
     *
     * @param request La solicitud {@link RegisterRequest} validada.
     * @return El objeto {@link AuthResponse} que contiene el JWT y los datos del usuario.
     * @throws RuntimeException si el email o nombre de usuario ya existen.
     */
    @Transactional
    public AuthResponse registerUser(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Este email ya está registrado. Por favor usa otro email o inicia sesión.");
        }
        if (userRepository.existsByUsername(request.getUsername())) {
            throw new RuntimeException("Este nombre de usuario ya está en uso. Por favor elige otro nombre de usuario.");
        }

        User user;
        String encodedPassword = passwordEncoder.encode(request.getPassword());
        String uid = request.getEmail(); 

        // Create specific user type based on role (using JPA inheritance)
        if (request.getRole() == UserRole.ARTIST) {
            user = Artist.builder()
                    .email(request.getEmail())
                    .username(request.getUsername())
                    .password(encodedPassword)
                    .firstName(request.getFirstName())
                    .lastName(request.getLastName())
                    .role(request.getRole())
                    .uid(uid)
                    .isActive(true)
                    .isVerified(false)
                    .artistName(request.getUsername()) // Default artistName to username
                    .verifiedArtist(false)
                    .build();
        } else {
            user = RegularUser.builder()
                    .email(request.getEmail())
                    .username(request.getUsername())
                    .password(encodedPassword)
                    .firstName(request.getFirstName())
                    .lastName(request.getLastName())
                    .role(request.getRole())
                    .uid(uid)
                    .isActive(true)
                    .isVerified(false)
                    .build();
        }

        user = userRepository.save(user);

        // Authenticate the user and generate token
        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword())
        );
        SecurityContextHolder.getContext().setAuthentication(authentication);
        String token = tokenProvider.generateToken(authentication);

        return AuthResponse.builder()
                .token(token)
                .user(mapToDTO(user))
                .build();
    }

    /**
     * Autentica a un usuario utilizando sus credenciales (email/username y contraseña).
     *
     * @param request La solicitud {@link LoginRequest} con las credenciales.
     * @return El objeto {@link AuthResponse} con el JWT y los datos del usuario.
     * @throws RuntimeException si la autenticación falla (credenciales incorrectas).
     */
    public AuthResponse loginUser(LoginRequest request) {
        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        request.getEmailOrUsername(),
                        request.getPassword()
                )
        );

        SecurityContextHolder.getContext().setAuthentication(authentication);
        String token = tokenProvider.generateToken(authentication);

        UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
        User user = userRepository.findById(userPrincipal.getId())
                .orElseThrow(() -> new RuntimeException("Usuario no encontrado"));

        return AuthResponse.builder()
                .token(token)
                .user(mapToDTO(user))
                .build();
    }

    /**
     * Actualiza el perfil de un usuario con los datos proporcionados en la solicitud.
     *
     * @param userId El ID del usuario a modificar.
     * @param request La solicitud {@link UpdateProfileRequest} con los campos a actualizar.
     * @return El {@link UserDTO} actualizado.
     * @throws RuntimeException si el usuario no se encuentra.
     * @throws IllegalArgumentException si alguna URL de red social es inválida.
     */
    @Transactional
    public UserDTO updateProfile(Long userId, UpdateProfileRequest request) {

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (request.getFirstName() != null) {
            user.setFirstName(request.getFirstName());
        }
        if (request.getLastName() != null) {
            user.setLastName(request.getLastName());
        }
        if (request.getBio() != null) {
            user.setBio(request.getBio());
        }
        if (request.getProfileImageUrl() != null) {
            user.setProfileImageUrl(request.getProfileImageUrl());
        }
        if (request.getBannerImageUrl() != null) {
            user.setBannerImageUrl(request.getBannerImageUrl());
        }
        if (request.getLocation() != null) {
            user.setLocation(request.getLocation());
        }
        if (request.getWebsite() != null) {
            user.setWebsite(request.getWebsite());
        }

        // Update artist-specific fields if user is an artist
        if (user instanceof Artist) {
            Artist artist = (Artist) user;
            if (request.getArtistName() != null) {
                artist.setArtistName(request.getArtistName());
            }
            if (request.getArtistBio() != null) {
                artist.setArtistBio(request.getArtistBio());
            }
            if (request.getRecordLabel() != null) {
                artist.setRecordLabel(request.getRecordLabel());
            }
        }

        // Update social media links with validation
        if (request.getTwitterUrl() != null && !request.getTwitterUrl().trim().isEmpty()) {
            String twitterUrl = request.getTwitterUrl().trim();
            if (!SocialMediaValidator.isValidTwitterUrl(twitterUrl)) {
                throw new IllegalArgumentException("URL de Twitter/X inválida. Formato: https://twitter.com/username o https://x.com/username");
            }
            user.setTwitterUrl(twitterUrl);
        }
        if (request.getInstagramUrl() != null && !request.getInstagramUrl().trim().isEmpty()) {
            String instagramUrl = request.getInstagramUrl().trim();
            if (!SocialMediaValidator.isValidInstagramUrl(instagramUrl)) {
                throw new IllegalArgumentException("URL de Instagram inválida. Formato: https://instagram.com/username");
            }
            user.setInstagramUrl(instagramUrl);
        }
        if (request.getFacebookUrl() != null && !request.getFacebookUrl().trim().isEmpty()) {
            String facebookUrl = request.getFacebookUrl().trim();
            if (!SocialMediaValidator.isValidFacebookUrl(facebookUrl)) {
                throw new IllegalArgumentException("URL de Facebook inválida. Formato: https://facebook.com/username");
            }
            user.setFacebookUrl(facebookUrl);
        }
        if (request.getYoutubeUrl() != null && !request.getYoutubeUrl().trim().isEmpty()) {
            String youtubeUrl = request.getYoutubeUrl().trim();
            if (!SocialMediaValidator.isValidYoutubeUrl(youtubeUrl)) {
                throw new IllegalArgumentException("URL de YouTube inválida. Formato: https://youtube.com/@channel o https://youtube.com/c/channel");
            }
            user.setYoutubeUrl(youtubeUrl);
        }
        if (request.getSpotifyUrl() != null && !request.getSpotifyUrl().trim().isEmpty()) {
            String spotifyUrl = request.getSpotifyUrl().trim();
            if (!SocialMediaValidator.isValidSpotifyUrl(spotifyUrl)) {
                throw new IllegalArgumentException("URL de Spotify inválida. Formato: https://open.spotify.com/artist/...");
            }
            user.setSpotifyUrl(spotifyUrl);
        }
        if (request.getTiktokUrl() != null && !request.getTiktokUrl().trim().isEmpty()) {
            String tiktokUrl = request.getTiktokUrl().trim();
            if (!SocialMediaValidator.isValidTiktokUrl(tiktokUrl)) {
                throw new IllegalArgumentException("URL de TikTok inválida. Formato: https://tiktok.com/@username");
            }
            user.setTiktokUrl(tiktokUrl);
        }

        user = userRepository.save(user);
        return mapToDTO(user);
    }

    /**
     * Obtiene el perfil de un usuario por su ID.
     *
     * @param id El ID del usuario (tipo {@link Long}).
     * @return El objeto {@link UserDTO} del perfil.
     * @throws RuntimeException si el usuario no se encuentra.
     */
    public UserDTO getUserById(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + id));
        return mapToDTO(user);
    }

    /**
     * Obtiene el perfil de un usuario por su nombre de usuario.
     *
     * @param username El nombre de usuario (String).
     * @return El objeto {@link UserDTO} del perfil.
     * @throws RuntimeException si el usuario no se encuentra.
     */
    public UserDTO getUserByUsername(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found with username: " + username));
        return mapToDTO(user);
    }

    /**
     * Obtiene una lista de todos los usuarios registrados.
     *
     * @return Una {@link List} de {@link UserDTO}.
     */
    public List<UserDTO> getAllUsers() {
        return userRepository.findAll().stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    /**
     * Obtiene una lista de usuarios filtrados por su rol.
     *
     * @param role El rol (String) a buscar (ej. "ARTIST").
     * @return Una {@link List} de {@link UserDTO}.
     */
    public List<UserDTO> getUsersByRole(String role) {
        UserRole userRole = UserRole.valueOf(role.toUpperCase());
        return userRepository.findByRole(userRole).stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    /**
     * Sube una imagen de perfil y actualiza la URL en el perfil del usuario.
     *
     * @param userId El ID del usuario.
     * @param imageFile El archivo de imagen {@link MultipartFile} a subir.
     * @return El {@link UserDTO} actualizado.
     * @throws RuntimeException si el usuario no se encuentra o falla la subida.
     */
    @Transactional
    public UserDTO uploadProfileImage(Long userId, MultipartFile imageFile) {
        try {
            // Upload image to file service
            String imageUrl = fileServiceClient.uploadImage(imageFile);

            // Update user with new profile image URL
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new RuntimeException("User not found"));

            user.setProfileImageUrl(imageUrl);
            user = userRepository.save(user);

            logger.info("Profile image updated for user: {} ({})", user.getUsername(), user.getEmail());

            return mapToDTO(user);
        } catch (Exception e) {
            logger.error("Error uploading profile image for user {}: {}", userId, e.getMessage());
            throw new RuntimeException("Error al subir la imagen de perfil: " + e.getMessage());
        }
    }

    /**
     * Sube una imagen de banner y actualiza la URL en el perfil del usuario.
     *
     * @param userId El ID del usuario.
     * @param imageFile El archivo de imagen {@link MultipartFile} a subir.
     * @return El {@link UserDTO} actualizado.
     * @throws RuntimeException si el usuario no se encuentra o falla la subida.
     */
    @Transactional
    public UserDTO uploadBannerImage(Long userId, MultipartFile imageFile) {
        try {
            // Upload image to file service
            String imageUrl = fileServiceClient.uploadImage(imageFile);

            // Update user with new banner image URL
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new RuntimeException("User not found"));

            user.setBannerImageUrl(imageUrl);
            user = userRepository.save(user);

            logger.info("Banner image updated for user: {} ({})", user.getUsername(), user.getEmail());

            return mapToDTO(user);
        } catch (Exception e) {
            logger.error("Error uploading banner image for user {}: {}", userId, e.getMessage());
            throw new RuntimeException("Error al subir la imagen de banner: " + e.getMessage());
        }
    }
    
    // --- Lógica de Interacción Social ---

    /**
     * Inicia la acción de seguir a otro usuario.
     *
     * @param userId ID del usuario seguidor.
     * @param targetUserId ID del usuario seguido.
     * @return El {@link UserDTO} del usuario seguidor actualizado.
     * @throws RuntimeException si los IDs son iguales o si un usuario no se encuentra.
     */
    @Transactional
    public UserDTO followUser(Long userId, Long targetUserId) {
        if (userId.equals(targetUserId)) {
            throw new RuntimeException("Cannot follow yourself");
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));
        User targetUser = userRepository.findById(targetUserId)
                .orElseThrow(() -> new RuntimeException("Target user not found"));

        user.getFollowingIds().add(targetUserId);
        targetUser.getFollowerIds().add(userId);

        userRepository.save(user);
        userRepository.save(targetUser);

        return mapToDTO(user);
    }

    /**
     * Inicia la acción de dejar de seguir a otro usuario.
     *
     * @param userId ID del usuario seguidor.
     * @param targetUserId ID del usuario seguido.
     * @return El {@link UserDTO} del usuario seguidor actualizado.
     * @throws RuntimeException si un usuario no se encuentra.
     */
    @Transactional
    public UserDTO unfollowUser(Long userId, Long targetUserId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));
        User targetUser = userRepository.findById(targetUserId)
                .orElseThrow(() -> new RuntimeException("Target user not found"));

        user.getFollowingIds().remove(targetUserId);
        targetUser.getFollowerIds().remove(userId);

        userRepository.save(user);
        userRepository.save(targetUser);

        return mapToDTO(user);
    }

    /**
     * Obtiene la lista de seguidores de un usuario.
     *
     * @param userId El ID del usuario.
     * @return Una {@link List} de {@link UserDTO} que son seguidores.
     * @throws RuntimeException si el usuario no se encuentra.
     */
    public List<UserDTO> getFollowers(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        return user.getFollowerIds().stream()
                .map(this::getUserById)
                .collect(Collectors.toList());
    }

    /**
     * Obtiene la lista de usuarios que un usuario está siguiendo.
     *
     * @param userId El ID del usuario.
     * @return Una {@link List} de {@link UserDTO} que el usuario está siguiendo.
     * @throws RuntimeException si el usuario no se encuentra.
     */
    public List<UserDTO> getFollowing(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        return user.getFollowingIds().stream()
                .map(this::getUserById)
                .collect(Collectors.toList());
    }

    /**
     * Obtiene la lista de usuarios que un usuario está siguiendo y que tienen el rol de {@link UserRole#ARTIST}.
     *
     * @param userId El ID del usuario.
     * @return Una {@link List} de {@link UserDTO} que son artistas seguidos.
     * @throws RuntimeException si el usuario no se encuentra.
     */
    public List<UserDTO> getFollowedArtists(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        return user.getFollowingIds().stream()
                .map(followingId -> userRepository.findById(followingId).orElse(null))
                .filter(followedUser -> followedUser != null && followedUser.getRole() == UserRole.ARTIST)
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    /**
     * Cambia la contraseña de un usuario después de verificar la contraseña actual.
     *
     * @param userId El ID del usuario.
     * @param request La solicitud {@link ChangePasswordRequest} validada.
     * @throws RuntimeException si el usuario no se encuentra, las contraseñas no coinciden o la contraseña actual es incorrecta.
     */
    @Transactional
    public void changePassword(Long userId, ChangePasswordRequest request) {
        // Validar que las contraseñas coincidan
        if (!request.getNewPassword().equals(request.getConfirmPassword())) {
            throw new RuntimeException("Las contraseñas no coinciden");
        }

        // Obtener el usuario
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Usuario no encontrado"));

        // Verificar que la contraseña actual sea correcta
        if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPassword())) {
            throw new RuntimeException("La contraseña actual es incorrecta");
        }

        // Validar que la nueva contraseña sea diferente de la actual
        if (passwordEncoder.matches(request.getNewPassword(), user.getPassword())) {
            throw new RuntimeException("La nueva contraseña debe ser diferente de la actual");
        }

        // Actualizar la contraseña
        user.setPassword(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);
    }
    
    // --- Métodos de Búsqueda de Artistas ---

    /**
     * Busca artistas activos por una cadena de consulta que coincida con su nombre artístico, nombre o apellido.
     * <p>
     * Utiliza la consulta JPQL personalizada definida en {@link UserRepository}.
     * </p>
     *
     * @param query La cadena de texto de búsqueda.
     * @return Una {@link List} de {@link UserDTO} que representan a los artistas que coinciden.
     */
    public List<UserDTO> searchArtists(String query) {
        List<Artist> artists = userRepository.searchArtistsByName(query);
        return artists.stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    /**
     * Busca los IDs de artistas activos por una cadena de consulta.
     * <p>
     * Utilizado principalmente por otros microservicios (uso interno).
     * </p>
     *
     * @param query La cadena de texto de búsqueda.
     * @return Una {@link List} de IDs (tipo {@link Long}) de los artistas que coinciden.
     */
    public List<Long> searchArtistIds(String query) {
        return userRepository.searchArtistIdsByName(query);
    }
    
    // --- Métodos de Administración (AdminController) ---

    /**
     * Cambia el rol de un usuario existente.
     * <p>
     * Esta operación es compleja en el esquema de herencia {@code JOINED} de JPA, ya que requiere:
     * 1. Eliminar la entidad existente.
     * 2. Crear una nueva entidad ({@link Artist} o {@link RegularUser}) con el mismo ID, copiando todos los datos, pero con el nuevo rol.
     * </p>
     *
     * @param userId El ID del usuario.
     * @param newRole El nuevo rol ({@link UserRole}) a asignar.
     * @return El {@link UserDTO} de la nueva entidad con el rol actualizado.
     * @throws RuntimeException si el usuario no se encuentra.
     */
    @Transactional
    public UserDTO changeUserRole(Long userId, UserRole newRole) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // Check if role is actually changing
        if (user.getRole() == newRole) {
            return mapToDTO(user);
        }

        // Get current role for logging
        UserRole oldRole = user.getRole();

        // 1. Delete old user entity
        userRepository.delete(user);
        userRepository.flush(); // Force deletion before insertion

        // 2. Create new user entity based on new role
        User newUser;
        if (newRole == UserRole.ARTIST) {
            newUser = Artist.builder()
                    // Copy existing data and assign the original ID
                    .id(user.getId()) 
                    .email(user.getEmail())
                    .username(user.getUsername())
                    .password(user.getPassword())
                    .firstName(user.getFirstName())
                    .lastName(user.getLastName())
                    .role(newRole) // <-- NEW ROLE
                    .uid(user.getUid())
                    .bio(user.getBio())
                    .profileImageUrl(user.getProfileImageUrl())
                    .bannerImageUrl(user.getBannerImageUrl())
                    .location(user.getLocation())
                    .website(user.getWebsite())
                    .twitterUrl(user.getTwitterUrl())
                    .instagramUrl(user.getInstagramUrl())
                    .facebookUrl(user.getFacebookUrl())
                    .youtubeUrl(user.getYoutubeUrl())
                    .spotifyUrl(user.getSpotifyUrl())
                    .tiktokUrl(user.getTiktokUrl())
                    .isActive(user.getIsActive())
                    .isVerified(user.getIsVerified())
                    .followerIds(user.getFollowerIds())
                    .followingIds(user.getFollowingIds())
                    .createdAt(user.getCreatedAt())
                    .build();
        } else {
            // For other roles (USER, ADMIN), use RegularUser (or Admin if applicable)
            newUser = RegularUser.builder() // Assumes RegularUser is the base concrete implementation for USER/ADMIN
                    .id(user.getId())
                    .email(user.getEmail())
                    .username(user.getUsername())
                    .password(user.getPassword())
                    .firstName(user.getFirstName())
                    .lastName(user.getLastName())
                    .role(newRole) // <-- NEW ROLE
                    .uid(user.getUid())
                    .bio(user.getBio())
                    .profileImageUrl(user.getProfileImageUrl())
                    .bannerImageUrl(user.getBannerImageUrl())
                    .location(user.getLocation())
                    .website(user.getWebsite())
                    .twitterUrl(user.getTwitterUrl())
                    .instagramUrl(user.getInstagramUrl())
                    .facebookUrl(user.getFacebookUrl())
                    .youtubeUrl(user.getYoutubeUrl())
                    .spotifyUrl(user.getSpotifyUrl())
                    .tiktokUrl(user.getTiktokUrl())
                    .isActive(user.getIsActive())
                    .isVerified(user.getIsVerified())
                    .followerIds(user.getFollowerIds())
                    .followingIds(user.getFollowingIds())
                    .createdAt(user.getCreatedAt())
                    .build();
        }

        newUser = userRepository.save(newUser);

        logger.info("User role changed: {} ({}) - {} -> {}",
                    user.getUsername(), user.getEmail(), oldRole, newRole);

        return mapToDTO(newUser);
    }

    /**
     * Cambia el estado de actividad (suspender/reactivar) de una cuenta de usuario.
     *
     * @param userId El ID del usuario.
     * @param isActive El nuevo estado de actividad ({@code true} para activar, {@code false} para suspender).
     * @return El {@link UserDTO} actualizado.
     * @throws RuntimeException si el usuario no se encuentra.
     */
    @Transactional
    public UserDTO changeUserStatus(Long userId, Boolean isActive) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        user.setIsActive(isActive);
        user = userRepository.save(user);

        String action = isActive ? "activated" : "suspended";
        logger.info("User account {}: {} ({})", action, user.getUsername(), user.getEmail());

        return mapToDTO(user);
    }

    /**
     * Obtiene estadísticas resumidas sobre la población de usuarios para el panel de administración.
     *
     * @return Un {@link Map} con las métricas clave (totalUsers, activeUsers, artists, etc.).
     */
    public Map<String, Object> getUserStatistics() {
        List<User> allUsers = userRepository.findAll();

        long totalUsers = allUsers.size();
        long activeUsers = allUsers.stream().filter(User::getIsActive).count();
        long inactiveUsers = totalUsers - activeUsers;
        long verifiedUsers = allUsers.stream().filter(User::getIsVerified).count();

        long regularUsers = allUsers.stream()
                .filter(u -> u.getRole() == UserRole.USER)
                .count();
        long artists = allUsers.stream()
                .filter(u -> u.getRole() == UserRole.ARTIST)
                .count();
        long admins = allUsers.stream()
                .filter(u -> u.getRole() == UserRole.ADMIN)
                .count();

        Map<String, Object> stats = new HashMap<>();
        stats.put("totalUsers", totalUsers);
        stats.put("activeUsers", activeUsers);
        stats.put("inactiveUsers", inactiveUsers);
        stats.put("verifiedUsers", verifiedUsers);
        stats.put("unverifiedUsers", totalUsers - verifiedUsers);
        stats.put("regularUsers", regularUsers);
        stats.put("artists", artists);
        stats.put("admins", admins);

        return stats;
    }

    /**
     * Busca usuarios por una cadena de consulta que coincida con el nombre de usuario, email, nombre o apellido.
     * <p>
     * Nota: Esta implementación realiza la búsqueda en memoria (después de {@code findAll()}). Para bases de datos grandes, se debería migrar a consultas JPQL como las utilizadas para {@code searchArtists}.
     * </p>
     *
     * @param query La cadena de texto de búsqueda.
     * @return Una {@link List} de {@link UserDTO} que coinciden.
     */
    public List<UserDTO> searchUsers(String query) {
        String lowerQuery = query.toLowerCase();
        List<User> allUsers = userRepository.findAll();

        return allUsers.stream()
                .filter(user ->
                    user.getUsername().toLowerCase().contains(lowerQuery) ||
                    user.getEmail().toLowerCase().contains(lowerQuery) ||
                    user.getFirstName().toLowerCase().contains(lowerQuery) ||
                    user.getLastName().toLowerCase().contains(lowerQuery))
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    /**
     * Marca manualmente el correo electrónico de un usuario como verificado (acción de administrador).
     *
     * @param userId El ID del usuario.
     * @return El {@link UserDTO} actualizado.
     * @throws RuntimeException si el usuario no se encuentra.
     */
    @Transactional
    public UserDTO adminVerifyUser(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        user.setIsVerified(true);
        user = userRepository.save(user);

        logger.info("User verified by admin: {} ({})", user.getUsername(), user.getEmail());

        return mapToDTO(user);
    }
    
    /**
     * Marcar el correo electrónico del usuario como verificado (flujo de verificación de email).
     *
     * @param userId El ID del usuario.
     * @return La entidad {@link User} actualizada.
     * @throws RuntimeException si el usuario no se encuentra o ya está verificado.
     */
    @Transactional
    public User verifyEmail(Long userId) {
        // Buscar usuario
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // Verificar que no esté ya verificado
        if (user.getIsVerified()) {
            throw new RuntimeException("Email already verified");
        }

        // Marcar como verificado
        user.setIsVerified(true);
        user = userRepository.save(user);


        logger.info("Email verified successfully for user: {} ({})",
                    user.getUsername(),
                    user.getEmail());

        return user;
    }


    /**
     * Mapea una entidad {@link User} (o subclase {@link Artist}) a su respectivo DTO {@link UserDTO}.
     * <p>
     * Método auxiliar privado. Incluye lógica condicional para copiar campos específicos de {@link Artist}.
     * </p>
     *
     * @param user La entidad {@link User} o {@link Artist} de origen.
     * @return El {@link UserDTO} resultante.
     */
    private UserDTO mapToDTO(User user) {
        logger.info("🔍 mapToDTO called for user: {} (id: {})", user.getUsername(), user.getId());
        logger.info("📱 User Twitter URL from entity: '{}'", user.getTwitterUrl());
        logger.info("📱 User Instagram URL from entity: '{}'", user.getInstagramUrl());

        UserDTO.UserDTOBuilder builder = UserDTO.builder()
                .id(user.getId())
                .email(user.getEmail())
                .username(user.getUsername())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .bio(user.getBio())
                .profileImageUrl(user.getProfileImageUrl())
                .bannerImageUrl(user.getBannerImageUrl())
                .location(user.getLocation())
                .website(user.getWebsite())
                .role(user.getRole())
                .isActive(user.getIsActive())
                .isVerified(user.getIsVerified())
                .followerIds(user.getFollowerIds())
                .followingIds(user.getFollowingIds())
                .createdAt(user.getCreatedAt())
                .updatedAt(user.getUpdatedAt());

        // Add artist-specific fields if user is an artist
        if (user instanceof Artist) {
            Artist artist = (Artist) user;
            // Ensure artistName is never null - fallback to username
            String artistName = artist.getArtistName();
            if (artistName == null || artistName.trim().isEmpty()) {
                artistName = user.getUsername();
            }
            builder.artistName(artistName)
                    .artistBio(artist.getArtistBio())
                    .recordLabel(artist.getRecordLabel())
                    .verifiedArtist(artist.getVerifiedArtist());
        } else if (user.getRole() == UserRole.ARTIST) {
            // Fallback: If role is ARTIST but not instanceof Artist (shouldn't happen but just in case)
            logger.warn("User {} has role ARTIST but is not instanceof Artist class", user.getId());
            builder.artistName(user.getUsername())
                    .verifiedArtist(false);
        }

        // Add social media links
        String twitterUrl = user.getTwitterUrl();
        String instagramUrl = user.getInstagramUrl();
        String facebookUrl = user.getFacebookUrl();
        String youtubeUrl = user.getYoutubeUrl();
        String spotifyUrl = user.getSpotifyUrl();
        String tiktokUrl = user.getTiktokUrl();

        logger.info("🐦 Adding Twitter URL to DTO: '{}'", twitterUrl);

        builder.twitterUrl(twitterUrl)
                .instagramUrl(instagramUrl)
                .facebookUrl(facebookUrl)
                .youtubeUrl(youtubeUrl)
                .spotifyUrl(spotifyUrl)
                .tiktokUrl(tiktokUrl);

        UserDTO dto = builder.build();
        logger.info("✅ DTO built - Twitter URL in DTO: '{}'", dto.getTwitterUrl());
        return dto;
    }
}