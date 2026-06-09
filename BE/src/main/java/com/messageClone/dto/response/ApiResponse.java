package com.messageClone.dto.response;

import lombok.*;
import lombok.experimental.FieldDefaults;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class ApiResponse {
    int code;
    String status;
    String message;
    String data;

    @Builder.Default
    LocalDateTime timestamp =  LocalDateTime.now();
}
