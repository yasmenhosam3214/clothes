import 'dart:convert';
import 'dart:io';
import 'package:clothes/MainScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'MyOrders.dart';

class BuyScreen extends StatefulWidget {
  final String itemID;

  const BuyScreen({super.key, required this.itemID});

  @override
  State<BuyScreen> createState() => _BuyScreenState();
}

class _BuyScreenState extends State<BuyScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController _size = TextEditingController();
  Map<String, dynamic>? itemData;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchByID(widget.itemID);
  }

  Future<void> fetchByID(String id) async {
    var url = "http://192.168.1.5:3000/general/getDetails/$id";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          itemData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Item not found";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load item. Check your connection.";
        isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Confirm Purchase", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductPreview(),
              SizedBox(height: 20),
              _buildDeliveryForm(),
              SizedBox(height: 20),
              _buildGuarantees(),
              SizedBox(height: 30),
              _buildConfirmButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductPreview() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (itemData == null) {
      return Center(child: Text("Failed to load item details"));
    }

    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(itemData!['image'] ?? ''),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itemData!['name'] ?? "Unknown Item",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Size: ${itemData!['size'] ??
                        'N/A'} | Material: ${itemData!['material'] ?? 'N/A'}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Price: \ ${itemData!['price'] ?? 'N/A'} EGP",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Delivery Details",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          SizedBox(height: 10),
          TextFormField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: "Full Name",
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.indigo)),
            ),
            validator: (value) => value!.isEmpty ? "Enter your name" : null,
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: addressController,
            maxLines: 3,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              labelText: "Delivery Address",
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.indigo)),
            ),
            validator: (value) =>
            value!.isEmpty ? "Enter delivery address" : null,
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: phoneController,
            decoration: InputDecoration(
              labelText: "Phone Number",
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.indigo)),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) => value!.isEmpty ? "Enter phone number" : null,
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: _size,
            decoration: InputDecoration(
              labelText: "The Size You Want",
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.indigo)),
            ),
            keyboardType: TextInputType.text,
            validator: (value) => value!.isEmpty ? "Enter your size" : null,
          ),
        ],
      ),
    );
  }

  Widget _buildGuarantees() {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Guarantees & Policies",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            SizedBox(height: 10),
            Row(children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text("30-Day Return Policy",
                  style: TextStyle(color: Colors.black87))
            ]),
            SizedBox(height: 5),
            Row(children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text("Authenticity Guarantee",
                  style: TextStyle(color: Colors.black87))
            ]),
            SizedBox(height: 5),
            Row(children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text("Fast & Secure Delivery",
                  style: TextStyle(color: Colors.black87))
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo,
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 6,
        ),
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            // Show a confirmation dialog
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text("Order Confirmed!",
                      style: TextStyle(color: Colors.green)),
                  content: Text(
                    "Thank you for your purchase. We will contact you as soon as possible.",
                    style: TextStyle(color: Colors.black87),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        addToOrders(FirebaseAuth.instance.currentUser?.uid,
                          widget.itemID,);
                        Navigator.push(context, MaterialPageRoute(builder: (context) => MainScreen()));
                      },
                      child: Text("OK", style: TextStyle(color: Colors.indigo)),
                    ),
                  ],
                );
              },
            );
          }
        },
        child: Text("Confirm Purchase",
            style: TextStyle(fontSize: 18, color: Colors.white)),
      ),
    );
  }

  void addToOrders(String? uid, String itemID) async {
    if (uid == null) {
      print("User is not authenticated.");
      return;
    }

    if (itemData == null) {
      print("Item data is not available.");
      return;
    }

    final imageUrl = itemData!['image'];

    try {
      final imageResponse = await http.get(Uri.parse(imageUrl));
      if (imageResponse.statusCode == 200) {
        // Save the image as a file
        final bytes = imageResponse.bodyBytes;
        final tempDir = await Directory.systemTemp.createTemp();
        final file = File('${tempDir.path}/image.jpg');
        await file.writeAsBytes(bytes);

        var url = "http://192.168.1.5:3000/order/Orders";

        var request = http.MultipartRequest('POST', Uri.parse(url))
          ..fields['uid'] = uid
          ..fields['name'] = itemData!['name']
          ..fields['desc'] = itemData!['desc']
          ..fields['price'] = itemData!['price'].toString()
          ..fields['size'] = _size.text
          ..fields['material'] = itemData!['material']
          ..fields['trader'] = itemData!['uid']
          ..fields['idItem'] = itemID
          ..fields['orderStatus'] = "Pending"
          ..fields['orderArrival'] = "Please Wait "
          ..fields['usernameOf'] = nameController.text
          ..fields['address'] =addressController.text
          ..fields['phone'] = phoneController.text
          ..fields['sizeOf'] = _size.text
          ..fields['processNum'] = "${1}";

        var image = await http.MultipartFile.fromPath(
          'image', file.path,
        );
        request.files.add(image);

        final response = await request.send();

        if (response.statusCode == 200) {
          print("Order placed successfully!");
          response.stream.transform(utf8.decoder).listen((value) {
            print("Response body: $value");
          });
          addNotification(
              itemData!['idItem'],
              "Someone Want To Buy Your Item",
              itemData!['uid'],
              FirebaseAuth.instance.currentUser!.uid);
        } else {
          print("Failed to place order. Status code: ${response.statusCode}");
        }
      } else {
        print("Failed to download image. Status code: ${imageResponse.statusCode}");
      }
    } catch (e) {
      print("Error downloading image: $e");
    }
  }

  Future<void> addNotification(
      String itemId, String message, String traderID, String correctId) async {
    const String apiUrl = "http://192.168.1.5:3000/noti/notis";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "itemId": itemId,
          "message": message,
          "traderId": traderID,
          "correctId": correctId,
        }),
      );

      if (response.statusCode == 201) {
        print("Notification added successfully!");
      } else {
        print("Failed to add notification: ${response.body}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }
}
