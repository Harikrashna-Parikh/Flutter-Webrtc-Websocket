package com.harikrashna.webrtc.config;

import com.harikrashna.webrtc.service.SocketAsyncService;
import com.harikrashna.webrtc.service.SocketRoomService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Configuration;
import org.springframework.lang.NonNull;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.net.URI;
import java.util.Objects;

@Configuration
@RequiredArgsConstructor
@Slf4j
public class SocketHandler extends TextWebSocketHandler {
    private final SocketAsyncService socketAsyncService;
    private final SocketRoomService roomService;
    public static final String SOCKET_ERROR = "Socket Error: ";

    @Override
    public void afterConnectionEstablished(@NonNull WebSocketSession session) {
        String roomId = extractRoomId(session.getUri());
        session.setTextMessageSizeLimit(1024 * 18);
        roomService.addSessionToRoom(roomId, session);
        socketAsyncService.initializeConnection(session, roomId);
    }

    @Override
    public void handleTextMessage(@NonNull WebSocketSession session, TextMessage message) {
        String roomId = extractRoomId(session.getUri());
        log.info("Received message: {} for room id: {}", message.getPayload(), roomId);
        socketAsyncService.broadcastSignalingMessage(session, roomId, message);
    }

    @Override
    public void afterConnectionClosed(@NonNull WebSocketSession session, @NonNull CloseStatus status) {
        String roomId = extractRoomId(session.getUri());
        roomService.removeSessionFromRoom(roomId, session);
        log.info("Connection closed: {}", status);
    }

    @Override
    public void handleTransportError(@NonNull WebSocketSession session, @NonNull Throwable exception) {
        throw new IllegalArgumentException(SOCKET_ERROR + exception.getMessage(), exception);
    }

    private String extractRoomId(URI uri){
        if(Objects.nonNull(uri)){
            return uri.getPath().split("/")[3];
        } else {
            return "default";
        }
    }
}
