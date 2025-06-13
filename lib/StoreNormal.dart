import 'dart:convert';
import 'dart:io';
import 'package:clothes/MainScreen.dart';
import 'package:clothes/MyOrders.dart';
import 'package:clothes/TradeScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

import 'BuyScreen.dart';
import 'UserProfileScreen.dart';

class StoreNormal extends StatefulWidget {
  const StoreNormal({super.key});

  @override
  State<StoreNormal> createState() => _StoreNormalState();
}

class _StoreNormalState extends State<StoreNormal> {
  List<dynamic> storeData = [];
  bool isLoading = true; // To show loading indicator

  @override
  void initState() {
    super.initState();
    fetchGeneralStore();
  }

  Future<void> fetchGeneralStore() async {
    var url = Uri.parse("http://192.168.1.6:3000/normal/getAllNormal");

    try {
      var response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> fetchedData = jsonDecode(response.body);
        setState(() {
          storeData = fetchedData;
          isLoading = false; // Hide loader
        });
      } else {
        print('Failed to fetch store items: ${response.statusCode}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching store items: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Show loader
          : storeData.isEmpty
              ? Center(child: Text("No items available"))
              : Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.42,
                    ),
                    itemCount: storeData.length,
                    itemBuilder: (context, index) {
                      var item = storeData[index];
                      return _buildItemCard(item, item['idItem'], item['uid']);
                    },
                  ),
                ),
    );
  }

  Widget _buildItemCard(dynamic item, itemID, id) {
    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ItemDetailsNormal(
                      itemID: itemID,
                      id: id,
                    )));
      },
      child: Card(
        color: Colors.grey.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 5,
        shadowColor: Colors.grey.withOpacity(0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
              child: Image.network(
                item['image'],
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180,
                  color: Colors.grey[300],
                  child: Icon(Icons.image_not_supported,
                      size: 50, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Name
                  Text(
                    item['name'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.indigo, Colors.indigoAccent],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Expanded(
                      child: Text(
                        (item['rentable'] == "true")
                            ? "${item['price']} EGP Per Day"
                            : "${item['price']} EGP",
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),

                  _buildDetailRow("Material", item['material']),
                  _buildDetailRow("Size", item['size']),
                  _buildDetailRow("Status", "${item['status']}"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// Helper method for item details
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            maxLines: 1,
            "$label:",
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700]),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class ItemDetailsNormal extends StatefulWidget {
  final String itemID;
  final String id;

  const ItemDetailsNormal({super.key, required this.itemID, required this.id});

  @override
  State<ItemDetailsNormal> createState() => _ItemDetailsNormalState();
}

class _ItemDetailsNormalState extends State<ItemDetailsNormal> {
  Map<String, dynamic>? itemData;
  bool isLoading = true;
  String errorMessage = '';
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    fetchByID(widget.itemID);
    fetchByIDData(widget.id);
  }

  Future<void> fetchByID(String id) async {
    var url = "http://192.168.1.6:3000/normal/getNormals/$id";
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

  Future<void> fetchByIDData(String id) async {
    var url = "http://192.168.1.6:3000/user/userDetails?uid=$id";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          userData = json.decode(response.body);
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Clothing Details",
            style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 18),
                  ),
                )
              : itemData == null
                  ? const Center(child: Text("No item data"))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              Container(
                                height: 400,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(30),
                                    bottomRight: Radius.circular(30),
                                  ),
                                  image: DecorationImage(
                                    image: NetworkImage(itemData!['image']),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 10,
                                left: 20,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Expanded(
                                    child: Text(
                                      itemData!["rentable"] == "true"
                                          ? "${itemData!['price']} EGP Per Day"
                                          : "${itemData!['price']} EGP",
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InkWell(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                UserProfileScreen(
                                                    uid: userData!['uid'])));
                                  },
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundImage: NetworkImage(
                                            'http://192.168.1.5:3000/${userData!['image']}'),
                                        radius: 25,
                                      ),
                                      SizedBox(
                                        width: 6,
                                      ),
                                      Text(
                                        "${userData!['username']}",
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontFamily: 'f'),
                                      )
                                    ],
                                  ),
                                ),
                                Text(
                                  itemData!['name'] ?? "No Name",
                                  style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  itemData!['desc'] ?? "No Description",
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Size: ${itemData!['size'] ?? 'N/A'}",
                                            style:
                                                const TextStyle(fontSize: 18),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Material: ${itemData!['material'] ?? 'N/A'}",
                                            style:
                                                const TextStyle(fontSize: 18),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.shopping_bag,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      backgroundColor: Colors.deepPurple,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  BuyandRentScreen(
                                                    action:
                                                        itemData!['rentable'],
                                                    itemID: widget.itemID,
                                                  )));
                                    },
                                    child: Text(
                                      (itemData!["rentable"] == "true")
                                          ? "Rent Now"
                                          : "Buy Now",
                                      style: const TextStyle(
                                          fontSize: 18, color: Colors.white),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class BuyandRentScreen extends StatefulWidget {
  final String itemID;
  final String action;

  const BuyandRentScreen(
      {super.key, required this.itemID, required this.action});

  @override
  State<BuyandRentScreen> createState() => _BuyandRentScreenState();
}

class _BuyandRentScreenState extends State<BuyandRentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController _size = TextEditingController();
  Map<String, dynamic>? itemData;
  bool isLoading = true;
  String errorMessage = '';

  var myAction;

  @override
  void initState() {
    super.initState();
    myAction = widget.action == "true" ? "Rent" : "Sell";
    fetchByID(widget.itemID);
  }

  Future<void> fetchByID(String id) async {
    var url = "http://192.168.1.6:3000/normal/getNormals/$id";
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
                    "Size: ${itemData!['size'] ?? 'N/A'} | Material: ${itemData!['material'] ?? 'N/A'}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    (myAction == "Rent")
                        ? "Price: \ ${itemData!['price'] ?? 'N/A'} EGP Per Day"
                        : "Price: \ ${itemData!['price'] ?? 'N/A'} EGP",
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
          Text("Your Details",
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
            decoration: InputDecoration(
              labelText: "Your Address",
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
                            widget.itemID, itemData?['uid']);
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => MainScreen()));
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

  void addToOrders(String? uid, String itemID, traderID) async {
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

        var url = "http://192.168.1.6:3000/order/Orders";

        var request = http.MultipartRequest('POST', Uri.parse(url))
          ..fields['uid'] = uid
          ..fields['name'] = itemData!['name']
          ..fields['desc'] = itemData!['desc']
          ..fields['price'] = itemData!['price'].toString()
          ..fields['size'] = itemData!['size']
          ..fields['material'] = itemData!['material']
          ..fields['idItem'] = itemID
          ..fields['orderStatus'] = "Pending"
          ..fields['trader'] = itemData!['uid']
          ..fields['orderArrival'] = "Please Wait "
          ..fields['usernameOf'] = nameController.text
          ..fields['address'] = addressController.text
          ..fields['phone'] = phoneController.text
          ..fields['sizeOf'] = itemData!['size']
          ..fields['processNum'] = "${1}";

        var image = await http.MultipartFile.fromPath(
          'image',
          file.path,
        );
        request.files.add(image);

        final response = await request.send();

        if (response.statusCode == 200) {
          print("Order placed successfully!");
          response.stream.transform(utf8.decoder).listen((value) {
            print("Response body: $value");
          });
        } else {
          print("Failed to place order. Status code: ${response.statusCode}");
        }
      } else {
        print(
            "Failed to download image. Status code: ${imageResponse.statusCode}");
      }
    } catch (e) {
      print("Error downloading image: $e");
    }
  }
}
