import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'MainScreen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(debugShowCheckedModeBanner: false, home: Splash());
  }
}

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  double _opacity = 0.0;
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _opacity = 1.0; // Fade in the image
      });
    });

    check();
  }

  void check() {
    var currentUser = FirebaseAuth.instance.currentUser;
    Future.delayed(const Duration(seconds: 3), () {
      if (currentUser != null) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => MainScreen()));
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => Intro()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade200, Colors.purple.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: AnimatedOpacity(
            opacity: _opacity,
            duration: const Duration(seconds: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/xs.png",
                  width: 100,
                  height: 100,
                ),
                SizedBox(
                  height: 10,
                ),
                Center(
                  child: Text(
                    "Welcome",
                    style: TextStyle(
                        fontFamily: "f", color: Colors.white, fontSize: 35),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class Intro extends StatefulWidget {
  const Intro({super.key});

  @override
  State<Intro> createState() => _IntroState();
}

class _IntroState extends State<Intro> {
  String currentImage = "assets/sell.png";
  String currentTitle = "Sell Clothes";
  bool showNextButton = false;

  Color selectedBuyColor = Colors.deepPurple.shade100;
  Color selectedSellColor = Colors.deepPurple.shade100;

  String selected = '';

  @override
  void initState() {
    super.initState();
    startIntroSequence();
  }

  void startIntroSequence() {
    Timer(Duration(seconds: 2), () {
      setState(() {
        currentImage = "assets/but.png";
        currentTitle = "Buy Clothes";
      });
      Timer(Duration(seconds: 2), () {
        setState(() {
          currentImage = "assets/rent.png";
          currentTitle = "Rent Clothes";
        });
        Timer(Duration(seconds: 2), () {
          setState(() {
            showNextButton = true;
          });
        });
      });
    });
  }

  void navigateToLogin(String selectedOption) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen(option: selectedOption)),
    );
  }

  void onOptionSelected(String option) {
    setState(() {
      if (option == 'Normal User') {
        selected = "Normal User";
        selectedBuyColor = Colors.deepPurple;
        selectedSellColor = Colors.deepPurple.shade100;
      } else if (option == 'Trade User') {
        selected = "Trade User";
        selectedBuyColor = Colors.deepPurple.shade100;
        selectedSellColor = Colors.deepPurple;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              SizedBox(height: 45),
              Image.asset("assets/man.png", height: 150, width: 150),
              SizedBox(height: 10),
              Text(
                "How Can I Help You?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: "f",
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              AnimatedSwitcher(
                duration: Duration(seconds: 1),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: Column(
                  key: ValueKey(currentImage),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Divider(
                        color: Colors.black,
                        thickness: 1,
                        height: 1,
                      ),
                    ),
                    SizedBox(height: 24),
                    Image.asset(
                      currentImage,
                      width: 150,
                      height: 150,
                    ),
                    SizedBox(height: 24),
                    Text(
                      currentTitle,
                      style: TextStyle(
                        fontFamily: "f",
                        color: Colors.black,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Divider(
                        color: Colors.black,
                        thickness: 1,
                        height: 1,
                      ),
                    ),
                    SizedBox(height: 15),
                    if (showNextButton)
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () => onOptionSelected('Normal User'),
                            child: Container(
                              width: 350,
                              height: 70,
                              decoration: BoxDecoration(
                                color: selectedBuyColor,
                                borderRadius: BorderRadius.all(Radius.circular(50)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  "Buy, Sell, or Rent as a Normal User",
                                  style: TextStyle(
                                    fontFamily: "f",
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          GestureDetector(
                            onTap: () => onOptionSelected('Trade User'),
                            child: Container(
                              width: 350,
                              height: 70,
                              decoration: BoxDecoration(
                                color: selectedSellColor,
                                borderRadius: BorderRadius.all(Radius.circular(50)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  "Create a Store to Sell and Buy or Rent",
                                  style: TextStyle(
                                    fontFamily: "f",
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    SizedBox(height: 15),
                    if (showNextButton)
                      IconButton(
                        onPressed: () {
                          if (selected.isEmpty) {
                            Fluttertoast.showToast(
                                msg: "You should select an option.");
                          } else {
                            navigateToLogin(selected);
                          }
                        },
                        icon: Icon(
                          Icons.arrow_forward,
                          size: 30,
                          color: Colors.black,
                        ),
                      )
                  ],
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}


class LoginScreen extends StatefulWidget {
  final String option;

  const LoginScreen({
    super.key,
    required this.option,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController email = TextEditingController(text: "");
  TextEditingController pass = TextEditingController();
  TextEditingController cpass = TextEditingController();

  var state = true;

  @override
  void initState() {
    super.initState();
    email.addListener(() {
      if (!email.text.endsWith("@gmail.com")) {
        final newText = email.text.replaceAll("@gmail.com", "");
        email.value = TextEditingValue(
          text: "$newText@gmail.com",
          selection: TextSelection.collapsed(offset: newText.length),
        );
      }
    });
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
                ClipPath(
                  clipper: WaveClipper(),
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Color(0xff9181F2),
                    ),
                  ),
                ),
                SizedBox(
                  height: 28,
                ),
                Text("Signup Please",
                    style: TextStyle(
                      fontFamily: "f",
                      fontSize: 24,
                      color: Colors.black,
                    )),
                SizedBox(
                  height: 14,
                ),
                Image.asset(
                  "assets/signuop.png",
                  height: 100,
                  width: 100,
                ),
                SizedBox(
                  height: 14,
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: customTextField(
                    controller: email,
                    hintText: "Email",
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                SizedBox(
                  height: 8,
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: customTextField(
                      controller: pass,
                      hintText: "Password",
                      keyboardType: TextInputType.number,
                      obscureText: state,
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              state = !state;
                            });
                          },
                          icon: state
                              ? Icon(Icons.visibility)
                              : Icon(Icons.visibility_off))),
                ),
                SizedBox(
                  height: 8,
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: customTextField(
                      controller: cpass,
                      hintText: "Confirm Password",
                      keyboardType: TextInputType.number,
                      obscureText: state,
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              state = !state;
                            });
                          },
                          icon: state
                              ? Icon(Icons.visibility)
                              : Icon(Icons.visibility_off))),
                ),
                SizedBox(
                  height: 35,
                ),
                Container(
                  width: 200,
                  height: 50,
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.circular(25)),
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xffE80054)),
                      onPressed: () {
                        if (pass.text == cpass.text) {
                          signup(email.text, pass.text, widget.option);
                        } else {
                          Fluttertoast.showToast(msg: "Passwords Not Match");
                        }
                      },
                      child: Text("Signup",
                          style: TextStyle(
                            fontFamily: "f",
                            fontSize: 24,
                            color: Colors.white,
                          ))),
                ),
                SizedBox(
                  height: 36,
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => LoginUserScreen()));
                  },
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already Have Account ?",
                          style: TextStyle(
                              color: Colors.black,
                              fontFamily: "f",
                              fontSize: 18),
                        ),
                        Text(
                          " Login",
                          style: TextStyle(
                              color: Colors.black,
                              fontFamily: "f",
                              fontSize: 18),
                        )
                      ]),
                )
              ],
            ),
          ),
        ),
      ),
    );
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

  Future<void> signup(String email, String pass, option) async {
    var auth = FirebaseAuth.instance;

    try {
      // Create user with FirebaseAuth
      await auth.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );

      var uid = FirebaseAuth.instance.currentUser!.uid;
      var username = FirebaseAuth.instance.currentUser!.email!.split("@")[0];
      Fluttertoast.showToast(msg: "Signup Successful, Welcome!");

      Navigator.push(context, MaterialPageRoute(builder: (context) => LoginUserScreen()));

      startSaveData(email, uid, username, option);

    } catch (e) {
      // Improved error handling with specific messages
      String errorMessage = "Error During Signup Process, Please Try Again.";

      if (e is FirebaseAuthException) {
        // Handle specific Firebase errors
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage =
                "This email is already in use. Please try another email.";
            break;
          case 'weak-password':
            errorMessage =
                "Password is too weak. Please choose a stronger password.";
            break;
          case 'invalid-email':
            errorMessage = "The email address is badly formatted.";
            break;
          default:
            errorMessage = "Unknown error occurred: ${e.message}";
            break;
        }
      }

      // Show the error message in a toast
      Fluttertoast.showToast(msg: errorMessage);
    }
  }

  void startSaveData(String email, String uid, String username, String type) async {
    final url = Uri.parse("http://192.168.1.6:3000/user/userData");

    String storeState = type == "Trade User" ? "$username Store" : "";

    final Map<String, dynamic> data = {
      'email': email,
      'username': username,
      'uid': uid,
      'storeName': storeState,
      'AccountType': type,
      'image': ''
    };

    try {
      final response = await http.post(url,
        body: json.encode(data),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 201) {
        print("User data saved successfully!");
      } else {
        print("Failed to save user data: ${response.body}");
      }
    } catch (error) {
      print("Error occurred while saving data: $error");
    }
  }
}

class LoginUserScreen extends StatefulWidget {
  const LoginUserScreen({super.key});

  @override
  State<LoginUserScreen> createState() => _LoginUserScreenState();
}

class _LoginUserScreenState extends State<LoginUserScreen> {
  TextEditingController email = TextEditingController(text: "");
  TextEditingController pass = TextEditingController();

  var state = true;

  @override
  void initState() {
    super.initState();
    email.addListener(() {
      if (!email.text.endsWith("@gmail.com")) {
        final newText = email.text.replaceAll("@gmail.com", "");
        email.value = TextEditingValue(
          text: "$newText@gmail.com",
          selection: TextSelection.collapsed(offset: newText.length),
        );
      }
    });
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
                ClipPath(
                  clipper: WaveClipper(),
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Color(0xff6864F7),
                    ),
                  ),
                ),
                SizedBox(
                  height: 28,
                ),
                Text("Login Please",
                    style: TextStyle(
                      fontFamily: "f",
                      fontSize: 24,
                      color: Colors.black,
                    )),
                SizedBox(
                  height: 14,
                ),
                Image.asset(
                  "assets/login.png",
                  height: 100,
                  width: 100,
                ),
                SizedBox(
                  height: 14,
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: customTextField(
                    controller: email,
                    hintText: "Email",
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                SizedBox(
                  height: 8,
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: customTextField(
                      controller: pass,
                      hintText: "Password",
                      keyboardType: TextInputType.number,
                      obscureText: state,
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              state = !state;
                            });
                          },
                          icon: state
                              ? Icon(Icons.visibility)
                              : Icon(Icons.visibility_off))),
                ),
                SizedBox(
                  height: 35,
                ),
                Container(
                  width: 200,
                  height: 50,
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.circular(25)),
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xffFDCB50)),
                      onPressed: () {
                        login(email.text, pass.text);
                      },
                      child: Text("Login",
                          style: TextStyle(
                            fontFamily: "f",
                            fontSize: 24,
                            color: Colors.white,
                          ))),
                ),
                SizedBox(
                  height: 36,
                ),
                InkWell(
                  onTap: () {
                    sendLink(context);
                  },
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Forget Password !!",
                          style: TextStyle(
                              color: Colors.black,
                              fontFamily: "f",
                              fontSize: 18),
                        ),
                      ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

  Future<void> login(String text, String text2) async {
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: text, password: text2);

      Fluttertoast.showToast(msg: "Login Succefully , Welcome");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WillPopScope(
            onWillPop: () async => false,
            child: MainScreen(),
          ),
        ),
      );
    } catch (e) {
      print(e);
      Fluttertoast.showToast(
          msg:
              "Error During Login Process  , Please Check Your Password And Try Again");
    }
  }

  void sendLink(BuildContext context) {
    TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Enter Your Email Please"),
          content: TextField(
            controller: emailController,
            decoration: InputDecoration(
              hintText: 'Enter your email here',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                String email = emailController.text.trim();

                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please enter an email address")),
                  );
                  return;
                }

                try {
                  await FirebaseAuth.instance
                      .sendPasswordResetEmail(email: email);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text("Password reset link sent to $email")),
                  );
                  Navigator.pop(context); // Close the dialog
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: ${e.toString()}")),
                  );
                }
              },
              child: Text("Send Link"),
            ),
          ],
        );
      },
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
        size.width / 4, size.height, size.width / 2, size.height - 50);
    path.quadraticBezierTo(
        3 * size.width / 4, size.height - 100, size.width, size.height - 50);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}
