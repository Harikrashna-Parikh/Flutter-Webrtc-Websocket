
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
          {'urls': 'stun:stun.l.google.com:5349'},
          {'urls': 'stun:stun1.l.google.com:3478'},
          {'urls': 'stun:stun1.l.google.com:5349'},
          {'urls': 'stun:stun2.l.google.com:19302'},
          {'urls': 'stun:stun2.l.google.com:5349'},
          {'urls': 'stun:stun3.l.google.com:3478'},
          {'urls': 'stun:stun3.l.google.com:5349'},
          {'urls': 'stun:stun4.l.google.com:19302'},
          {'urls': 'stun:stun4.l.google.com:5349'},
          {'urls': 'stun:bn-turn1.xirsys.com'},
          {
            'urls': 'turn:turn.anyfirewall.com:443?transport=tcp',
            'username': 'webrtc',
            'credential': 'webrtc',
          },
          {
            'urls': 'turn:relay1.expressturn.com:3478',
            'username': 'efRZX7VVZB6250T4HF',
            'credential': 'UFiJt9Y2Rctg18RL',
          },
          {
            'urls': 'turn:relay1.expressturn.com:3478',
            'username': 'ef59NGX88DYZX3JU68',
            'credential': 'Y9JL6obz547h3xa4',
          },
          {
            'username': '0I4QrZu3s-C3mU-256EVtbvg9AnsaItARBnXpye1msFXoJ42E8GXgG1pDeGgAHGBAAAAAGZz2bRTaG9iaGE=',
            'credential': '721cfd32-2ed6-11ef-8b34-0242ac140004',
            'urls': [
              'turn:bn-turn1.xirsys.com:80?transport=udp',
              'turn:bn-turn1.xirsys.com:3478?transport=udp',
              'turn:bn-turn1.xirsys.com:80?transport=tcp',
              'turn:bn-turn1.xirsys.com:3478?transport=tcp',
              'turns:bn-turn1.xirsys.com:443?transport=tcp',
              'turns:bn-turn1.xirsys.com:5349?transport=tcp',
            ],
          },
        ],
        'iceTransportPolicy': 'all',
      };
      peer = await createPeerConnection(configuration);


      peer!.onIceCandidate = (RTCIceCandidate candidate) {
        // if(localIceCandidate == null){
          handleICECandidateEvent(candidate);
        // }

      };

      peer!.onIceConnectionState = (RTCIceConnectionState state) {
        handleICEConnectionStateChangeEvent(state);
      };

      peer!.onTrack = (RTCTrackEvent event) {
        handleTrackEvent(event);
      };
    }
  }

  void handleICECandidateEvent(RTCIceCandidate candidate) {
    // Handle ICE candidate event
    print('ICE Candidate: ${candidate.candidate}');
    localIceCandidate = candidate;
  }

  void handleICEConnectionStateChangeEvent(RTCIceConnectionState state) {
    // Handle ICE connection state change event
    print('ICE Connection State: $state');
  }

  void handleTrackEvent(RTCTrackEvent event) {
    // Handle track event
    print('Track Event: ${event.track}');
  }



  void closePeer() {
    if (peer != null) {
      peer!.close();
      peer = null;
    }
  }

  Future<RTCSessionDescription?> getAnswer(RTCSessionDescription? offer) async {
    try {
      if (peer != null && offer != null) {
        await peer!.setRemoteDescription(offer);
        final answer = await peer!.createAnswer();
        await peer!.setLocalDescription(answer);
        return answer;
      }
    } catch (e) {
      print('Error getting answer: $e');
    }
    return null;
  }

  Future<void> setLocalDescription(RTCSessionDescription answer) async {
    try {
      if (peer != null) {
        await peer!.setRemoteDescription(answer);
      }
    } catch (e) {
      print('Error setting local description: $e');
    }
  }

  Future<RTCSessionDescription?> getOffer() async {
    try {
      if (peer != null) {
        final offer = await peer!.createOffer();
        await peer!.setLocalDescription(offer);
        return offer;
      }
    } catch (e) {
      print('Error getting offer: $e');
    }
    return null;
  }

  RTCIceCandidate? getIceCandidate(){
    return localIceCandidate;
  }
}

final peerServiceInstance = PeerService();
