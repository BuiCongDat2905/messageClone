package com.messageClone.entity;

import com.messageClone.enums.MessageType;
import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldDefaults;

import java.time.LocalDateTime;

@Entity
@Table(name = "messages")
@Builder
@Setter
@Getter
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class Message{
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "conversation_id", nullable = false)
    Conversation conversation;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sender_id", nullable = false)
    Users sender;

    @Column(columnDefinition = "TEXT")
    String content;

    @Enumerated(EnumType.STRING)
    @Column(name = "message_type", nullable = false)
    @Builder.Default
    MessageType messageType = MessageType.TEXT;

    @Column(name = "file_url", length = 500)
    String fileUrl;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "reply_to")
    Message replyTo;

    @Column(name = "is_edited")
    @Builder.Default
    Boolean isEdited = false;

    @Column(name = "is_deleted")
    @Builder.Default
    Boolean isDeleted = false;

    @Column(name = "sent_at")
    @Builder.Default
    LocalDateTime sentAt = LocalDateTime.now();

    @Column(name = "edited_at")
    LocalDateTime editedAt;
}