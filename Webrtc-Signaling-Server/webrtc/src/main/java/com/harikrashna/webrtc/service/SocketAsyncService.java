package com.harikrashna.webrtc.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;

import java.io.IOException;
import java.util.Map;
import java.util.Objects;
import java.util.concurrent.ConcurrentMap;

import static com.harikrashna.webrtc.config.SocketHandler.SOCKET_ERROR;

@RequiredArgsConstructor
@Slf4j
@Service
public class SocketAsyncService {
    private  final SocketRoomService socketRoomService;

    @Async
    public void initializeConnection(WebSocketSession session, String roomId) {
        log.info("Initialized connection for room {} and session {}", roomId, session.getId());
    }

    @Async
    public void broadcastSignalingMessage(WebSocketSession senderSession, String roomId, TextMessage message) {
        ConcurrentMap<String, WebSocketSession> roomSessions = socketRoomService.getRoomSessions(roomId);

        if (Objects.nonNull(roomSessions) && !roomSessions.isEmpty()) {
            for (Map.Entry<String, WebSocketSession> entry : roomSessions.entrySet()) {
                WebSocketSession session = entry.getValue();
                if (!session.getId().equals(senderSession.getId())) {
                    try {
                        session.sendMessage(new TextMessage(message.getPayload()));
                    } catch (IOException e) {
                        throw new IllegalArgumentException(SOCKET_ERROR + e.getMessage(), e);
                    }
                }
            }
        }
    }

}
