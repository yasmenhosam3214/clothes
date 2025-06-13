import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> traders = [];
  List<Map<String, dynamic>> myChats = [];
  String? currentUserUid;

  @override
  void initState() {
    super.initState();
    initializeFirebase();
  }

  Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
    currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid != null) {
      fetchAllUsers();
      fetchMyChats();
    }
  }

  Future<void> fetchAllUsers() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.1.6:3000/user/AllusersDetails'));
      if (response.statusCode == 200) {
        List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        setState(() {
          users = data.where((user) => user["uid"] != currentUserUid && (user["AccountType"] == "Normal User" || user["AccountType"] == null)).toList();
          traders = data.where((user) => user["uid"] != currentUserUid && user["AccountType"] == "Trade User").toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void fetchMyChats() {
    DatabaseReference chatsRef = FirebaseDatabase.instance.ref("chats");
    chatsRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        Map<String, dynamic> chatsData = Map<String, dynamic>.from(event.snapshot.value as Map);
        List<Map<String, dynamic>> conversations = [];

        chatsData.forEach((chatId, messages) {
          if (chatId.contains(currentUserUid!)) {
            String otherUserId = chatId.split("_").firstWhere((id) => id != currentUserUid);
            conversations.add({"chatId": chatId, "otherUserId": otherUserId});
          }
        });

        setState(() {
          myChats = conversations;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  _buildSection("My Chats", myChats, isMyChats: true),
                  _buildSection("Users", users),
                  _buildSection("Stores", traders),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> data, {bool isMyChats = false}) {
    return Card(
      color: Colors.grey.shade50,
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: ExpansionTile(
        title: Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
        children: data.isNotEmpty
            ? data.map((user) {
          return isMyChats
              ? FutureBuilder<Map<String, dynamic>>(
            future: fetchUserDetails(user['otherUserId']),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListTile(title: Text("Loading..."));
              }
              if (!snapshot.hasData) return SizedBox();
              var userData = snapshot.data!;
              return _buildChatTile(
                image: userData["image"] ?? "assets/man.png",
                name: userData["username"] ?? "Unknown User",
                TheId: userData['uid'] ?? "",
              );
            },
          )
              : _buildChatTile(
            image: user["image"] ?? "assets/man.png",
            name: title == "Stores" ? user["storeName"] ?? "Unknown Store" : user["username"] ?? "Unknown User",
            TheId: user['uid'] ?? "",
          );
        }).toList()
            : [Padding(padding: EdgeInsets.all(12), child: Text("No $title available.", style: TextStyle(color: Colors.grey)))],
      ),
    );
  }

  Future<Map<String, dynamic>> fetchUserDetails(String userId) async {
    final response = await http.get(Uri.parse('http://192.168.1.6:3000/user/userDetails?uid=$userId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {};
  }

  Widget _buildChatTile({required String image, required String name, required String TheId}) {
    String imageUrl = image.startsWith("http") ? image : "http://192.168.1.6:3000/$image";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagesScreen(
              imageOfUser: imageUrl,
              myId: currentUserUid!,
              TheId: TheId,
              username: name,
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        margin: EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 5)],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: NetworkImage(imageUrl),
              onBackgroundImageError: (_, __) => AssetImage("assets/man.png"),
            ),
            SizedBox(width: 15),
            Expanded(
              child: Text(
                name,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.chat_bubble_outline, color: Colors.blueAccent),
          ],
        ),
      ),
    );
  }
}



class MessagesScreen extends StatefulWidget {
  final String imageOfUser;
  final String myId;
  final String TheId;
  final String username;

  const MessagesScreen({
    super.key,
    required this.imageOfUser,
    required this.myId,
    required this.TheId,
    required this.username,
  });

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final List<Map<String, dynamic>> messages = [];
  final TextEditingController _messageController = TextEditingController();
  late DatabaseReference _messagesRef;
  late FirebaseDatabase _database;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();

  }

  void _initializeFirebase() async {
    await Firebase.initializeApp();
    _database = FirebaseDatabase.instance;

    // Create chatId based on sender and receiver
    String chatId = widget.myId.compareTo(widget.TheId) < 0
        ? '${widget.myId}_${widget.TheId}'
        : '${widget.TheId}_${widget.myId}';

    _messagesRef = _database.ref("chats/$chatId");

    // Listen for real-time updates to messages
    _messagesRef.onChildAdded.listen((event) {
      setState(() {
        Map<String, dynamic> newMessage =
        Map<String, dynamic>.from(event.snapshot.value as Map);
        messages.insert(0, newMessage); // Insert at the top
      });
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      String messageText = _messageController.text.trim();
      String time = DateTime.now().toString(); // You can format time as needed

      // Create chatId based on sender and receiver
      String chatId = widget.myId.compareTo(widget.TheId) < 0
          ? '${widget.myId}_${widget.TheId}'
          : '${widget.TheId}_${widget.myId}';

      // Push message to Firebase Realtime Database
      _messagesRef.push().set({
        'text': messageText,
        'SenderId': widget.myId,
        'ReceiverId': widget.TheId,
        'time': time,
      });

      // Clear the input field
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(widget.imageOfUser),
              radius: 20,
            ),
            SizedBox(width: 10),
            Text(
              widget.username,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.video_call,
              color: Colors.white,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              Icons.call,
              color: Colors.white,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true, // Starts from the bottom (latest message)
              padding: EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                bool isMe = message["SenderId"] == widget.myId;
                return _buildChatBubble(message["text"], isMe, message["time"]);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isMe, String time) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blueAccent : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomLeft: isMe ? Radius.circular(15) : Radius.zero,
            bottomRight: isMe ? Radius.zero : Radius.circular(15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              spreadRadius: 2,
            ),
          ],
        ),
        constraints:
        BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87, fontSize: 16),
            ),
            SizedBox(height: 5),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                time,
                style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.black54,
                    fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Type a message...",
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: Colors.blueAccent),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
