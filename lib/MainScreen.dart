import 'dart:convert';

import 'package:clothes/EvoScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'ChatsScreen.dart';
import 'NotiScreen.dart';
import 'TradeScreen.dart';
import 'UserProfileScreen.dart';
import 'main.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  String email = '';
  String userName = '';
  String uid = '';
  String type = '';

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 4, vsync: this);
    getUserData();
  }

  Future<void> getUserData() async {
    uid = FirebaseAuth.instance.currentUser!.uid;

    var url = Uri.parse("http://192.168.1.6:3000/user/userDetails?uid=$uid");

    try {
      var response = await http.get(url, headers: {
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        Map<String, dynamic> userData = jsonDecode(response.body);
        setState(() {
          userName = userData['username'] ?? '';
          email = userData['email'] ?? '';
          type = userData['AccountType'] ?? '';
        });
      } else if (response.statusCode == 404) {
        print("User not found");
      } else {
        print("Error fetching user data: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception: $e");
    }
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          bottom: TabBar(
            controller: tabController,
            tabs: [
              Tab(
                  child:
                      Icon(Icons.person, color: Colors.deepPurple, size: 25)),
              Tab(
                  child:
                      Icon(Icons.timeline, color: Colors.deepPurple, size: 25)),
              Tab(child: Icon(Icons.chat, color: Colors.deepPurple, size: 25)),
              Tab(
                  child: Icon(Icons.notifications,
                      color: Colors.deepPurple, size: 25)),
            ],
          ),
        ),
        body: TabBarView(
          controller: tabController,
          children: [
            UserProfileScreen(uid: uid),
            TradeScreen(),
            ChatsScreen(),
            NotiScreen(),
          ],
        ),
      ),
    );
  }

  // Widget _buildDrawerMenu() {
  //   return Drawer(
  //     child: Column(
  //       children: [
  //         UserAccountsDrawerHeader(
  //           accountName: Text(
  //             userName,
  //             style:
  //                 TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  //           ),
  //           accountEmail: Text(
  //             email,
  //             style:
  //                 TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  //           ),
  //           currentAccountPicture: CircleAvatar(
  //             backgroundColor: Colors.white,
  //             child: userName.isNotEmpty
  //                 ? Text(
  //                     userName[0].toUpperCase(),
  //                     style: TextStyle(
  //                         fontSize: 28,
  //                         color: Colors.deepPurple,
  //                         fontWeight: FontWeight.bold),
  //                   )
  //                 : Icon(
  //                     Icons.person,
  //                     size: 30,
  //                     color: Colors.deepPurple,
  //                   ),
  //           ),
  //           decoration: BoxDecoration(color: Colors.deepPurple),
  //         ),
  //         ListTile(
  //           leading: Icon(Icons.dashboard, color: Colors.deepPurple),
  //           title: Text("Dashboard"),
  //           onTap: () {
  //             Navigator.push(context, MaterialPageRoute(builder: (context) => EvoScreen(uid: uid)));
  //           },
  //         ),
  //         ListTile(
  //           leading: Icon(Icons.ac_unit_rounded, color: Colors.deepPurple),
  //           title: Text("Achievements"),
  //           onTap: () {},
  //         ),
  //         ListTile(
  //           leading: Icon(Icons.person, color: Colors.deepPurple),
  //           title: Text("Donate"),
  //           onTap: () {},
  //         ),
  //         ListTile(
  //           leading: Icon(Icons.star, color: Colors.deepPurple),
  //           title: Text("Rate This App"),
  //           onTap: () {},
  //         ),
  //         Divider(),
  //         ListTile(
  //           leading: Icon(Icons.logout, color: Colors.red),
  //           title: Text("Logout"),
  //           onTap: () async {
  //             await FirebaseAuth.instance.signOut();
  //             Navigator.pushReplacement(
  //                 context, MaterialPageRoute(builder: (context) => Intro()));
  //           },
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
