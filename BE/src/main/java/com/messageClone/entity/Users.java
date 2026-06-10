package com.messageClone.entity;

import com.messageClone.enums.Provider;
import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldDefaults;

import java.time.LocalDateTime;

@Entity
@Table(name = "users")
@Builder
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class Users extends BaseEntity {
    // ===== Convenience getters/setters if needed =====
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    Long id;

    @Column(length = 50, nullable = false, unique = true)
    String username;

    @Column(length = 100, nullable = false, unique = true)
    String email;

    @Column(name = "password_hash", length = 255)
    String passwordHash;

    @Column(name = "display_name", length = 100)
    String displayName;

    @Column(name = "avatar_url", length = 500)
    String avatarUrl;

    @Column(length = 255)
    String bio;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    Provider provider = Provider.LOCAL;

    @Column(name = "provider_id", length = 100)
    String providerId;

    @Column(name = "is_online")
    @Builder.Default
    Boolean isOnline = false;

    @Column(name = "last_seen_at")
    LocalDateTime lastSeenAt;

}
