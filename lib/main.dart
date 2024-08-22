import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
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
  late WebSocketChannel channel;
  String recieved = "Waiting ====???????";
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();

  @override
  void initState() {
    connectSocket();
    channel.stream.listen((message) {
      print("=======================>>>>>>>>>>>>>>>> message recieved");
      setState(() {
        recieved = message;
      });
      print(message);
      print(
          "=======================>>>>>>>>>>>>>>>> ok!!!                                                                              ");
    });
  }

  connectSocket() async {
    final url = Uri.parse(
        'ws://192.1.150.112:8082/api/videochat/efd6fea9-fa56-4c01-bbe4-0853e40c1866w');
    channel = WebSocketChannel.connect(url);
    print("=======================>>>>>>>>>>>>>>>> channel getting ready");
    await channel.ready;
    print("=======================>>>>>>>>>>>>>>>>  ready , ok!!");
    print("=======================>>>>>>>>>>>>>>>> $channel");
  }

  void initCamera() async {
    await _localRenderer.initialize();
    MediaStream stream = await navigator.mediaDevices.getUserMedia({
      'video': true,
      'audio': true,
    });

    setState(() {
      _localRenderer.srcObject = stream;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print("=====================");
          print(textEditingController.text);
          channel.sink.add(textEditingController.text);
          print("=====================");
        },
        child: Icon(Icons.send),
      ),
      appBar: AppBar(
        title: Text("Home Page"),
      ),
      body: Column(
        children: [
          Text("hello"),
          TextField(
            controller: textEditingController,
          ),
          Text(recieved),
          SizedBox(
            height: 12,
          ),
          ElevatedButton(
              onPressed: () {
                initCamera();
              },
              child: Text("Start Video call")),
        Expanded(child: RTCVideoView(_localRenderer))
        ],
      ),
    );
  }
}
