import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_page.dart';
import 'message.dart';

void main() {
  runApp(const ChatApp());
}

var logger = Logger();

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatGPT Client',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ChatPage(),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Message> _messages = <Message>[];
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EasyGPT'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: _messages.length,
              itemBuilder: (_, int index) => _messages[index],
              controller: _scrollController,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Enter a message",
                    ),
                    onSubmitted: _handleSubmitted,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    _sendMessage(_controller.text);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubmitted(String text) {
    _controller.clear();
    _sendMessage(text);
  }

  void _sendMessage(String text) {
    logger.i('Sending message: $text');
    _controller.clear();
    _addMessage(text, true);
    getResponse(text).then((String response) {
      logger.i('Received response: $response');
      _addMessage(response, false);
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _addMessage(String text, bool isUser) {
    final Message message = Message(
      text: text,
      isUser: isUser,
    );

    setState(() {
      _messages.add(message);
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  // API call
  Future<String> getResponse(String message) async {
    final prefs = await SharedPreferences.getInstance();

    String apiUrl =
        "${prefs.getString('apiUrl') ?? 'https://api.openai.com/'}v1/chat/completions";
    logger.i('Making API request to: $apiUrl');

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Authorization": "Bearer ${prefs.getString('apiKey') ?? ''}",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        'model': prefs.getString('model') ?? 'gpt-3.5-turbo',
        'messages': [
          {"role": "user", "content": message}
        ]
      }),
    );

    logger.i('API response status: ${response.statusCode}');
    logger.i('API response body: ${response.body}');

    if (response.statusCode == 200) {
      String result =
          jsonDecode(response.body)["choices"][0]["message"]["content"].trim();
      logger.i('Parsed result from API response: $result');
      return result;
    } else {
      logger.e('API request failed with status: ${response.statusCode}');
      logger.e('Response body: ${response.body}');
      throw Exception('Failed to load data!');
    }
  }
}
