import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:videoconferencing/peer_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController textEditingController = TextEditingController();
  final PeerService peerServiceInstance = PeerService();
  late WebSocketChannel channel;
  String recieved = "Waiting for connection...";
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    initCamera();
    connectSocket();
    peerServiceInstance.initializePeer();
    peerServiceInstance.peer?.onAddStream = (MediaStream stream) {
      setState(() {
        _remoteRenderer.srcObject = stream;
      });
    };
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    peerServiceInstance.closePeer();
    super.dispose();
  }

  Future<void> initCamera() async {
    // Initialize the local renderer
    await _localRenderer.initialize();

    // Get the local media stream (video + audio)
    MediaStream stream = await navigator.mediaDevices.getUserMedia({
      'video': true,
      'audio': true,
    });

    // Set the local renderer's stream once it is initialized
    setState(() {
      _localRenderer.srcObject = stream;
    });

    // Add tracks from the stream to the peer connection
    stream.getTracks().forEach((track) {
      peerServiceInstance.peer?.addTrack(track, stream);
    });

    // Set up the remote stream renderer
    peerServiceInstance.peer?.onTrack = (RTCTrackEvent event) async {
      if (event.streams.isNotEmpty) {
        await _remoteRenderer.initialize();
        setState(() {
          _remoteRenderer.srcObject = event.streams[0];
        });
      }
    };
  }

  void connectSocket() async {
    final url = Uri.parse('ws://192.1.150.112:8082/api/videochat/efd6fea9-fa56-4c01-bbe4-0853e40c1866');
    channel = WebSocketChannel.connect(url);

    channel.stream.listen((message) {
      handleSignalingMessage(message);
    });
  }

  void handleSignalingMessage(dynamic message) async {
    Map<String, dynamic> decodedMessage = jsonDecode(message);

    if (decodedMessage['type'] == "offer") {
      final RTCSessionDescription offer = RTCSessionDescription(decodedMessage["sdp"], decodedMessage["type"]);
      final RTCSessionDescription? answer = await peerServiceInstance.getAnswer(offer);
      channel.sink.add(jsonEncode(answer?.toMap()));

      while (peerServiceInstance.getIceCandidate() != null) {
        final IceCandidateWrapper localIceCandidate = IceCandidateWrapper(candidate: peerServiceInstance.localIceCandidate);
        channel.sink.add(jsonEncode(localIceCandidate.toMap()));
        break;
      }
    } else if (decodedMessage['type'] == "answer") {
      final RTCSessionDescription answer = RTCSessionDescription(decodedMessage["sdp"], decodedMessage["type"]);
      peerServiceInstance.peer?.setRemoteDescription(answer);
    } else if (decodedMessage['type'] == "candidate") {
      final candidate = RTCIceCandidate(decodedMessage['candidate']['candidate'],
          decodedMessage['candidate']['sdpMid'], decodedMessage['candidate']['sdpMLineIndex']);
      peerServiceInstance.peer?.addCandidate(candidate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final text = textEditingController.text;
          channel.sink.add(text);
        },
        child: Icon(Icons.send),
      ),
      appBar: AppBar(
        title: Text("Home Page"),
      ),
      body: Column(
        children: [
          TextField(
            controller: textEditingController,
            decoration: InputDecoration(labelText: 'Send a message'),
          ),
          Text(recieved),
          SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              initCamera();
              final offer = await peerServiceInstance.getOffer();
              channel.sink.add(jsonEncode(offer?.toMap()));

              while (peerServiceInstance.getIceCandidate() != null) {
                final IceCandidateWrapper localIceCandidate = IceCandidateWrapper(candidate: peerServiceInstance.localIceCandidate);
                channel.sink.add(jsonEncode(localIceCandidate.toMap()));
                break;
              }
            },
            child: Text("Start Video Call"),
          ),
          Expanded(child: RTCVideoView(_localRenderer)),
          Expanded(child: RTCVideoView(_remoteRenderer))
        ],
      ),
    );
  }
}
