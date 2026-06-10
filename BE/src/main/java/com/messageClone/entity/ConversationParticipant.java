package com.messageClone.entity;

import com.messageClone.enums.ParticipantRole;
import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldDefaults;

import java.time.LocalDateTime;

@Entity
@Table(name = "conversation_participants",
       uniqueConstraints = @UniqueConstraint(columnNames = {"conversation_id", "user_id"}))
@Builder
@Setter
@Getter
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class ConversationParticipant{
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "conversation_id", nullable = false)
    Conversation conversation;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    Users user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    ParticipantRole role = ParticipantRole.MEMBER;

    @Column(length = 100)
    String nickname;

    @Builder.Default
    Boolean muted = false;

    @Column(name = "joined_at")
    @Builder.Default
    LocalDateTime joinedAt = LocalDateTime.now();

    @Column(name = "left_at")
    LocalDateTime leftAt;
}