import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(HectoClashApp());
}

class HectoClashApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HectoClash',
      theme: ThemeData.dark(),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('HectoClash')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => GameScreen()),
            );
          },
          child: Text('Find a Match'),
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  WebSocketChannel? channel;
  String puzzle = "Loading...";
  TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    connectWebSocket();
    fetchPuzzle();
  }

  void connectWebSocket() {
    try {
      channel = IOWebSocketChannel.connect('ws://localhost:8080/ws');
    } catch (e) {
      print("WebSocket error: $e");
    }
  }

  Future<void> fetchPuzzle() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/puzzle'),
      );
      if (response.statusCode == 200) {
        setState(() {
          puzzle = response.body.trim();
        });
      } else {
        setState(() {
          puzzle = "Error loading puzzle";
        });
      }
    } catch (e) {
      setState(() {
        puzzle = "Server unavailable";
      });
    }
  }

  void sendAnswer() {
    if (_controller.text.isNotEmpty && channel != null) {
      channel!.sink.add(_controller.text);
    }
  }

  @override
  void dispose() {
    channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Game Arena')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Solve: $puzzle',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Enter your equation',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: sendAnswer, child: Text('Submit')),
          ],
        ),
      ),
    );
  }
}
