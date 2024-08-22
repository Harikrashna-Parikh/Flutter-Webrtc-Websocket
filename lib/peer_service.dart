import 'package:flutter_webrtc/flutter_webrtc.dart';

class PeerService {
  RTCPeerConnection? peer;
  RTCIceCandidate? localIceCandidate;

  PeerService() {
    initializePeer();
  }

  Future<void> initializePeer() async {
    if (peer == null) {
      final configuration = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          {
            'urls': 'turn:turn.anyfirewall.com:443?transport=tcp',
            'username': 'webrtc',
            'credential': 'webrtc',
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

      peer!.onTrack = (RTCTrackEvent event) {
        print('Track Event: ${event.track}');
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
