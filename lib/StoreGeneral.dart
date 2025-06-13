import 'dart:convert';
import 'package:clothes/TradeScreen.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

class StoreGeneral extends StatefulWidget {
  const StoreGeneral({super.key});

  @override
  State<StoreGeneral> createState() => _StoreGeneralState();
}

class _StoreGeneralState extends State<StoreGeneral> {
  List<dynamic> storeData = [];
  bool isLoading = true; // To show loading indicator

  @override
  void initState() {
    super.initState();
    fetchGeneralStore();
  }

  Future<void> fetchGeneralStore() async {
    var url = Uri.parse("http://192.168.1.6:3000/general/getStore");

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
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.42,
          ),
          itemCount: storeData.length,
          itemBuilder: (context, index) {
            var item = storeData[index];
            return _buildItemCard(item , item['idItem'] , item['uid']);
          },
        ),
      ),
    );
  }

  Widget _buildItemCard(dynamic item ,itemID ,uid) {
    return InkWell(
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (context) => ItemDetails(itemID: itemID, uid: uid, )));
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
                errorBuilder: (context, error, stackTrace) =>
                    Container(
                      height: 180,
                      color: Colors.grey[300],
                      child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
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
                        colors: [Colors.green, Colors.lightGreenAccent],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${item['price']} EGP",
                      style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                  SizedBox(height: 8),

                  _buildDetailRow("Material", item['material']),
                  _buildDetailRow("Size", item['size']),
                  _buildDetailRow("Quantity", "${item['quantity']}"),
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
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700]),
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
