package com.harikrashna.webrtc.config;
import com.harikrashna.webrtc.service.SocketAsyncService;
import com.harikrashna.webrtc.service.SocketRoomService;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;


@EnableWebSocket
@RequiredArgsConstructor
@Configuration
public class WebSocketConfig implements WebSocketConfigurer {
    private final SocketAsyncService socketAsyncService;
    private final SocketRoomService roomService;

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(new SocketHandler(socketAsyncService, roomService),
                        "/api/videochat/{roomId}");
    }
}
