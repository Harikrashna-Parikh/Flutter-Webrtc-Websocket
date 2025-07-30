package com.harikrashna.webrtc.service;

import org.springframework.stereotype.Service;
import org.springframework.web.socket.WebSocketSession;

import java.util.Objects;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

@Service
public class SocketRoomService {

    private final ConcurrentMap<String, ConcurrentMap<String, WebSocketSession>> rooms = new ConcurrentHashMap<>();

    public void addSessionToRoom(String roomId, WebSocketSession session) {
        rooms.computeIfAbsent(roomId, k -> new ConcurrentHashMap<>()).put(session.getId(), session);
    }

    public void removeSessionFromRoom(String roomId, WebSocketSession session) {
        ConcurrentMap<String, WebSocketSession> roomSessions = rooms.get(roomId);
        if(Objects.nonNull(roomSessions) && !roomSessions.isEmpty()){
            roomSessions.remove(session.getId());
            if (roomSessions.isEmpty()){
                rooms.remove(roomId);
            }
        }
    }

    public ConcurrentMap<String, WebSocketSession> getRoomSessions(String roomId) {
        return rooms.get(roomId);
    }
}
