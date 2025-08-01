# 📹 WebRTC Video Call Demo  
**Java Spring Boot (Signaling) + Flutter (UI)**

A lightweight demo of peer-to-peer video calling using **WebRTC**, with:

- 🔌 Java Spring Boot signaling server  
- 📱 Flutter UI using `flutter_webrtc`  
- 🔁 WebSocket-based signaling

---

## ⚙️ Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_webrtc: ^1.0.0
  web_socket_channel: ^3.0.3
```

---

## 🚀 Run the App

### 🔧 Backend (Signaling Server)
```bash
cd webrtc
./mvnw spring-boot:run
```

### 📱 Flutter Client
```bash
cd Webrtc-Flutter
flutter pub get
flutter run
```

---

## 📡 How It Works

- WebSocket for signaling  
- WebRTC for peer connection and media  
- Direct video/audio between 2 peers

---

## 🛠️ Made for learning and experimentation.
