import 'dart:convert';
import 'package:clothes/EvoScreen.dart';
import 'package:clothes/StoreNormal.dart';
import 'package:clothes/TradeScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NotiScreen extends StatefulWidget {
  const NotiScreen({super.key});

  @override
  State<NotiScreen> createState() => _NotiScreenState();
}

class _NotiScreenState extends State<NotiScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true; // Show loading indicator

  @override
  void initState() {
    super.initState();
    fetchAllNoti(FirebaseAuth.instance.currentUser!.uid);
  }

  Future<void> fetchAllNoti(String uid) async {
    const String apiUrl =
        "http://192.168.1.6:3000/noti/GetNotis"; // Replace with your backend API

    try {
      final response = await http.get(Uri.parse("$apiUrl?correctId=$uid"));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          notifications = data
              .map((item) => {
                    "title": "New Notification", // Customize this
                    "subtitle": item["message"],
                    "icon": Icons.notifications,
                  })
              .toList();
        });
      } else {
        print("Failed to fetch notifications: ${response.body}");
      }
    } catch (error) {
      print("Error fetching notifications: $error");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading indicator
          : notifications.isEmpty
              ? Center(child: Text("No notifications found"))
              : ListView.builder(
                  itemCount: notifications.length,
                  padding: EdgeInsets.all(10),
                  itemBuilder: (context, index) {
                    final item = notifications[index];

                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepPurple.shade100,
                          child: Icon(item["icon"], color: Colors.white),
                        ),
                        title: Text(
                          item["title"],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(item["subtitle"]),
                        onTap: () {
                          if (item["subtitle"] == "Someone Want To Buy Your Item") {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => EvoScreen(
                                        uid: FirebaseAuth
                                            .instance.currentUser!.uid)));
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
