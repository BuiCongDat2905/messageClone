-- ============================================================
-- 🗄️ Database: messageClone
-- 📅 Date: 2026-06-09
-- 🛢️ Engine: MySQL 8+
-- ============================================================

-- Tạo database
CREATE DATABASE IF NOT EXISTS db_messageClone
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE db_messageClone;

-- ============================================================
-- 1. Bảng users (Người dùng)
-- ============================================================
CREATE TABLE users (
    id            BIGINT AUTO_INCREMENT PRIMARY KEY,
    username      VARCHAR(50)  NOT NULL UNIQUE,
    email         VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255),
    display_name  VARCHAR(100),
    avatar_url    VARCHAR(500),
    bio           VARCHAR(255),
    provider      ENUM('LOCAL', 'GOOGLE', 'GITHUB') DEFAULT 'LOCAL',
    provider_id   VARCHAR(100),
    is_online     BOOLEAN DEFAULT FALSE,
    last_seen_at  TIMESTAMP NULL,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_users_username (username),
    INDEX idx_users_email (email),
    INDEX idx_users_provider (provider, provider_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 2. Bảng conversations (Cuộc trò chuyện)
-- ============================================================
CREATE TABLE conversations (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    type            ENUM('PRIVATE', 'GROUP') NOT NULL DEFAULT 'PRIVATE',
    name            VARCHAR(100),
    avatar_url      VARCHAR(500),
    created_by      BIGINT NOT NULL,
    last_message    TEXT,
    last_message_at TIMESTAMP NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id),
    INDEX idx_conv_updated (updated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 3. Bảng conversation_participants (Thành viên cuộc trò chuyện)
-- ============================================================
CREATE TABLE conversation_participants (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    conversation_id BIGINT NOT NULL,
    user_id         BIGINT NOT NULL,
    role            ENUM('MEMBER', 'ADMIN') DEFAULT 'MEMBER',
    nickname        VARCHAR(100),
    muted           BOOLEAN DEFAULT FALSE,
    joined_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    left_at         TIMESTAMP NULL,
    UNIQUE KEY uk_conv_user (conversation_id, user_id),
    FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_cp_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 4. Bảng messages (Tin nhắn)
-- ============================================================
CREATE TABLE messages (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    conversation_id BIGINT NOT NULL,
    sender_id       BIGINT NOT NULL,
    content         TEXT,
    message_type    ENUM('TEXT', 'IMAGE', 'FILE', 'VIDEO') DEFAULT 'TEXT',
    file_url        VARCHAR(500),
    reply_to        BIGINT NULL,
    is_edited       BOOLEAN DEFAULT FALSE,
    is_deleted      BOOLEAN DEFAULT FALSE,
    sent_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    edited_at       TIMESTAMP NULL,
    FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES users(id),
    FOREIGN KEY (reply_to) REFERENCES messages(id),
    INDEX idx_msg_conv (conversation_id, sent_at),
    INDEX idx_msg_sender (sender_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 5. Bảng message_reads (Đánh dấu đã đọc)
-- ============================================================
CREATE TABLE message_reads (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    message_id  BIGINT NOT NULL,
    user_id     BIGINT NOT NULL,
    read_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_msg_user (message_id, user_id),
    FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_mr_message (message_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 6. Bảng refresh_tokens (JWT Refresh Token)
-- ============================================================
CREATE TABLE refresh_tokens (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id     BIGINT NOT NULL,
    token       VARCHAR(500) NOT NULL UNIQUE,
    expires_at  TIMESTAMP NOT NULL,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_rt_token (token),
    INDEX idx_rt_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 7. Bảng friend_requests (Lời mời kết bạn)
-- ============================================================
CREATE TABLE friend_requests (
    id           BIGINT AUTO_INCREMENT PRIMARY KEY,
    sender_id    BIGINT NOT NULL,
    receiver_id  BIGINT NOT NULL,
    status       ENUM('PENDING', 'ACCEPTED', 'REJECTED', 'CANCELLED') DEFAULT 'PENDING',
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    responded_at TIMESTAMP NULL,
    UNIQUE KEY uk_fr_sender_receiver (sender_id, receiver_id),
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_fr_receiver (receiver_id, status),
    INDEX idx_fr_sender (sender_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 8. Bảng friendships (Danh sách bạn bè)
-- ============================================================
CREATE TABLE friendships (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id     BIGINT NOT NULL,
    friend_id   BIGINT NOT NULL,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_friendship (user_id, friend_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (friend_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_friend_user (user_id),
    INDEX idx_friend_friend (friend_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 9. Bảng notifications (Thông báo in-app)
-- ============================================================
CREATE TABLE notifications (
    id           BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id      BIGINT NOT NULL,
    type         ENUM('NEW_MESSAGE', 'FRIEND_REQUEST', 'FRIEND_ACCEPTED',
                      'GROUP_INVITE', 'SYSTEM') NOT NULL,
    title        VARCHAR(255) NOT NULL,
    content      VARCHAR(500),
    reference_id VARCHAR(100),
    is_read      BOOLEAN DEFAULT FALSE,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_noti_user (user_id, is_read, created_at),
    INDEX idx_noti_type (user_id, type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- ✅ Done!
-- ============================================================
