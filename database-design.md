# 🗄️ Database Design – Web Chat Application

> **Version:** 1.0 — Draft  
> **Date:** 2026-06-08  
> **Stack:** MySQL 8 + Spring Boot 3.2 (JPA/Hibernate) + React (Vite)

---

## 1. Tổng quan

Ứng dụng web chat real-time, hỗ trợ:
- ✅ Chat 1-1 (Private) & Chat nhóm (Group)
- ✅ Gửi text, ảnh, file, video
- ✅ Xác thực: JWT (username/password) + OAuth2 (Google, GitHub)
- ✅ Trạng thái Online/Offline
- ✅ Đánh dấu đã đọc (Read Receipt)
- ✅ Trả lời tin nhắn (Reply)
- ✅ Upload file lên Cloud Storage (AWS S3 / Cloudinary)
- ✅ Kết bạn & Danh sách bạn bè (Friend Request / Friendship)
- ✅ Thông báo in-app (tin nhắn mới, lời mời kết bạn...)
- ✅ Phân trang tin nhắn (50 msg/trang)

---

## 2. ER Diagram

```
┌──────────────┐       ┌────────────────────────┐       ┌──────────────┐
│    users     │       │conversation_participants│       │ conversations│
├──────────────┤       ├────────────────────────┤       ├──────────────┤
│ id (PK)      │──┐    │ id (PK)                │    ┌──│ id (PK)      │
│ username     │  │    │ conversation_id (FK)   │────┘  │ type         │
│ email        │  ├───▶│ user_id (FK)           │       │ name         │
│ password_hash│  │    │ role                   │       │ avatar_url   │
│ display_name │  │    │ muted                  │       │ created_by   │
│ avatar_url   │  │    │ joined_at              │       │ last_message │
│ provider     │  │    └────────────────────────┘       │ created_at   │
│ provider_id  │  │                                     └──────────────┘
│ is_online    │  │
│ last_seen_at │  │
└──────────────┘  │
                  │    ┌──────────────┐       ┌──────────────┐
                  │    │   messages   │       │ message_reads│
                  │    ├──────────────┤       ├──────────────┤
                  └───▶│ id (PK)      │──┐    │ id (PK)      │
                       │ conversation │  │    │ message_id   │◀──┐
                       │ sender_id    │  ├───▶│ user_id      │   │
                       │ content      │  │    │ read_at      │   │
                       │ message_type │  │    └──────────────┘   │
                       │ file_url     │  │                       │
                       │ reply_to     │──┘ (self-ref)            │
                       │ is_edited    │                          │
                       │ is_deleted   │                          │
                       │ sent_at      │                          │
                       └──────────────┘                          │
                                                                 │
  ┌─────────────────┐     ┌─────────────────┐                    │
  │ friend_requests │     │   friendships   │                    │
  ├─────────────────┤     ├─────────────────┤                    │
  │ id (PK)         │     │ id (PK)         │                    │
  │ sender_id (FK)  │────▶│ user_id (FK)    │────────────────────┤
  │ receiver_id(FK) │     │ friend_id (FK)  │────────────────────┘
  │ status          │     │ created_at      │
  │ created_at      │     └─────────────────┘
  │ responded_at    │
  └─────────────────┘
                       ┌──────────────┐
                       │refresh_tokens│
                       ├──────────────┤
                       │ id (PK)      │
                       │ user_id (FK) │
                       │ token        │
                       │ expires_at   │
                       └──────────────┘
  ┌─────────────────┐
  │  notifications  │
  ├─────────────────┤
  │ id (PK)         │
  │ user_id (FK)────│──┐
  │ type            │  │
  │ title           │  │
  │ content         │  │
  │ reference_id    │  │
  │ is_read         │  │
  │ created_at      │  │
  └─────────────────┘  │
                       │
  ┌─────────────────┐  │
  │ friend_requests │  │
  ├─────────────────┤  │
  │ id (PK)         │  │
  │ sender_id (FK)──┤──┤
  │ receiver_id(FK)─┤──┤
  │ status          │  │
  │ created_at      │  │
  │ responded_at    │  │
  └─────────────────┘  │
                       │
  ┌─────────────────┐  │
  │   friendships   │  │
  ├─────────────────┤  │
  │ id (PK)         │  │
  │ user_id (FK)────┤──┤
  │ friend_id (FK)──┤──┘
  │ created_at      │
  └─────────────────┘
```

---

## 3. Chi tiết từng bảng

### 3.1. `users` — Người dùng

| # | Cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|-----|-------------|-----------|-------|
| 1 | `id` | `BIGINT` | PK, AUTO_INCREMENT | ID người dùng |
| 2 | `username` | `VARCHAR(50)` | NOT NULL, UNIQUE | Tên đăng nhập |
| 3 | `email` | `VARCHAR(100)` | NOT NULL, UNIQUE | Email |
| 4 | `password_hash` | `VARCHAR(255)` | NULLABLE | Mã hóa BCrypt (NULL nếu OAuth) |
| 5 | `display_name` | `VARCHAR(100)` | NULLABLE | Tên hiển thị |
| 6 | `avatar_url` | `VARCHAR(500)` | NULLABLE | Link ảnh đại diện |
| 7 | `bio` | `VARCHAR(255)` | NULLABLE | Giới thiệu ngắn |
| 8 | `provider` | `ENUM('LOCAL','GOOGLE','GITHUB')` | DEFAULT 'LOCAL' | Nguồn đăng nhập |
| 9 | `provider_id` | `VARCHAR(100)` | NULLABLE | ID từ OAuth provider |
| 10 | `is_online` | `BOOLEAN` | DEFAULT FALSE | Đang online? |
| 11 | `last_seen_at` | `TIMESTAMP` | NULLABLE | Lần cuối hoạt động |
| 12 | `created_at` | `TIMESTAMP` | DEFAULT NOW() | Ngày tạo |
| 13 | `updated_at` | `TIMESTAMP` | ON UPDATE NOW() | Ngày cập nhật |

**Indexes:** `idx_users_username`, `idx_users_email`, `idx_users_provider`

```sql
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
);
```

---

### 3.2. `conversations` — Cuộc trò chuyện

| # | Cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|-----|-------------|-----------|-------|
| 1 | `id` | `BIGINT` | PK, AUTO_INCREMENT | ID cuộc trò chuyện |
| 2 | `type` | `ENUM('PRIVATE','GROUP')` | DEFAULT 'PRIVATE' | Loại chat |
| 3 | `name` | `VARCHAR(100)` | NULLABLE | Tên nhóm (NULL nếu PRIVATE) |
| 4 | `avatar_url` | `VARCHAR(500)` | NULLABLE | Ảnh đại diện nhóm |
| 5 | `created_by` | `BIGINT` | FK → users.id | Người tạo |
| 6 | `last_message` | `TEXT` | NULLABLE | Preview tin nhắn cuối |
| 7 | `last_message_at` | `TIMESTAMP` | NULLABLE | Thời gian tin nhắn cuối |
| 8 | `created_at` | `TIMESTAMP` | DEFAULT NOW() | Ngày tạo |
| 9 | `updated_at` | `TIMESTAMP` | ON UPDATE NOW() | Ngày cập nhật |

```sql
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
);
```

---

### 3.3. `conversation_participants` — Thành viên nhóm

| # | Cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|-----|-------------|-----------|-------|
| 1 | `id` | `BIGINT` | PK, AUTO_INCREMENT | ID |
| 2 | `conversation_id` | `BIGINT` | FK → conversations.id | Cuộc trò chuyện |
| 3 | `user_id` | `BIGINT` | FK → users.id | Người dùng |
| 4 | `role` | `ENUM('MEMBER','ADMIN')` | DEFAULT 'MEMBER' | Vai trò |
| 5 | `nickname` | `VARCHAR(100)` | NULLABLE | Biệt danh trong nhóm |
| 6 | `muted` | `BOOLEAN` | DEFAULT FALSE | Tắt thông báo? |
| 7 | `joined_at` | `TIMESTAMP` | DEFAULT NOW() | Ngày tham gia |
| 8 | `left_at` | `TIMESTAMP` | NULLABLE | Ngày rời nhóm |

**Unique:** `(conversation_id, user_id)` — mỗi user chỉ join 1 lần/group

```sql
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
);
```

---

### 3.4. `messages` — Tin nhắn

| # | Cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|-----|-------------|-----------|-------|
| 1 | `id` | `BIGINT` | PK, AUTO_INCREMENT | ID tin nhắn |
| 2 | `conversation_id` | `BIGINT` | FK → conversations.id | Thuộc cuộc trò chuyện nào |
| 3 | `sender_id` | `BIGINT` | FK → users.id | Người gửi |
| 4 | `content` | `TEXT` | NULLABLE | Nội dung text |
| 5 | `message_type` | `ENUM('TEXT','IMAGE','FILE','VIDEO')` | DEFAULT 'TEXT' | Loại tin nhắn |
| 6 | `file_url` | `VARCHAR(500)` | NULLABLE | Link file đính kèm |
| 7 | `reply_to` | `BIGINT` | FK → messages.id, NULLABLE | Trả lời tin nhắn nào |
| 8 | `is_edited` | `BOOLEAN` | DEFAULT FALSE | Đã chỉnh sửa? |
| 9 | `is_deleted` | `BOOLEAN` | DEFAULT FALSE | Đã xóa? (soft delete) |
| 10 | `sent_at` | `TIMESTAMP` | DEFAULT NOW() | Thời gian gửi |
| 11 | `edited_at` | `TIMESTAMP` | NULLABLE | Thời gian chỉnh sửa |

```sql
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
);
```

---

### 3.5. `message_reads` — Đánh dấu đã đọc

| # | Cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|-----|-------------|-----------|-------|
| 1 | `id` | `BIGINT` | PK, AUTO_INCREMENT | ID |
| 2 | `message_id` | `BIGINT` | FK → messages.id | Tin nhắn |
| 3 | `user_id` | `BIGINT` | FK → users.id | Ai đã đọc |
| 4 | `read_at` | `TIMESTAMP` | DEFAULT NOW() | Thời gian đọc |

**Unique:** `(message_id, user_id)` — mỗi user chỉ đọc 1 lần/message

```sql
CREATE TABLE message_reads (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    message_id  BIGINT NOT NULL,
    user_id     BIGINT NOT NULL,
    read_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_msg_user (message_id, user_id),
    FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_mr_message (message_id)
);
```

---

### 3.6. `refresh_tokens` — JWT Refresh Token

| # | Cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|-----|-------------|-----------|-------|
| 1 | `id` | `BIGINT` | PK, AUTO_INCREMENT | ID |
| 2 | `user_id` | `BIGINT` | FK → users.id | Người dùng |
| 3 | `token` | `VARCHAR(500)` | NOT NULL, UNIQUE | Refresh token |
| 4 | `expires_at` | `TIMESTAMP` | NOT NULL | Hết hạn |
| 5 | `created_at` | `TIMESTAMP` | DEFAULT NOW() | Ngày tạo |

```sql
CREATE TABLE refresh_tokens (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id     BIGINT NOT NULL,
    token       VARCHAR(500) NOT NULL UNIQUE,
    expires_at  TIMESTAMP NOT NULL,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_rt_token (token),
    INDEX idx_rt_user (user_id)
);
```

---

### 3.7. `friend_requests` — Lời mời kết bạn

| # | Cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|-----|-------------|-----------|-------|
| 1 | `id` | `BIGINT` | PK, AUTO_INCREMENT | ID |
| 2 | `sender_id` | `BIGINT` | FK → users.id | Người gửi lời mời |
| 3 | `receiver_id` | `BIGINT` | FK → users.id | Người nhận lời mời |
| 4 | `status` | `ENUM('PENDING','ACCEPTED','REJECTED','CANCELLED')` | DEFAULT 'PENDING' | Trạng thái |
| 5 | `created_at` | `TIMESTAMP` | DEFAULT NOW() | Ngày gửi |
| 6 | `responded_at` | `TIMESTAMP` | NULLABLE | Ngày phản hồi |

**Unique:** `(sender_id, receiver_id)` — không gửi trùng lời mời  
**Check:** `sender_id != receiver_id` — không tự kết bạn với chính mình

```sql
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
);
```

**Luồng kết bạn:**
1. User A gửi lời mời → `status = PENDING`
2. User B chấp nhận → `status = ACCEPTED`, đồng thời INSERT vào `friendships`
3. User B từ chối → `status = REJECTED`
4. User A hủy lời mời → `status = CANCELLED`

---

### 3.8. `friendships` — Danh sách bạn bè

| # | Cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|-----|-------------|-----------|-------|
| 1 | `id` | `BIGINT` | PK, AUTO_INCREMENT | ID |
| 2 | `user_id` | `BIGINT` | FK → users.id | User |
| 3 | `friend_id` | `BIGINT` | FK → users.id | Bạn của user |
| 4 | `created_at` | `TIMESTAMP` | DEFAULT NOW() | Ngày kết bạn |

**Unique:** `(user_id, friend_id)`  
**Index:** `(user_id)` và `(friend_id)` để tra nhanh danh sách bạn

```sql
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
);
```

> **Ghi chú:** Khi chấp nhận kết bạn, INSERT 2 dòng: `(A, B)` và `(B, A)` để truy vấn 2 chiều dễ dàng.  
> Khi hủy kết bạn (unfriend), DELETE cả 2 dòng.

---

### 3.9. `notifications` — Thông báo in-app

| # | Cột | Kiểu dữ liệu | Ràng buộc | Mô tả |
|---|-----|-------------|-----------|-------|
| 1 | `id` | `BIGINT` | PK, AUTO_INCREMENT | ID |
| 2 | `user_id` | `BIGINT` | FK → users.id | Người nhận thông báo |
| 3 | `type` | `ENUM('NEW_MESSAGE','FRIEND_REQUEST','FRIEND_ACCEPTED','GROUP_INVITE','SYSTEM')` | NOT NULL | Loại thông báo |
| 4 | `title` | `VARCHAR(255)` | NOT NULL | Tiêu đề |
| 5 | `content` | `VARCHAR(500)` | NULLABLE | Nội dung |
| 6 | `reference_id` | `VARCHAR(100)` | NULLABLE | ID tham chiếu (conversationId, requestId...) |
| 7 | `is_read` | `BOOLEAN` | DEFAULT FALSE | Đã đọc? |
| 8 | `created_at` | `TIMESTAMP` | DEFAULT NOW() | Ngày tạo |

```sql
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
);
```

> **Khi nào tạo notification?**
> - Có tin nhắn mới → `NEW_MESSAGE` (reference_id = conversationId)
> - Có lời mời kết bạn → `FRIEND_REQUEST` (reference_id = requestId)
> - Lời mời được chấp nhận → `FRIEND_ACCEPTED` (reference_id = userId)
> - Được mời vào nhóm → `GROUP_INVITE` (reference_id = conversationId)

---

## 4. Mối quan hệ giữa các bảng

| Quan hệ | Mô tả |
|---------|-------|
| **users** 1→N **messages** | Một user gửi nhiều tin nhắn |
| **users** 1→N **conversation_participants** | Một user tham gia nhiều cuộc trò chuyện |
| **users** 1→N **refresh_tokens** | Một user có nhiều refresh token (đa thiết bị) |
| **users** 1→N **friend_requests** (sender) | Một user gửi nhiều lời mời kết bạn |
| **users** 1→N **friend_requests** (receiver) | Một user nhận nhiều lời mời kết bạn |
| **users** 1→N **friendships** | Một user có nhiều bạn bè |
| **users** 1→N **notifications** | Một user nhận nhiều thông báo |
| **conversations** 1→N **messages** | Một cuộc trò chuyện chứa nhiều tin nhắn |
| **conversations** 1→N **conversation_participants** | Một cuộc trò chuyện có nhiều thành viên |
| **messages** 1→N **message_reads** | Một tin nhắn được đọc bởi nhiều người |
| **messages** 1→1 **messages** (reply_to) | Một tin nhắn có thể trả lời 1 tin nhắn khác |

---

## 5. Mapping tính năng → Bảng

| Tính năng | Bảng liên quan | Ghi chú |
|-----------|---------------|---------|
| Đăng ký / Đăng nhập (JWT) | `users`, `refresh_tokens` | password_hash + token |
| Đăng nhập Google/GitHub | `users` | provider + provider_id |
| Chat 1-1 | `conversations`, `conversation_participants` | type='PRIVATE', 2 participants |
| Chat nhóm | `conversations`, `conversation_participants` | type='GROUP', name != NULL |
| Gửi tin nhắn text | `messages` | message_type='TEXT' |
| Gửi ảnh / file / video | `messages` | message_type + file_url |
| Trả lời tin nhắn | `messages` | reply_to → messages.id |
| Sửa tin nhắn | `messages` | is_edited + edited_at |
| Xóa tin nhắn | `messages` | is_deleted (soft delete) |
| Đánh dấu đã đọc | `message_reads` | insert khi user đọc |
| Online/Offline | `users` | is_online + last_seen_at |
| Tắt thông báo nhóm | `conversation_participants` | muted = true |
| Danh sách chat | `conversations` + `conversation_participants` | JOIN để lấy |
| Gửi lời mời kết bạn | `friend_requests` | INSERT status=PENDING |
| Chấp nhận / Từ chối kết bạn | `friend_requests` + `friendships` | UPDATE status + INSERT friendships |
| Hủy kết bạn (Unfriend) | `friendships` + `friend_requests` | DELETE cả 2 dòng |
| Danh sách bạn bè | `friendships` | SELECT WHERE user_id = ? |
| Danh sách lời mời đã nhận | `friend_requests` | WHERE receiver_id = ? AND status = 'PENDING' |
| Danh sách lời mời đã gửi | `friend_requests` | WHERE sender_id = ? AND status = 'PENDING' |
| Thông báo tin nhắn mới | `notifications` | INSERT khi có message mới |
| Thông báo lời mời kết bạn | `notifications` | INSERT khi có friend request |
| Danh sách thông báo | `notifications` | SELECT WHERE user_id = ? |
| Đánh dấu thông báo đã đọc | `notifications` | UPDATE is_read = true |
| Số thông báo chưa đọc (badge) | `notifications` | SELECT COUNT WHERE is_read = false |

---

## 6. Dự kiến API Endpoints

### Auth
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| POST | `/api/auth/register` | Đăng ký |
| POST | `/api/auth/login` | Đăng nhập → trả JWT |
| POST | `/api/auth/refresh` | Refresh token |
| GET | `/api/auth/me` | Lấy thông tin user hiện tại |

### Users
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | `/api/users` | Tìm kiếm user |
| GET | `/api/users/{id}` | Lấy thông tin user |
| PUT | `/api/users/me` | Cập nhật profile |
| PUT | `/api/users/me/avatar` | Upload avatar |

### Friends
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| POST | `/api/friends/request/{userId}` | Gửi lời mời kết bạn |
| PUT | `/api/friends/accept/{requestId}` | Chấp nhận lời mời |
| PUT | `/api/friends/reject/{requestId}` | Từ chối lời mời |
| DELETE | `/api/friends/cancel/{requestId}` | Hủy lời mời đã gửi |
| DELETE | `/api/friends/unfriend/{userId}` | Hủy kết bạn |
| GET | `/api/friends` | Danh sách bạn bè |
| GET | `/api/friends/requests/received` | Lời mời đã nhận (đang chờ) |
| GET | `/api/friends/requests/sent` | Lời mời đã gửi (đang chờ) |
| GET | `/api/friends/status/{userId}` | Kiểm tra trạng thái với 1 user |

### Notifications
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | `/api/notifications` | Danh sách thông báo (phân trang) |
| GET | `/api/notifications/unread-count` | Số thông báo chưa đọc |
| PUT | `/api/notifications/{id}/read` | Đánh dấu 1 thông báo đã đọc |
| PUT | `/api/notifications/read-all` | Đánh dấu tất cả đã đọc |
| DELETE | `/api/notifications/{id}` | Xóa 1 thông báo |

### Conversations
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | `/api/conversations` | Danh sách cuộc trò chuyện của tôi |
| POST | `/api/conversations/private` | Tạo chat 1-1 |
| POST | `/api/conversations/group` | Tạo chat nhóm |
| GET | `/api/conversations/{id}` | Chi tiết cuộc trò chuyện |
| PUT | `/api/conversations/{id}` | Cập nhật nhóm (tên, avatar) |
| POST | `/api/conversations/{id}/members` | Thêm thành viên |
| DELETE | `/api/conversations/{id}/members/{userId}` | Xóa thành viên |
| POST | `/api/conversations/{id}/leave` | Rời nhóm |

### Messages
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | `/api/conversations/{id}/messages` | Lấy tin nhắn (phân trang) |
| POST | `/api/conversations/{id}/messages` | Gửi tin nhắn text |
| POST | `/api/conversations/{id}/messages/upload` | Gửi file/ảnh |
| PUT | `/api/messages/{id}` | Sửa tin nhắn |
| DELETE | `/api/messages/{id}` | Xóa tin nhắn |
| POST | `/api/messages/{id}/read` | Đánh dấu đã đọc |

---

## 7. Dự kiến WebSocket Events

### Server → Client
| Event | Payload | Mô tả |
|-------|---------|-------|
| `NEW_MESSAGE` | `{messageId, conversationId, sender, content, type, fileUrl, sentAt}` | Có tin nhắn mới |
| `MESSAGE_UPDATED` | `{messageId, newContent, editedAt}` | Tin nhắn bị sửa |
| `MESSAGE_DELETED` | `{messageId, conversationId}` | Tin nhắn bị xóa |
| `USER_ONLINE` | `{userId}` | User vừa online |
| `USER_OFFLINE` | `{userId, lastSeenAt}` | User vừa offline |
| `READ_RECEIPT` | `{messageId, userId, readAt}` | User đã đọc tin nhắn |
| `USER_TYPING` | `{conversationId, userId}` | User đang nhập... |
| `USER_STOP_TYPING` | `{conversationId, userId}` | User ngừng nhập |
| `FRIEND_REQUEST` | `{requestId, sender: {id, username, avatar}}` | Có lời mời kết bạn mới |
| `FRIEND_ACCEPTED` | `{userId, friend: {id, username, avatar}}` | Lời mời được chấp nhận |
| `FRIEND_ONLINE` | `{userId}` | Bạn bè vừa online |
| `FRIEND_OFFLINE` | `{userId, lastSeenAt}` | Bạn bè vừa offline |
| `NEW_NOTIFICATION` | `{id, type, title, content, referenceId, createdAt}` | Có thông báo mới |
| `UNREAD_COUNT` | `{count}` | Cập nhật số thông báo chưa đọc |

### Client → Server
| Event | Payload | Mô tả |
|-------|---------|-------|
| `TYPING` | `{conversationId}` | Tôi đang nhập |
| `STOP_TYPING` | `{conversationId}` | Tôi ngừng nhập |
| `MARK_READ` | `{conversationId}` | Đánh dấu tất cả đã đọc |

---

## 8. Quyết định thiết kế (ĐÃ CHỐT)

| # | Vấn đề | Quyết định |
|---|--------|------------|
| 1 | **File upload** | ☁️ **Cloud Storage** (AWS S3 / Cloudinary) |
| 2 | **Thông báo** | 🌐 **In-app only** (chỉ hiển thị khi user đang hoạt động trên web) |
| 3 | **Gọi video/audio** | ❌ **Không cần** ở giai đoạn này |
| 4 | **Phân trang** | ✅ Có — **50 tin nhắn/trang**, scroll lên load thêm |
| 5 | **Database** | 🐬 **MySQL 8** |

---

## 9. Tổng kết Schema

| # | Bảng | Số cột | Mô tả |
|---|------|--------|-------|
| 1 | `users` | 13 | Người dùng + auth (JWT/OAuth) |
| 2 | `conversations` | 9 | Cuộc trò chuyện (Private/Group) |
| 3 | `conversation_participants` | 8 | Thành viên trong nhóm |
| 4 | `messages` | 11 | Tin nhắn (text/ảnh/file/video) |
| 5 | `message_reads` | 4 | Đánh dấu đã đọc |
| 6 | `refresh_tokens` | 5 | JWT refresh token |
| 7 | `friend_requests` | 6 | Lời mời kết bạn |
| 8 | `friendships` | 4 | Danh sách bạn bè |
| 9 | `notifications` | 8 | Thông báo in-app |

> **Tổng: 9 bảng, ~34 API endpoints, 14 WebSocket events**
> 
> 🚀 **Sẵn sàng để bắt đầu code!**

---

> *File này lưu tại: `d:\Work\MessageClone\database-design.md`*
