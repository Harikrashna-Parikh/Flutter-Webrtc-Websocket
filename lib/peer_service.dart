import 'package:flutter_webrtc/flutter_webrtc.dart';

class PeerService {
  RTCPeerConnection? peer;
  RTCIceCandidate? localIceCandidate;
  // StreamStateCallback? onAddRemoteStream;


  PeerService() {
    initializePeer();
  }

  Future<void> initializePeer() async {
    if (peer == null) {
      final configuration = {
        'iceServers': [
          { "urls": 'stun:stun.l.google.com:19302'},
          { "urls": "stun:stun.l.google.com:19302" },
          { "urls": "stun:stun.l.google.com:5349" },
          { "urls": "stun:stun1.l.google.com:3478" },
          { "urls": "stun:stun1.l.google.com:5349" },
          { "urls": "stun:stun2.l.google.com:19302" },
          { "urls": "stun:stun2.l.google.com:5349" },
          { "urls": "stun:stun3.l.google.com:3478" },
          { "urls": "stun:stun3.l.google.com:5349" },
          { "urls": "stun:stun4.l.google.com:19302" },
          { "urls": "stun:stun4.l.google.com:5349" },
          { "urls": ["stun:bn-turn1.xirsys.com"] },
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
            "username":
            "0I4QrZu3s-C3mU-256EVtbvg9AnsaItARBnXpye1msFXoJ42E8GXgG1pDeGgAHGBAAAAAGZz2bRTaG9iaGE=",
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
        'iceTransportPolicy': 'all',
      };
      peer = await createPeerConnection(configuration);

      peer!.onIceCandidate = (RTCIceCandidate candidate) {
        localIceCandidate = candidate;
      };

      peer!.onIceConnectionState = (RTCIceConnectionState state) {
        print('ICE Connection State: $state');
      };

      peer!.onIceGatheringState = (RTCIceGatheringState state){
        if(state == RTCIceGatheringState.RTCIceGatheringStateComplete){
          print("and the finallu==========================?>>>>>>>>>>>>>>>>>>>>>>");
        }
      };
      peer!.onTrack = (RTCTrackEvent event) {
        print('Track Event: ${event.track}');
      };
      peer!.onAddStream = (MediaStream stream) {
        print("Add remote stream");
      };
    }
  }

  Future<RTCSessionDescription?> getAnswer(RTCSessionDescription offer) async {
    try {
      await peer!.setRemoteDescription(offer);
      final answer = await peer!.createAnswer();
      await peer!.setLocalDescription(answer);
      return answer;
    } catch (e) {
      print('Error getting answer: $e');
      return null;
    }
  }

  Future<RTCSessionDescription?> getOffer() async {
    try {
      final offer = await peer!.createOffer();
      await peer!.setLocalDescription(offer);
      // Add a small delay to ensure ICE candidates have time to gather
      await Future.delayed(Duration(seconds: 2));
      return offer;
    } catch (e) {
      print('Error getting offer: $e');
      return null;
    }
  }

  RTCIceCandidate? getIceCandidate() {
    return localIceCandidate;
  }

  void closePeer() {
    if (peer != null) {
      peer!.close();
      peer = null;
    }
  }
}

class IceCandidateWrapper {
  String type;
  RTCIceCandidate? candidate;

  IceCandidateWrapper({this.type = 'candidate', this.candidate});

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'candidate': {
        'candidate': candidate?.candidate,
        'sdpMid': candidate?.sdpMid,
        'sdpMLineIndex': candidate?.sdpMLineIndex,
      }
    };
  }
}
