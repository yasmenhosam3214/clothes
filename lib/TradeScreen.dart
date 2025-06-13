import 'dart:convert';

import 'package:clothes/StoreGeneral.dart';
import 'package:clothes/StoreNormal.dart';
import 'package:clothes/UserProfileScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

import 'BuyScreen.dart';

class TradeScreen extends StatefulWidget {
  const TradeScreen({super.key});

  @override
  State<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen> {
  var storeData = [];
  var normalData = [];
  List<String> clothingTypes = [];
  String selectedClothing = 'All';

  @override
  void initState() {
    super.initState();
    fetchCloths();
    fetchClothsNormal();
  }

  void fetchCloths() async {
    var url = Uri.parse("http://192.168.1.6:3000/general/getStore");

    try {
      var response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> fetchedData = jsonDecode(response.body);
        setState(() {
          storeData = fetchedData;
        });
        Fluttertoast.showToast(msg: "Done");
      } else {
        print('Failed to fetch store items: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching store items: $e');
    }
  }

  // Fetch data for normal items
  void fetchClothsNormal() async {
    var url = Uri.parse("http://192.168.1.6:3000/normal/getAllNormal");

    try {
      var response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> fetchedData = jsonDecode(response.body);
        setState(() {
          normalData = fetchedData;
        });
        Fluttertoast.showToast(msg: "Done");
      } else {
        print('Failed to fetch store items: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching store items: $e');
    }
  }

  List<dynamic> getFilteredData() {
    var mergedData = [...storeData, ...normalData];
    return selectedClothing == 'All'
        ? mergedData
        : mergedData.where((item) => item['name'] == selectedClothing).toList();
  }

  @override
  Widget build(BuildContext context) {
    var filteredData = getFilteredData();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                SizedBox(height: 10),
                _categoryButton(
                    "Store Products", Colors.blueAccent, StoreGeneral()),
                SizedBox(height: 10),
                _categoryButton("Rent and Sell Clothes", Colors.indigoAccent,
                    StoreNormal()),
                SizedBox(height: 10),
                Divider(
                  color: Colors.black,
                  thickness: 1,
                ),
                SizedBox(height: 12),
                Center(
                  child: Container(
                    padding: EdgeInsets.all(16.0),
                    // Adds padding around the text
                    decoration: BoxDecoration(
                      color: Colors.blueGrey,
                      // Background color for the container
                      borderRadius: BorderRadius.circular(12.0),
                      // Rounded corners for the container
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 8.0,
                          offset: Offset(0, 4), // Shadow offset
                        ),
                      ],
                    ),
                    child: Text(
                      "Random Items",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.0,
                        fontFamily: "f",
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.6, // Adjusted aspect ratio
                  ),
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: filteredData.length,
                  itemBuilder: (BuildContext context, int index) {
                    var item = filteredData[index];
                    return Padding(
                      padding: EdgeInsets.all(8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.0),
                        child: Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16.0),
                              child: Image.network(
                                "${item['image']}",
                                width: double.infinity,
                                height: 270,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              left: -2,
                              child: IconButton(
                                  onPressed: () {
                                    addNotification(
                                        item['idItem'],
                                        "Someone Liked Your Item",
                                        item['uid'],
                                        FirebaseAuth.instance.currentUser!.uid);
                                  },
                                  icon: Icon(
                                    size: 28,
                                    Icons.favorite,
                                    color: Colors.red,
                                  )),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method for category buttons
  Widget _categoryButton(String text, Color color, Widget onpress) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: double.infinity,
        height: 75,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => onpress));
          },
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontFamily: "f",
              fontSize: 23,
            ),
          ),
          style: ElevatedButton.styleFrom(
            elevation: 4,
            shape: RoundedRectangleBorder(),
            backgroundColor: color,
          ),
        ),
      ),
    );
  }

  Future<void> addNotification(
      String itemId, String message, String traderID, String correctId) async {
    const String apiUrl = "http://192.168.1.6:3000/noti/notis";

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

class ItemDetails extends StatefulWidget {
  final String itemID;
  final String uid;

  const ItemDetails({super.key, required this.itemID, required this.uid});

  @override
  State<ItemDetails> createState() => _ItemDetailsState();
}

class _ItemDetailsState extends State<ItemDetails> {
  Map<String, dynamic>? itemData;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchByID(widget.itemID);
    fetchByIDData(widget.uid);
  }

  Future<void> fetchByID(String id) async {
    var url = "http://192.168.1.6:3000/general/getDetails/$id";
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
                                          ? "${itemData!['rentPri']} EGP Per Day"
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
                                            'http://192.168.1.6:3000/${userData!['image']}'),
                                        radius: 25,
                                      ),
                                      SizedBox(
                                        width: 6,
                                      ),
                                      Text(
                                        "${userData!['storeName']}",
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
                                              builder: (context) => BuyScreen(
                                                    itemID: widget.itemID,
                                                  )));
                                    },
                                    child: const Text(
                                      "Buy Now",
                                      style: TextStyle(
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
