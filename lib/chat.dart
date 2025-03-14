import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> messages = [];
  final String apiKey = "AIzaSyAar-pAToe0rjgUC_CKHha_JqVw5ULpCEQ";
  final String apiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=";
  Box? chatBox;

  @override
  void initState() {
    super.initState();
    chatBox = Hive.box('chat_history');
    loadChatHistory();
  }

  void loadChatHistory() {
    final history = chatBox?.get('history', defaultValue: []) as List;
    setState(() {
      messages = history.map((item) {
        return Map<String, String>.from(item as Map); // Ensure type safety
      }).toList();
    });
  }


  void saveChatHistory() {
    chatBox?.put('history', messages);
  }

  Future<void> sendMessage(String message) async {
    if (message.isEmpty) return;

    setState(() {
      messages.add({"role": "user", "text": message});
    });
    saveChatHistory();

    final response = await http.post(
      Uri.parse(apiUrl + apiKey),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": message}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final aiResponse =
          responseData['candidates']?[0]['content']['parts'][0]['text'] ?? "No response";

      setState(() {
        messages.add({"role": "bot", "text": aiResponse});
      });
      saveChatHistory();
    } else {
      setState(() {
        messages.add({"role": "bot", "text": "Error fetching response."});
      });
      saveChatHistory();
    }
  }

  void startNewChat() {
    setState(() {
      messages.clear();
    });
    saveChatHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "AI Chatbot",
          style: GoogleFonts.dmSans(
            textStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: Colors.black),
          ),
        ),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.blue, Colors.blueAccent]),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "Chat History",
                    style: GoogleFonts.dmSans(
                      textStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Your previous conversations",
                    style: GoogleFonts.dmSans(
                      textStyle: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: messages.isEmpty
                  ? Center(
                child: Text(
                  "No chat history",
                  style: GoogleFonts.dmSans(
                    textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black54),
                  ),
                ),
              )
                  : ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  if (messages[index]["role"] == "user") {
                    return ListTile(
                      leading: Icon(Icons.chat_bubble_outline, color: Colors.blue),
                      title: Text(
                        messages[index]["text"]!,
                        style: GoogleFonts.dmSans(
                          textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }
                  return SizedBox.shrink(); // Only show user messages in history
                },
              ),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.add, color: Colors.blue),
              title: Text(
                "New Chat",
                style: GoogleFonts.dmSans(
                  textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              onTap: () {
                startNewChat();
                Navigator.pop(context); // Close the drawer
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isUser = message["role"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    margin: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[200] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      message["text"]!,
                      style: GoogleFonts.dmSans(
                        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      hintStyle: GoogleFonts.dmSans(
                        textStyle: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500),
                      ),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    sendMessage(_controller.text);
                    _controller.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
