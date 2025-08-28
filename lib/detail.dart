import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DetailsPage extends StatelessWidget {
  final Map<String, dynamic> product;

  DetailsPage({required this.product});

  @override
  Widget build(BuildContext context) {
    print("Product data: $product");

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Image.asset(
          "img/openart-e1c9a516-c9aa-4f0f-9b32-5df2a55c3fd3.png",
          height: 40,
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: IconThemeData(color: Colors.brown),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: CachedNetworkImage(
                    imageUrl: product['image'] ?? '',
                    height: 250,
                    width: double.infinity,

                    placeholder: (context, url) =>
                        Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) =>
                        Icon(Icons.error, color: Colors.red),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Product Name in a card
              Card(
                color: Colors.white,
                elevation: 3,

                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    product['name'] ?? 'Unknown',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[800]),
                  ),
                ),
              ),
              SizedBox(height: 10),

              // Description Box
              Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.description, color: Colors.brown),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "${product['desc'] ?? 'No description available'}\n${product['details'] ?? 'Unknown'}",
                          style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                        ),


                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10),

              // Store & Location
              Row(
                children: [
                  Expanded(
                    child: Card(
                      color: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(Icons.store, color: Colors.brown),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                product['store'] ?? 'Unknown',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Card(
                      color: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.redAccent),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                product['location'] ?? 'Unknown',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),


              SizedBox(height: 20),

              // Price Box
              Card(
                color: Colors.brown[100],
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Text(
                    "\$${product['price'] ?? 0}",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[800]),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Add to Bag Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Please login first")));
                      return;
                    }

                    final bagRef = FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('bag');

                    await bagRef.add({
                      'productId': product['id'] ?? '',
                      'name': product['name'] ?? '',
                      'price': product['price'] ?? 0,
                      'image': product['image'] ?? '',
                      'quantity': 1,
                      'addedAt': FieldValue.serverTimestamp(),
                    });

                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:
                        Text("${product['name'] ?? 'Product'} added to bag")));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    "Add to Bag",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
