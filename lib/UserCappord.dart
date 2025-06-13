import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';

class UserCappord extends StatefulWidget {
  final String uid;

  const UserCappord({super.key, required this.uid});

  @override
  State<UserCappord> createState() => _UserCappordState();
}

class _UserCappordState extends State<UserCappord> {
  List<Map<String, dynamic>> data = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCloths(widget.uid);
  }

  Future<void> fetchCloths(String uid) async {
    var url = Uri.parse("http://192.168.1.6:3000/normal/getNormal?uid=$uid");

    try {
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var decodedData = jsonDecode(response.body);

        setState(() {
          if (decodedData is List) {
            data = List<Map<String, dynamic>>.from(decodedData);
          } else if (decodedData is Map<String, dynamic>) {
            data = [decodedData];
          }
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        print('Failed to fetch store items: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('Error fetching store items: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "My Clothes",
          style: TextStyle(color: Colors.white, fontFamily: "f"),
        ),
        backgroundColor: Colors.indigo,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openAddAlertDialog(context),
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : data.isEmpty
              ? const Center(child: Text("No items available"))
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.6,
                    ),
                    itemCount: data.length,
                    itemBuilder: (context, index) =>
                        _buildClothCard(data[index]),
                  ),
                ),
    );
  }

  Widget _buildClothCard(Map<String, dynamic> item) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                "${item['image']}" ?? '',
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.image_not_supported, size: 50),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? "No Name",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "\$${item['price'] ?? '0.00'}",
                  style: const TextStyle(
                      fontSize: 14,
                      color: Colors.green,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "Status: ${item['status'] ?? 'Unknown'}",
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                ),
                const SizedBox(height: 4),
                Text(
                  (item['rentable'] == "true") ? "For Rent" : "For Sell",
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void openAddAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Center(
            child: Text(
              "What do you prefer?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogButton(
                  context, "Rent My Clothes", Colors.teal, "Rent"),
              const SizedBox(height: 8),
              _buildDialogButton(
                  context, "Sell My Clothes", Colors.blue.shade800, "Sell"),
            ],
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel",
                    style: TextStyle(color: Colors.redAccent, fontSize: 16)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogButton(
      BuildContext context, String text, Color color, String action) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  RentAndSellScreen(uid: widget.uid, action: action)),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }
}

class RentAndSellScreen extends StatefulWidget {
  final String uid;
  final String action;

  const RentAndSellScreen({super.key, required this.uid, required this.action});

  @override
  State<RentAndSellScreen> createState() => _RentAndSellScreenState();
}

class _RentAndSellScreenState extends State<RentAndSellScreen> {
  File? _image;
  final picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _materialController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  String _selectedStatus = "New";

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitForm(context) async {
    if (_formKey.currentState!.validate()) {
      var uri = Uri.parse("http://192.168.1.6:3000/normal/NormalItems");
      var request = http.MultipartRequest("POST", uri);

      var x = "true";
      if (widget.action == "Rent") {
        setState(() {
          x = "true";
        });
      } else {
        setState(() {
          x = "false";
        });
      }

      request.fields.addAll({
        'uid': FirebaseAuth.instance.currentUser!.uid,
        'name': _nameController.text.trim(),
        'desc': _descController.text.trim(),
        'price': _priceController.text.trim(),
        'size': _sizeController.text.trim(),
        'material': _materialController.text.trim(),
        'status': _selectedStatus,
        'rentable': x,
        'idItem': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      if (_image != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          _image!.path,
          filename: basename(_image!.path),
        ));
      }

      try {
        var response = await request.send();
        if (response.statusCode == 200) {
          Fluttertoast.showToast(msg: "Done");

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => UserCappord(
                uid: FirebaseAuth.instance.currentUser!.uid,
              ),
            ),
          );
        } else {
          Fluttertoast.showToast(msg: "Failed");
        }
      } catch (e) {
        print("Error: $e"); // Log the error to the console for debugging
        Fluttertoast.showToast(msg: "Error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("${widget.action} Clothes"),
        backgroundColor: Colors.indigoAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImagePicker(),
                const SizedBox(height: 16),
                _buildTextField("Clothing Name", _nameController),
                _buildTextField("Description", _descController, maxLines: 3),
                _buildTextField("Size", _sizeController),
                _buildTextField("Material", _materialController),
                if (widget.action == "Rent")
                  _buildTextField("Price Per Day", _priceController,
                      isNumber: true)
                else
                  _buildTextField("Price", _priceController,
                      isNumber: true),
                _buildStatusDropdown(),
                const SizedBox(height: 20),
                _buildSubmitButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.indigoAccent, width: 2),
          ),
          child: _image != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _image!,
                    fit: BoxFit.cover,
                  ),
                )
              : const Center(
                  child: Icon(
                    Icons.camera_alt,
                    color: Colors.indigoAccent,
                    size: 50,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1, bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (value) => value!.isEmpty ? "Enter $label" : null,
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedStatus,
      items: ["New", "Used", "Good Condition"]
          .map((status) => DropdownMenuItem(
                value: status,
                child: Text(status),
              ))
          .toList(),
      decoration: const InputDecoration(
        labelText: "Status",
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        setState(() {
          _selectedStatus = value!;
        });
      },
    );
  }

  Widget _buildSubmitButton(context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          _submitForm(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigoAccent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          widget.action == "Sell" ? "Sell Now" : "Put on Rent",
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }
}
