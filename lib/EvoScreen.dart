import 'dart:convert';
import 'dart:ffi';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

class EvoScreen extends StatefulWidget {
  final String uid;

  const EvoScreen({super.key, required this.uid});

  @override
  State<EvoScreen> createState() => _EvoScreenState();
}

class _EvoScreenState extends State<EvoScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> orders = [];

  @override
  void initState() {
    super.initState();
    fetchOrders(widget.uid);
  }

  Future<void> fetchOrders(uid) async {
    var url = 'http://192.168.1.6:3000/order/GetOrdersT?trader=${widget.uid}';
    print('Fetching orders from: $url');
    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Content-Type': 'application/json',
      });

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          orders = data.map((order) => order as Map<String, dynamic>).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        print("Failed to fetch orders. Status code: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching orders: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "My Orders",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? Center(child: Text("No orders found."))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return _buildOrderCard(order);
                    },
                  ),
                ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => DashBoard(
                    uid: FirebaseAuth.instance.currentUser!.uid,
                    itemID: order['idItem'])));
      },
      child: Card(
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(order['image'] ?? ''),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order['name'] ?? "Item Name",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                    Text("Size: ${order['size'] ?? 'N/A'}",
                        style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashBoard extends StatefulWidget {
  final String uid;
  final String itemID;

  const DashBoard({super.key, required this.uid, required this.itemID});

  @override
  State<DashBoard> createState() => _DashBoardState();
}

class _DashBoardState extends State<DashBoard> {
  bool isLoading = true;
  List<Map<String, dynamic>> orders = [];
  TextEditingController textEx = TextEditingController();
  TextEditingController exepected = TextEditingController();
  var myAnswer = "";
  var process = 1;

  @override
  void initState() {
    super.initState();
    fetchByID(widget.itemID);
  }

  fetchByID(id) async {
    var url = 'http://192.168.1.6:3000/order/GetOrdersOF?idItem=${id}';
    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Content-Type': 'application/json',
      });
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          // Assuming you want the first order's processNum, you can adjust this as needed
          if (data.isNotEmpty) {
            orders =
                data.map((order) => order as Map<String, dynamic>).toList();
            process = data[0]['processNum'] != null ? data[0]['processNum'] : 1;
            print(process);
          }
          isLoading = false;
          Fluttertoast.showToast(msg: "Process: $process");
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Orders",
            style: TextStyle(color: Colors.white, fontFamily: "f")),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: orders.map((order) {
              return switch (process) {
                1 => MoveToProcess1(
                    changeOrderStatus: changeOrderStatus,
                    itemID: widget.itemID,
                    order: order, changeOrderStatusRejected: changeOrderStatusRejected,
                  ),
                2 => MoveToProcess2(
                    order: order,
                    itemID: widget.itemID,
                    changeOrderArrival: changeOrderArrival,
                  ),
                _ => Center(child: Text("Process Finished" , style: TextStyle(color:Colors.black  ,fontSize: 22 ,fontFamily: "f"),)),
              };
            }).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> changeOrderStatus(String myAnswer, String itemID) async {
    var url = Uri.parse("http://192.168.1.6:3000/order/Orders/$itemID/status");

    try {
      var response = await http.patch(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"orderStatus": myAnswer, "processNum": 2}),
      );

      if (response.statusCode == 200) {
        print("Order status updated successfully");
        setState(() {
          process=2;
        });
      } else {
        print("Failed to update order status: ${response.body}");
      }
    } catch (e) {
      print("Error updating order status: $e");
    }
  }

  Future<void> changeOrderStatusRejected(String myAnswer, String itemID) async {
    var url = Uri.parse("http://192.168.1.6:3000/order/Orders/$itemID/status");

    try {
      var response = await http.patch(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"orderStatus": myAnswer, "processNum": 0}),
      );

      if (response.statusCode == 200) {
        print("Order status updated successfully");
        setState(() {
          process=0;
        });
      } else {
        print("Failed to update order status: ${response.body}");
      }
    } catch (e) {
      print("Error updating order status: $e");
    }
  }

  Future<void> changeOrderArrival(String text, String itemID) async {
    var url =
        Uri.parse("http://192.168.1.6:3000/order/OrdersArrive/$itemID/arrival");

    try {
      var response = await http.patch(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"orderArrival": text, "processNum": 3}),
      );

      if (response.statusCode == 200) {
        print("orderArrival updated successfully");
        setState(() {
          process = 3;
        });
      } else {
        print("Failed to update order status: ${response.body}");
      }
    } catch (e) {
      print("Error updating order status: $e");
    }
  }
}

class MoveToProcess1 extends StatefulWidget {
  final Map<String, dynamic> order;
  final Function(String, String) changeOrderStatus;
  final Function(String, String) changeOrderStatusRejected;
  final String itemID;

  MoveToProcess1(
      {required this.order,
      required this.changeOrderStatus,
      required this.itemID, required this.changeOrderStatusRejected});

  @override
  _MoveToProcess1State createState() => _MoveToProcess1State();
}

class _MoveToProcess1State extends State<MoveToProcess1> {
  String myAnswer = "";
  TextEditingController textEx = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "🛠 Process 1",
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.order['image'],
                width: double.infinity,
                height: 250,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 12),
            _buildDetailItem("👤 Name:", widget.order['usernameOf']),
            _buildDetailItem("📍 Address:", widget.order['address']),
            _buildDetailItem("📞 Phone:", widget.order['phone']),
            Divider(height: 20, thickness: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDetailItem("💰 Price", "${widget.order['price']}"),
                _buildDetailItem("📏 Size", widget.order['sizeOf']),
                _buildDetailItem("🔨 Material", widget.order['material']),
              ],
            ),
            SizedBox(height: 15),
            Text(
              "Do you want to Accept or Reject this Order?",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      myAnswer = "Accepted";
                    });
                  },
                  icon: Icon(Icons.check , color: Colors.white,),
                  label: Text("Accept"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (textEx.text.isNotEmpty) {
                      setState(() {
                        myAnswer = "Rejected: ${textEx.text}";
                      });
                    } else {
                      Fluttertoast.showToast(
                        msg: "⚠ Please enter a reason for rejection!",
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                      );
                    }
                  },
                  icon: Icon(Icons.cancel , color: Colors.white,),
                  label: Text("Reject"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            TextField(
              controller: textEx,
              decoration: InputDecoration(
                hintText: "Enter reason for rejection",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              ),
            ),
            SizedBox(height: 10),
            Text(
              myAnswer.isNotEmpty ? "📝 $myAnswer" : "",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                if (myAnswer == "Accepted") {
                  widget.changeOrderStatus(myAnswer, widget.itemID);
                }else if( myAnswer.startsWith("Rejected")){
                  widget.changeOrderStatusRejected(myAnswer ,widget.itemID);
                } else {
                  Fluttertoast.showToast(
                    msg: "⚠ Please accept or reject the order first!",
                    backgroundColor: Colors.blue,
                    textColor: Colors.white,
                  );
                }
              },
              icon: Icon(Icons.send ,color: Colors.white,),
              label: Text("Send My Answer"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MoveToProcess2 extends StatefulWidget {
  final Map<String, dynamic> order;
  final Function(String, String) changeOrderArrival;
  final String itemID;

  MoveToProcess2(
      {required this.order,
      required this.changeOrderArrival,
      required this.itemID});

  @override
  _MoveToProcess2State createState() => _MoveToProcess2State();
}

class _MoveToProcess2State extends State<MoveToProcess2> {
  TextEditingController expectedController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "🛠 Process 2",
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.order['image'],
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 12),
            _buildDetailItem("👤 Name:", widget.order['usernameOf']),
            _buildDetailItem("📍 Address:", widget.order['address']),
            _buildDetailItem("📞 Phone:", widget.order['phone']),
            Divider(height: 20, thickness: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDetailItem("💰 Price", "${widget.order['price']}"),
                _buildDetailItem("📏 Size", widget.order['sizeOf']),
                _buildDetailItem("🔨 Material", widget.order['material']),
              ],
            ),
            SizedBox(height: 15),
            Text(
              "When do you expect the arrival?",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            TextField(
              controller: expectedController,
              decoration: InputDecoration(
                hintText: "Enter Expected Arrival Time",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              ),
            ),
            SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: () {
                if (expectedController.text.isNotEmpty) {
                  widget.changeOrderArrival(
                      expectedController.text, widget.itemID);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text("⚠ Please enter the expected arrival time."),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: Icon(Icons.send ,color: Colors.white,),
              label: Text("Send My Answer"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildDetailItem(String label, String value) {
  return Column(
    children: [
      Text(
        label,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 4),
      Text(
        value,
        style: TextStyle(fontSize: 14, color: Colors.black87),
      ),
    ],
  );
}
