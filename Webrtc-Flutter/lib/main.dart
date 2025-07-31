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
      title: 'Flutter WebRTC Demo',
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
  RTCPeerConnection? _rtcPeerConnection;
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  RTCIceCandidate? localIceCandidate;
  DuringCallStatus callStatus = DuringCallStatus.roomJoined;
  bool receiverPauseVideo = false;
  bool receiverEndVideo = false;
  Offset offsetForLocalCamera = const Offset(20, 100);
  bool isMicMuted = false;
  bool isVideoOff = false;
  bool isFrontCamera = false;


  @override
  void initState() {
    super.initState();
    start();
  }

  start() async {
    await connectSocket("first");
  }

  Future<void> connectSocket(String? id) async {
    final url = Uri.parse('ws://192.168.34.246:8080/api/videochat/$id');
    channel = WebSocketChannel.connect(url);
    channel.ready.then(
          (value) async {
        print("Connect Socket");
        channel.stream.listen((message) {
          handleSignalingMessage(message);
        });
        // await _setupPeerConnection();
        channel.sink.add(jsonEncode({"type": "joined"}));
      },
    );
    await _setupLocalStream();
  }


  Future<void> _setupLocalStream() async {
    await localRenderer.initialize();

    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': true,
    };
    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    setState(() {
      localRenderer.srcObject = _localStream;
    });
  }

  @override
  void dispose() {
    localRenderer.dispose();
    remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, results) {
        if (didPop) {
          return;
        }
        if (callStatus == DuringCallStatus.senderEnd) {
          Navigator.of(context).pop(true);
        }
      },
      canPop: false,
      child: Container(
        color: Colors.black,
        child: Stack(
          children: [
            getBody(),
          ],
        ),
      ),
    );
  }

  Widget getBody() {
    return Stack(children: [
      Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: RTCVideoView(
          key: const Key("remote"),
          callStatus == DuringCallStatus.callStarted
              ? remoteRenderer
              : localRenderer,
          mirror: callStatus == DuringCallStatus.callStarted
              ? false
              : (isFrontCamera ? false : true),
          placeholderBuilder: (context) => const Center(child: CircularProgressIndicator()),
        ),
      ),
      Visibility(
          visible: receiverPauseVideo || receiverEndVideo,
          child: Container(
            color: Colors.black.withValues(alpha: 0.8),
            child: Center(
                child: Text(
                  receiverPauseVideo
                      ? "peer paused the video"
                      : "peer left the meeting",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 16),
                )),
          )),
      Positioned(
        left: offsetForLocalCamera.dx,
        top: offsetForLocalCamera.dy,
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              offsetForLocalCamera += details.delta;
            });
          },
          onTap: () {},
          child: Visibility(
            visible: callStatus == (DuringCallStatus.callStarted),
            child: SizedBox(
              height: 0.25,
              width: 0.30,
              child: Padding(
                padding: EdgeInsets.only(right: 10),
                child: RTCVideoView(
                  key: const Key("local"),
                  localRenderer,
                  mirror: isFrontCamera ? false : true,
                  placeholderBuilder: (context) => const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
          ),
        ),
      ),
      Positioned(
          left: 30,
          right: 30,
          bottom: 20,
          child: getControlPanel(),
      )
    ]);
  }

  Widget getControlPanel() {
    return Container(
      padding: const EdgeInsets.only(left: 0, right: 0),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          controlIcons(
              icon1: Icons.mic_off,
              icon2: Icons.mic,
              check: isMicMuted,
              color1: const Color(0xFFBC3C00),
              color2: const Color(0xff6D7179),
              onPress: () => toggleMic()),
          controlIcons(
              icon1: Icons.videocam_off,
              icon2: Icons.videocam,
              check: isVideoOff,
              color1: const Color(0xFFBC3C00),
              color2: const Color(0xff6D7179),
              onPress: () => toggleVideo()),
          controlIcons(
            icon1: Icons.switch_camera,
            check: isFrontCamera,
            color1: const Color(0xFFBC3C00),
            color2: const Color(0xff6D7179),
            onPress: () => toggleCamera(),
          ),
          controlIcons(
              circleColor: const Color(0xffD7363C),
              icon1: Icons.call_end,
              check: true,
              color1: Colors.white,
              onPress: () => endCall()),
        ],
      ),
    );
  }

  Widget controlIcons(
      {Color? circleColor,
        required IconData icon1,
        IconData? icon2,
        required bool check,
        required Color color1,
        Color? color2,
        required Function() onPress}) {
    return IconButton(
        icon: Container(
          height: 30,
          width: 30,
          decoration: BoxDecoration(
            color: circleColor ?? const Color(0xfff2f6f8),
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: EdgeInsets.all(1.0),
            child: Icon(
              size: 20,
              check ? icon1 : (icon2 ?? icon1),
              color: check ? color1 : (color2 ?? color1),
            ),
          ),
        ),
        onPressed: onPress);
  }

  toggleMic() {
    if (localRenderer.srcObject != null) {
      for (var track in localRenderer.srcObject!.getAudioTracks()) {
        track.enabled = !track.enabled;
      }

      setState(() {
        isMicMuted = !isMicMuted;
      });
    }
  }

  toggleVideo() {
    if (localRenderer.srcObject != null) {
      for (var track in localRenderer.srcObject!.getVideoTracks()) {
        track.enabled = !track.enabled;
      }
      channel.sink.add(jsonEncode({"type": !isVideoOff ? "pauseRemoteVideo" : "resumeRemoteVideo"}));
      setState(() {
        isVideoOff = !isVideoOff;
      });
    }
  }

  toggleCamera() async {
    if (localRenderer.srcObject != null) {
      for (var track in localRenderer.srcObject!.getVideoTracks()) {
        Helper.switchCamera(track);
      }
    }

    setState(() {
      isFrontCamera = !isFrontCamera;
    });
  }

  endCall() async {
    channel.sink.add(jsonEncode({"type": "leave"}));
    await _stop();
    await channel.sink.close();
    setState(() {
      callStatus = DuringCallStatus.senderEnd;
    });
    print("Close Socket");
  }

  Future<void> _stop() async {
    try {
      await _rtcPeerConnection?.close();
      _rtcPeerConnection = null;
      _localStream?.getTracks().forEach((track) async {
        await track.stop();
      });
      await _localStream?.dispose();
      _localStream = null;
    } catch (e) {
      print(e);
    }
  }

  Future<void> _setupPeerConnection() async {
    await _stop();
    _rtcPeerConnection = await createPeerConnection({
      "iceServers": [
        {"urls": "stun:stun.l.google.com:19302"},
        {"urls": "stun:stun.l.google.com:5349"},
        {"urls": "stun:stun1.l.google.com:3478"},
        {"urls": "stun:stun1.l.google.com:5349"},
        {"urls": "stun:stun2.l.google.com:19302"},
        {"urls": "stun:stun2.l.google.com:5349"},
        {"urls": "stun:stun3.l.google.com:3478"},
        {"urls": "stun:stun3.l.google.com:5349"},
        {"urls": "stun:stun4.l.google.com:19302"},
        {"urls": "stun:stun4.l.google.com:5349"},
        {
          "urls": ["stun:bn-turn1.xirsys.com"]
        },
        {
          "urls": "turn:turn.anyfirewall.com:443?transport=tcp",
          "username": "webrtc",
          "credential": "webrtc",
        },
        {
          "urls": "turn:relay1.expressturn.com:3478",
          "username": "efRZX7VVZB6250T4HF",
          "credential": "UFiJt9Y2Rctg18RL",
        },
        {
          "urls": "turn:relay1.expressturn.com:3478",
          "username": "ef59NGX88DYZX3JU68",
          "credential": "Y9JL6obz547h3xa4",
        },
        {
          "username": "0I4QrZu3s-C3mU-256EVtbvg9AnsaItARBnXpye1msFXoJ42E8GXgG1pDeGgAHGBAAAAAGZz2bRTaG9iaGE=",
          "credential": "721cfd32-2ed6-11ef-8b34-0242ac140004",
          "urls": [
            "turn:bn-turn1.xirsys.com:80?transport=udp",
            "turn:bn-turn1.xirsys.com:3478?transport=udp",
            "turn:bn-turn1.xirsys.com:80?transport=tcp",
            "turn:bn-turn1.xirsys.com:3478?transport=tcp",
            "turns:bn-turn1.xirsys.com:443?transport=tcp",
            "turns:bn-turn1.xirsys.com:5349?transport=tcp",
          ],
        },
      ],
      "iceTransportPolicy": "all",
    });

    await _setupLocalStream();
    _localStream?.getTracks().forEach((track) async {
      _rtcPeerConnection?.addTrack(track, _localStream!);
    });

    await remoteRenderer.initialize();
    _rtcPeerConnection?.onTrack = (RTCTrackEvent event) {
      print("onTrack event triggered with ${event.streams.length} streams");
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams[0];
        setState(() {
        });
      }
    };

    _rtcPeerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      final IceCandidateWrapper local = IceCandidateWrapper(candidate: candidate);
      channel.sink.add(jsonEncode(local.toMap()));
    };
    print("Setup Peer Connection");
  }

  void handleSignalingMessage(dynamic message) async {
    if (message == null) {
      return;
    }
    Map<String, dynamic> decodedMessage = jsonDecode(message);
    print("Type: ${decodedMessage['type']}");
    try {
      switch (decodedMessage['type']) {
        case 'joined':
          await _createOffer();
          break;
        case 'offer':
          await _onOffer(decodedMessage);
          break;
        case 'answer':
          await _onAnswer(decodedMessage);
          break;
        case 'candidate':
          await _onCandidate(decodedMessage);
          break;
        case 'pauseRemoteVideo':
          setState(() {
            receiverPauseVideo = true;
          });
          break;
        case 'resumeRemoteVideo':
          setState(() {
            receiverPauseVideo = false;
          });
          break;
        case 'leave':
          setState(() {
            receiverEndVideo = true;
          });
          break;
      }
    } catch (e) {
      print("Error : $e");
    }
  }

  Future<void> _createOffer() async {
    await _setupPeerConnection();
    RTCSessionDescription offer = await _rtcPeerConnection!.createOffer();
    await _rtcPeerConnection!.setLocalDescription(offer);
    channel.sink.add(jsonEncode(offer.toMap()));
    print("Create Offer ${jsonEncode(offer.toMap())}");
  }

  Future<void> _onOffer(Map<String, dynamic> message) async {
    await _setupPeerConnection();
    await _rtcPeerConnection?.setRemoteDescription(RTCSessionDescription(message['sdp'], message['type']));

    RTCSessionDescription answer = await _rtcPeerConnection!.createAnswer();

    await _rtcPeerConnection?.setLocalDescription(answer);
    channel.sink.add(jsonEncode(answer.toMap()));
    setState(() {
      callStatus = DuringCallStatus.callStarted;
      receiverEndVideo = false;
    });
    print("Create Answer ${jsonEncode(answer.toMap())}");
  }

  Future<void> _onAnswer(Map<String, dynamic> message) async {
    await _rtcPeerConnection?.setRemoteDescription(RTCSessionDescription(message['sdp'], message['type']));
    print("On Answer ${jsonEncode(message)}");
    setState(() {
      callStatus = DuringCallStatus.callStarted;
      receiverEndVideo = false;
    });
  }

  Future<void> _onCandidate(Map<String, dynamic> message) async {
    RTCIceCandidate candidate =
    RTCIceCandidate(message['candidate']['candidate'], message['candidate']['sdpMid'], message['candidate']['sdpMLineIndex']);
    _rtcPeerConnection?.addCandidate(candidate);
  }
}

enum DuringCallStatus { roomJoined, callStarted, senderEnd }

