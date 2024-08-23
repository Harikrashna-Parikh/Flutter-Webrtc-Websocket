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
    _localRenderer.initialize();
    _remoteRenderer.initialize();

    start();



  }

  void start(){
    initCamera();
    connectSocket();

    peerServiceInstance.initializePeer();
    peerServiceInstance.peer?.onAddStream = (MediaStream stream) {
      _remoteRenderer.srcObject = stream;
    };
    createOfferForInit();
      setState(() {
      });



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

    // Get the local media stream (video + audio)
    MediaStream stream = await navigator.mediaDevices.getUserMedia({
      'video': true,
      'audio': true,
    });

    // Set the local renderer's stream once it is initialized
    _localRenderer.srcObject = stream;
    setState(() {

    });

    // Add tracks from the stream to the peer connection
    stream.getTracks().forEach((track) {
      print('Track : ${track.id}, ${track.kind} ${track.enabled}');
      peerServiceInstance.peer?.addTrack(track, stream);
    });



    // Set  up the remote stream renderer
    peerServiceInstance.peer?.onAddStream = (MediaStream event) async {
      // if (event.streams.isNotEmpty) {
          _remoteRenderer.srcObject = event;
          setState(() {
          });


    };
  }
  void createOfferForInit() async{
    peerServiceInstance.peer!.onAddStream = (MediaStream mediaStream){
      _remoteRenderer.srcObject = mediaStream;
    };

    _localRenderer.srcObject?.getTracks().forEach((track) {
      peerServiceInstance?.peer?.addTrack(track, _localRenderer.srcObject!);
    });

    RTCSessionDescription offer = await peerServiceInstance!.peer!.createOffer();
    await peerServiceInstance!.peer!.setLocalDescription(offer);
    print('Created offer: $offer');
    peerServiceInstance!.peer?.onTrack = (RTCTrackEvent event) {
      print('Got remote track: ${event.streams[0]}');

      event.streams[0].getTracks().forEach((track) {
        print('Add a track to the remoteStream $track');
        _remoteRenderer!.srcObject!.addTrack(track);
      });
    };


  }

  Future<void> joinRoom() async {
    peerServiceInstance.peer!.onAddStream = (MediaStream mediaStream){
      _remoteRenderer.srcObject = mediaStream;
    };

    _localRenderer.srcObject?.getTracks().forEach((track) {
      peerServiceInstance?.peer?.addTrack(track, _localRenderer.srcObject!);
    });


    }

  void connectSocket() async {
    final url = Uri.parse('ws://192.168.1.14:8082/api/videochat/95d5edb9-7c93-48c7-80ca-92915cf9b882');
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
    }
    else if (decodedMessage['type'] == "answer") {
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
          Row(
            children: [
              ElevatedButton(
                onPressed: () async {
                  channel.sink.close();
                  start();
                },
                child: Text("Reconnect Socket"),
              ),
              ElevatedButton(
                onPressed: () async {
                  initCamera();
                  final offer = await peerServiceInstance.getOffer();
                  channel.sink.add(jsonEncode(offer?.toMap()));
                  setState(() {
                  });
                  // joinRoom();
                  while (peerServiceInstance.getIceCandidate() != null) {
                    final IceCandidateWrapper localIceCandidate = IceCandidateWrapper(candidate: peerServiceInstance.localIceCandidate);
                    channel.sink.add(jsonEncode(localIceCandidate.toMap()));
                    break;
                  }
                  setState(() {
                  });
                },
                child: Text("Start Video Call"),
              ),
            ],
          ),
          Expanded(child: RTCVideoView(
            key: const Key("local"),
              _localRenderer)),
          Expanded(child: RTCVideoView(
              key: const Key("remote"),
              _remoteRenderer))
        ],
      ),
    );
  }
}
