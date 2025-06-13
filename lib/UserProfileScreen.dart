import 'dart:convert';
import 'dart:io';
import 'package:clothes/ChatsScreen.dart';
import 'package:clothes/MainScreen.dart';
import 'package:clothes/MyOrders.dart';
import 'package:clothes/TradeScreen.dart';
import 'package:clothes/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:multi_select_flutter/chip_display/multi_select_chip_display.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:path/path.dart';

import 'EvoScreen.dart';
import 'UserCappord.dart';

class UserProfileScreen extends StatefulWidget {
  final String uid;

  const UserProfileScreen({super.key, required this.uid});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String username = '';
  String storeName = '';
  String AccountType = '';
  File? _image;
  String imageOfUser = '';
  String ussrImageUrl = '';
  late bool isLoading;

  List<Map<String, dynamic>> storeItems = [];

  @override
  void initState() {
    super.initState();
    fetchUserData(widget.uid);
    fetchStoreItems(widget.uid);
    isLoading = true;
  }

  Future<void> fetchStoreItems(String uid) async {
    try {
      final response = await http
          .get(Uri.parse('http://192.168.1.6:3000/store/getStore?uid=$uid'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          // Extract only the items list
          storeItems = List<Map<String, dynamic>>.from(data['store']['items']);
        });
      } else {
        print("Failed to load items: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching store items: $e");
    }
  }

  Future<void> fetchUserData(String uid) async {
    var url = Uri.parse("http://192.168.1.6:3000/user/userDetails?uid=$uid");

    try {
      var response = await http.get(url, headers: {
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        Map<String, dynamic> userData = jsonDecode(response.body);

        setState(() {
          username = userData['username'] ?? '';
          storeName = userData['storeName'] ?? '';
          AccountType = userData['AccountType'] ?? '';

          imageOfUser =
              (userData['image'] != null && userData['image'].isNotEmpty)
                  ? "http://192.168.1.6:3000/${userData['image']}"
                  : "assets/man.png";

          isLoading = false;
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            child: Column(
              children: [
                SizedBox(
                  height: 35,
                ),
                Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 1),
                      borderRadius: BorderRadius.circular(50)),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: isLoading
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.asset("assets/man.png"),
                          )
                        : (imageOfUser.startsWith("http")
                            ? ClipOval(
                                child: Image.network(
                                  imageOfUser,
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 100,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset("assets/man.png",
                                        width: 75, height: 75);
                                  },
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) {
                                      return child; // Image is fully loaded
                                    } else {
                                      return Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                  },
                                ),
                              )
                            : Image.asset("assets/man.png",
                                width: 100, height: 100)),
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                Text(
                  username,
                  style: TextStyle(
                      color: Colors.black, fontSize: 25, fontFamily: "f"),
                ),
                SizedBox(
                  height: 15,
                ),
                if (widget.uid != FirebaseAuth.instance.currentUser?.uid)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => MessagesScreen(
                                      imageOfUser: imageOfUser,
                                      myId: FirebaseAuth
                                          .instance.currentUser!.uid,
                                      TheId: widget.uid,
                                      username: (AccountType == "Trade User")
                                          ? storeName
                                          : username)));
                        },
                        child: Text(
                          "Message",
                          style: TextStyle(
                              color: Colors.white,
                              fontFamily: "f",
                              fontSize: 20),
                        ),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo),
                      ),
                    ],
                  )
                else
                  SizedBox.shrink(),
                SizedBox(
                  height: 15,
                ),
                if (AccountType == "Trade User") ...[
                  Text(
                    storeName,
                    style: TextStyle(
                        color: Colors.black, fontSize: 25, fontFamily: "f"),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.orange.shade50,
                      ),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4, // Adjust number of columns
                          crossAxisSpacing: 2.0,
                          mainAxisSpacing: 2.0,
                        ),
                        itemCount: storeItems.length,
                        itemBuilder: (BuildContext context, int index) {
                          final item = storeItems[index];
                          return Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15.0),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ItemDetails(
                                        itemID: item['idItem'],
                                        uid: widget
                                            .uid, // from the original widget
                                      ),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15.0),
                                  child: Image.network(
                                    item['image'],
                                    fit: BoxFit.cover,
                                    width: 250,
                                    height: 250,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  )
                ] else
                  SizedBox.shrink(),
                SizedBox(
                  height: 15,
                ),
                if (widget.uid == FirebaseAuth.instance.currentUser!.uid)
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Container(
                      height: 65,
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.circular(15)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => SettingScreen(
                                            username: username,
                                            account: AccountType,
                                            storename: storeName,
                                            UserImage: ussrImageUrl)));
                              },
                              icon: Image.asset(
                                "assets/setus.gif",
                                width: 55,
                                height: 55,
                              )),
                          SizedBox(
                            width: 10,
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          EvoScreen(uid: widget.uid)));
                            },
                            icon: Image.asset("assets/evo.gif",
                                width: 55, height: 55),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          IconButton(
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            MyOrders(uid: widget.uid)));
                              },
                              icon: Image.asset(
                                "assets/shop.gif",
                                width: 55,
                                height: 55,
                              )),
                          SizedBox(
                            width: 10,
                          ),
                          if (AccountType == "Trade User")
                            IconButton(
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              StoreScreen(uid: widget.uid)));
                                },
                                icon: Image.asset(
                                  "assets/store.gif",
                                  width: 55,
                                  height: 55,
                                ))
                          else
                            IconButton(
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              UserCappord(uid: widget.uid)));
                                },
                                icon: Image.asset(
                                  "assets/samples.png",
                                  width: 55,
                                  height: 55,
                                )),
                          SizedBox(
                            width: 10,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SizedBox.shrink()
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingScreen extends StatefulWidget {
  final String username;
  final String storename;
  final String UserImage;
  final String account;

  const SettingScreen(
      {super.key,
      required this.username,
      required this.storename,
      required this.UserImage,
      required this.account});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController storenameController = TextEditingController();
  TextEditingController currentPasswordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController passwordControllerForDelete = TextEditingController();
  bool isLoading = false;
  File? selectedImage;

  @override
  void initState() {
    super.initState();
    usernameController.text = widget.username;
    storenameController.text = widget.storename;
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent,
        title: Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontFamily: "f", fontSize: 22),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Username
              customTextField(
                controller: usernameController,
                hintText: 'Username',
                prefixIcon: Icon(Icons.person, color: Colors.deepPurple),
              ),
              SizedBox(height: 16),

              if (widget.account == "Trade User")
                customTextField(
                  controller: storenameController,
                  hintText: 'Store Name',
                  prefixIcon: Icon(Icons.store, color: Colors.deepPurple),
                )
              else
                SizedBox.shrink(),
              SizedBox(height: 16),

              Center(
                child: GestureDetector(
                  onTap: pickImage,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      selectedImage == null
                          ? CircleAvatar(
                              radius: 65,
                              backgroundImage: NetworkImage(widget.UserImage),
                            )
                          : CircleAvatar(
                              radius: 65,
                              backgroundImage: FileImage(selectedImage!),
                            ),
                      Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 32,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Password Fields
              customTextField(
                controller: currentPasswordController,
                hintText: 'Current Password',
                keyboardType: TextInputType.number,
                obscureText: true,
                prefixIcon: Icon(Icons.lock, color: Colors.deepPurple),
              ),
              SizedBox(height: 16),
              customTextField(
                controller: newPasswordController,
                hintText: 'New Password',
                keyboardType: TextInputType.number,
                obscureText: true,
                prefixIcon: Icon(Icons.lock, color: Colors.deepPurple),
              ),
              SizedBox(height: 16),
              customTextField(
                controller: confirmPasswordController,
                hintText: 'Confirm New Password',
                obscureText: true,
                keyboardType: TextInputType.number,
                prefixIcon: Icon(Icons.lock, color: Colors.deepPurple),
              ),
              SizedBox(height: 30),

              isLoading
                  ? Center(child: CircularProgressIndicator())
                  : Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (newPasswordController.text ==
                              confirmPasswordController.text) {
                            changePassword();
                          } else {
                            Fluttertoast.showToast(
                              msg: 'Passwords do not match!',
                              backgroundColor: Colors.red,
                              textColor: Colors.white,
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          child: Text(
                            'Change Password',
                            style: TextStyle(
                                color: Colors.white,
                                fontFamily: "f",
                                fontSize: 14),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
              SizedBox(height: 25),

              // Save Changes Button
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    if (usernameController.text.isNotEmpty) {
                      editUserAndImage(
                          usernameController.text,
                          selectedImage != null ? selectedImage!.path : '',
                          storenameController.text ?? "Unknown",
                          context);
                    } else {
                      Fluttertoast.showToast(
                        msg: 'Please fill in all fields!',
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    child: Text(
                      'Save Changes',
                      style: TextStyle(
                          color: Colors.white, fontFamily: "f", fontSize: 14),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 25),

              // Delete Account Button
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    String? enteredPassword = await showDialog<String>(
                      context: context,
                      builder: (BuildContext context) {
                        TextEditingController passwordController =
                            TextEditingController();
                        return AlertDialog(
                          title: Text("Enter Password"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: passwordController,
                                keyboardType: TextInputType.number,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: "Password",
                                  prefixIcon: Icon(Icons.lock),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(
                                    null); // Close the dialog without returning any value
                              },
                              child: Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(passwordController
                                    .text); // Close the dialog and return the password
                              },
                              child: Text("Confirm"),
                            ),
                          ],
                        );
                      },
                    );

                    if (enteredPassword != null && enteredPassword.isNotEmpty) {
                      bool passwordIsValid =
                          await verifyPassword(enteredPassword);

                      if (passwordIsValid) {
                        await deleteAccountFromFirebase(context);
                        Fluttertoast.showToast(
                          msg: 'Account deleted successfully.',
                          backgroundColor: Colors.green,
                          textColor: Colors.white,
                        );
                      } else {
                        Fluttertoast.showToast(
                          msg: 'Invalid password. Account not deleted.',
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                        );
                      }
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    child: Text(
                      'Delete Account',
                      style: TextStyle(
                          color: Colors.white, fontFamily: "f", fontSize: 14),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    FirebaseAuth.instance.signOut();
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (context) => Intro()));
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    child: Text(
                      'Logout',
                      style: TextStyle(
                          color: Colors.white, fontFamily: "f", fontSize: 14),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> verifyPassword(String enteredPassword) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      // Reauthenticate the user
      AuthCredential credential = EmailAuthProvider.credential(
        email: user?.email ?? '',
        password: enteredPassword,
      );

      await user?.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteAccountFromFirebase(context) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      await user?.delete();
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: ((context) => Intro())));
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error deleting account. Please try again.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // Function to handle password change
  Future<void> changePassword() async {
    setState(() {
      isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;

      // Reauthenticate user with the current password
      String currentPassword = currentPasswordController.text;
      AuthCredential credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPasswordController.text);

      Fluttertoast.showToast(
        msg: 'Password updated successfully!',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      // Clear text fields
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Function to handle user info update (username, store name, and image)
  void editUserAndImage(
      String username, String imagePath, String storename, context) async {
    try {
      final url = Uri.parse('http://192.168.1.6:3000/user/edit');

      var request = http.MultipartRequest('PATCH', url);
      request.fields['uid'] = FirebaseAuth.instance.currentUser!.uid;
      request.fields['username'] = username;
      request.fields['storeName'] = storename;

      // Attach the image if selected
      if (imagePath.isNotEmpty) {
        var imageFile = File(imagePath);
        var stream = http.ByteStream(imageFile.openRead());
        var length = await imageFile.length();
        var multipartFile = http.MultipartFile(
          'image',
          stream,
          length,
          filename: imageFile.uri.pathSegments.last,
        );
        request.files.add(multipartFile);
      }

      var response = await request.send();

      final responseString = await response.stream.bytesToString();
      print('Response: $responseString');

      if (response.statusCode == 200) {
        final responseData = json.decode(responseString);
        print('User updated successfully: ${responseData['user']}');
        Fluttertoast.showToast(msg: "Data Updated Successfully");
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => MainScreen()));
      } else {
        final responseData = json.decode(responseString);
        print('Error updating user: ${responseData['message']}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}

class StoreScreen extends StatefulWidget {
  final String uid;

  const StoreScreen({super.key, required this.uid});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  TextEditingController itemName = TextEditingController();
  TextEditingController itemDesc = TextEditingController();
  TextEditingController itemPrice = TextEditingController();
  TextEditingController itemSize = TextEditingController();
  TextEditingController itemMaterial = TextEditingController();

  File? selectedImage;
  List<Map<String, dynamic>> storeItems = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchStoreItems(widget.uid); // Fetch items when the screen is loaded
  }

  // Fetch store items from backend API
  Future<void> fetchStoreItems(String uid) async {
    setState(() {
      isLoading = true; // Show loading indicator when fetching data
    });

    try {
      final response = await http
          .get(Uri.parse('http://192.168.1.6:3000/store/getStore?uid=$uid'));

      if (response.statusCode == 200) {
        // Parse the response
        final data = json.decode(response.body);
        setState(() {
          storeItems = List<Map<String, dynamic>>.from(data['store']['items']);
          isLoading = false; // Hide loading indicator after data is fetched
        });
      } else {
        // Handle error
        print("Failed to load items: ${response.statusCode}");
        setState(() {
          isLoading = false; // Hide loading indicator on error
        });
      }
    } catch (e) {
      print("Error fetching store items: $e");
      setState(() {
        isLoading = false; // Hide loading indicator on error
      });
    }
  }

  void showItemDetails(Map<String, dynamic> item, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            item['name'],
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.network(
                  item['image'],
                  fit: BoxFit.cover,
                  height: 500,
                ),
                SizedBox(height: 10),
                Text("Description: ${item['desc']}",
                    style: TextStyle(fontSize: 16)),
                SizedBox(height: 10),
                Text("Price: \$${item['price']}",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text("Size: ${item['size']}", style: TextStyle(fontSize: 16)),
                SizedBox(height: 10),
                Text("Material: ${item['material']}",
                    style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade500),
              child: Text("Close",
                  style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 35),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade300, Colors.orange.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    "My Store",
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: "f",
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          offset: Offset(2.0, 2.0),
                          blurRadius: 3.0,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Colors.orange.shade600,
                        strokeWidth: 3,
                      ),
                    )
                  : storeItems.isEmpty
                      ? Center(child: Text("No items available"))
                      : GridView.builder(
                          shrinkWrap: true,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8.0,
                            mainAxisSpacing: 8.0,
                          ),
                          itemCount: storeItems.length,
                          itemBuilder: (BuildContext context, int index) {
                            final item = storeItems[index];
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: GestureDetector(
                                onTap: () => showItemDetails(item, context),
                                child: Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: Material(
                                    color: Colors.white,
                                    elevation: 5,
                                    borderRadius: BorderRadius.circular(15.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(15.0),
                                      child: Padding(
                                        padding: const EdgeInsets.all(0.0),
                                        child: FittedBox(
                                          fit: BoxFit.cover,
                                          child: Image.network(
                                            item['image'],
                                            width: 180,
                                            height: 180,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange.shade300,
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => AddItemScreen(uid: widget.uid)));
        },
        child: Icon(
          Icons.add,
          size: 35,
          color: Colors.white,
        ),
        elevation: 10,
      ),
    );
  }
}

Widget customTextField({
  required TextEditingController controller,
  String hintText = '',
  TextInputType keyboardType = TextInputType.text,
  bool obscureText = false,
  Widget? prefixIcon,
  Widget? suffixIcon,
  int maxLines = 1,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.black, width: 1),
    ),
    padding: EdgeInsets.symmetric(horizontal: 10),
    child: TextField(
      style: TextStyle(fontFamily: "f"),
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    ),
  );
}

class AddItemScreen extends StatefulWidget {
  final String uid;

  const AddItemScreen({super.key, required this.uid});

  @override
  _AddItemScreenState createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final TextEditingController itemName = TextEditingController();
  final TextEditingController itemDesc = TextEditingController();
  final TextEditingController itemPrice = TextEditingController();
  final TextEditingController QuatityController = TextEditingController();
  final TextEditingController customSizeController = TextEditingController();
  final TextEditingController customMaterialController =
      TextEditingController();

  File? selectedImage;
  String? selectedMaterial;
  List<String> selectedSizes = [];

  final List<String> availableSizes = [
    "12",
    "13",
    "14",
    "15",
    "16",
    "M",
    "L",
    "XL",
    "XXL",
    "XXXL",
    "S",
    "XS",
    "4XL",
    "5XL",
    "All Sizes",
    "Other"
  ];

  final List<String> availableMaterials = [
    "Cotton",
    "Wool",
    "Silk",
    "Polyester",
    "Linen",
    "Nylon",
    "Rayon",
    "Leather",
    "Denim",
    "Chiffon",
    "Satin",
    "Other"
  ];

  Future<File?> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    return image != null ? File(image.path) : null;
  }

  void addItem(BuildContext context) {
    String finalSizes = selectedSizes.join(", ");
    String? finalMaterial = selectedMaterial == "Other"
        ? customMaterialController.text
        : selectedMaterial;
    String itemId = DateTime.now().millisecondsSinceEpoch.toString();

    if (selectedImage != null) {
      addToStore(
          itemName.text,
          itemDesc.text,
          itemPrice.text,
          finalSizes,
          finalMaterial,
          selectedImage!.path,
          widget.uid,
          context,
          itemId,
          QuatityController.text);
    }
  }

  Future<void> addToStore(
      String name,
      String desc,
      String price,
      String size,
      String? material,
      String selectedImagePath,
      String uid,
      BuildContext context,
      String itemId,
      String quantity) async {
    var uri = Uri.parse("http://192.168.1.6:3000/store/storeItems");
    var request = http.MultipartRequest("POST", uri);

    request.fields['uid'] = uid;
    request.fields['name'] = name;
    request.fields['desc'] = desc;
    request.fields['price'] = price;
    request.fields['size'] = size;
    request.fields['material'] = material ?? "";
    request.fields['idItem'] = itemId;
    request.fields['quantity'] = quantity;

    if (selectedImagePath.isNotEmpty) {
      var imageFile = File(selectedImagePath);
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        filename: basename(imageFile.path),
      ));
    }

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Item added successfully!")));
        addToGeneralStore(name, desc, price, size, material, selectedImagePath,
            uid, itemId, quantity);
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => MainScreen()));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Failed to add item")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> addToGeneralStore(
      String name,
      String desc,
      String price,
      String? size,
      String? material,
      String selectedImagePath,
      String uid,
      String itemId,
      qua) async {
    // Accept itemId as parameter
    try {
      final Uri url = Uri.parse('http://192.168.1.6:3000/general/GeneralStore');
      var request = http.MultipartRequest('POST', url);

      request.fields['name'] = name;
      request.fields['desc'] = desc;
      request.fields['price'] = price;
      request.fields['uid'] = uid;
      request.fields['size'] = size ?? "";
      request.fields['material'] = material ?? "";
      request.fields['idItem'] = itemId;
      request.fields['quantity'] = qua;

      if (selectedImagePath.isNotEmpty) {
        var imageFile =
            await http.MultipartFile.fromPath('image', selectedImagePath);
        request.files.add(imageFile);
      }

      var response = await request.send();
      if (response.statusCode != 201) {
        print("Failed to add to general store");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title:
            const Text("Add New Item", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange.shade300,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(controller: itemName, label: "Item Name"),
              _buildTextField(
                  controller: itemDesc, label: "Description", maxLines: 3),
              _buildTextField(
                  controller: QuatityController,
                  label: "Quantity",
                  keyboardType: TextInputType.number),
              _buildTextField(
                  controller: itemPrice,
                  label: "Price",
                  keyboardType: TextInputType.number),
              MultiSelectDialogField(
                items: availableSizes
                    .map((size) => MultiSelectItem(size, size))
                    .toList(),
                title: const Text("Select Sizes"),
                selectedColor: Colors.orange.shade300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.orange.shade300, width: 1),
                  borderRadius: BorderRadius.circular(10),
                ),
                buttonText: const Text("Choose Sizes"),
                onConfirm: (results) {
                  setState(() {
                    selectedSizes = results.cast<String>();
                  });
                },
                chipDisplay: MultiSelectChipDisplay(
                  chipColor: Colors.orange.shade300,
                  textStyle: const TextStyle(color: Colors.white),
                  onTap: (value) {
                    setState(() {
                      selectedSizes.remove(value);
                    });
                  },
                ),
              ),
              if (selectedSizes.contains("Other"))
                _buildTextField(
                    controller: customSizeController, label: "Custom Size"),
              const SizedBox(height: 15),
              _buildDropdown(
                  label: "Material",
                  value: selectedMaterial,
                  items: availableMaterials,
                  onChanged: (newValue) {
                    setState(() => selectedMaterial = newValue);
                  }),
              if (selectedMaterial == "Other")
                _buildTextField(
                    controller: customMaterialController,
                    label: "Custom Material"),
              const SizedBox(height: 15),
              Center(
                child: GestureDetector(
                  onTap: () async {
                    File? image = await pickImage();
                    if (image != null) {
                      setState(() {
                        selectedImage = image;
                      });
                    }
                  },
                  child: Container(
                    height: 250,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.orange.shade300),
                      image: selectedImage != null
                          ? DecorationImage(
                              image: FileImage(selectedImage!),
                              fit: BoxFit.cover)
                          : null,
                    ),
                    child: selectedImage == null
                        ? Icon(Icons.camera_alt,
                            size: 50, color: Colors.orangeAccent.shade200)
                        : null,
                  ),
                ),
              ),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    addItem(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade300,
                  ),
                  child: const Text("Add Item",
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildDropdown(
    {required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 15.0),
    child: DropdownButtonFormField<String>(
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      value: value,
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    ),
  );
}

Widget _buildTextField(
    {required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 15.0),
    child: TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}
