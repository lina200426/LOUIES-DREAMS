import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth.dart';
import 'notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    _setupFirebaseMessaging();
  }

  void _setupFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permission
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    }

    // Get token (optional)
    String? token = await messaging.getToken();
    print('FCM Token: $token');

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a message in foreground!');
      if (message.notification != null) {
        NotificationService.showNotification(
          title: message.notification!.title ?? "Notification",
          body: message.notification!.body ?? "",
        );
      }
    });

    // Background & terminated messages handled in main.dart
  }

  num getTotal(List<QueryDocumentSnapshot> items) {
    num total = 0;
    for (var item in items) {
      total += item['price'] * (item['quantity'] ?? 1);
    }
    return total;
  }

  void checkout(List<QueryDocumentSnapshot> items) {
    final _cardNameController = TextEditingController();
    final _cardNumberController = TextEditingController();
    final _expiryController = TextEditingController();
    final _cvvController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.brown[50],
        title: Row(
          children: [
            Icon(Icons.credit_card, color: Colors.brown[800]),
            SizedBox(width: 10),
            Text("Payment", style: TextStyle(color: Colors.brown[800])),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Total: \$${getTotal(items)}",
                  style: TextStyle(
                      color: Colors.brown[700], fontWeight: FontWeight.bold)),
              SizedBox(height: 15),
              TextField(
                controller: _cardNameController,
                decoration: InputDecoration(
                  labelText: "Cardholder Name",
                  prefixIcon: Icon(Icons.person, color: Colors.brown[700]),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _cardNumberController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Card Number",
                  prefixIcon: Icon(Icons.credit_card, color: Colors.brown[700]),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _expiryController,
                      keyboardType: TextInputType.datetime,
                      decoration: InputDecoration(
                        labelText: "Expiry",
                        hintText: "MM/YY",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _cvvController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "CVV",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.brown)),
          ),
          ElevatedButton(
            onPressed: () async {
              for (var item in items) {
                await item.reference.delete();
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        "Payment successful! Your bag is now empty.")),
              );

              // Local notification
              await NotificationService.showNotification(
                  title: "Payment Successful",
                  body: "Your bag has been cleared after payment.");

              // Optional: send message via FCM to yourself or admin server
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown[400],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            ),
            child: Text("Pay", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void saveProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'name': _nameController.text,
      'phone': _phoneController.text,
    });

    setState(() {
      isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Profile updated successfully!")),
    );

    await NotificationService.showNotification(
        title: "Profile Updated",
        body: "Your profile info has been updated successfully.");
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              "img/openart-e1c9a516-c9aa-4f0f-9b32-5df2a55c3fd3.png",
              height: 40,
            ),
            Icon(Icons.person, color: Colors.brown[800]),
          ],
        ),
      ),
      body: user == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("You are not logged in",
                style: TextStyle(fontSize: 18, color: Colors.brown[700])),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => AuthPage()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown[400],
                padding:
                EdgeInsets.symmetric(vertical: 12, horizontal: 25),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
              ),
              child: Text("Go to Login",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      )
          : FutureBuilder<DocumentSnapshot>(
        future: _firestore.collection('users').doc(user.uid).get(),
        builder: (context, profileSnapshot) {
          if (!profileSnapshot.hasData)
            return Center(child: CircularProgressIndicator());
          final profileData = profileSnapshot.data!;
          if (!isEditing) {
            _nameController.text = profileData['name'];
            _phoneController.text = profileData['phone'];
          }

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('users')
                .doc(user.uid)
                .collection('bag')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting)
                return Center(child: CircularProgressIndicator());

              final bagItems = snapshot.data?.docs ?? [];
              num total = getTotal(bagItems);

              return SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Profile Info",
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown[800])),
                          IconButton(
                            icon: Icon(
                                isEditing
                                    ? Icons.close
                                    : Icons.edit,
                                color: Colors.brown[700]),
                            onPressed: () {
                              setState(() {
                                isEditing = !isEditing;
                                if (!isEditing) {
                                  _nameController.text =
                                  profileData['name'];
                                  _phoneController.text =
                                  profileData['phone'];
                                }
                              });
                            },
                          )
                        ],
                      ),
                      SizedBox(height: 10),
                      TextField(
                          controller: _nameController,
                          enabled: isEditing,
                          decoration: InputDecoration(
                              labelText: "Name",
                              filled: true,
                              fillColor: Colors.brown[50],
                              border: OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius.circular(15)))),
                      SizedBox(height: 10),
                      TextField(
                          controller: _phoneController,
                          enabled: isEditing,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                              labelText: "Phone",
                              filled: true,
                              fillColor: Colors.brown[50],
                              border: OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius.circular(15)))),
                      SizedBox(height: 10),
                      if (isEditing)
                        ElevatedButton(
                            onPressed: saveProfile,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.brown[400],
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(25)),
                                padding:
                                EdgeInsets.symmetric(vertical: 12)),
                            child: Text("Save Profile",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16))),
                      Divider(
                          height: 30,
                          thickness: 2,
                          color: Colors.brown[200]),
                      Text("Your Bag",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown[800])),
                      SizedBox(height: 10),
                      bagItems.isEmpty
                          ? Text("Your bag is empty",
                          style: TextStyle(
                              fontSize: 16, color: Colors.brown[600]))
                          : ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: bagItems.length,
                        itemBuilder: (context, index) {
                          final item = bagItems[index];
                          int quantity = item['quantity'] ?? 1;
                          return Card(
                            margin:
                            EdgeInsets.symmetric(vertical: 6),
                            color: Colors.brown[50],
                            child: ListTile(
                              leading: Image.network(item['image'],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover),
                              title: Text(item['name'],
                                  style: TextStyle(
                                      color: Colors.brown[800])),
                              subtitle: Text(
                                  "\$${item['price']} x $quantity = \$${item['price'] * quantity}",
                                  style: TextStyle(
                                      color: Colors.brown[700])),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                      icon: Icon(Icons.remove,
                                          color: Colors.brown[700]),
                                      onPressed: () {
                                        if (quantity > 1)
                                          item.reference.update({
                                            'quantity':
                                            quantity - 1
                                          });
                                      }),
                                  Text("$quantity",
                                      style: TextStyle(
                                          color:
                                          Colors.brown[800])),
                                  IconButton(
                                      icon: Icon(Icons.add,
                                          color: Colors.brown[700]),
                                      onPressed: () {
                                        item.reference.update({
                                          'quantity': quantity + 1
                                        });
                                      }),
                                  IconButton(
                                      icon: Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () {
                                        item.reference.delete();
                                      }),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 10),
                      Text("Total: \$${total}",
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown[800])),
                      SizedBox(height: 10),
                      ElevatedButton(
                          onPressed: () => checkout(bagItems),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown[400],
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25)),
                              padding:
                              EdgeInsets.symmetric(vertical: 12)),
                          child: Text("Checkout",
                              style: TextStyle(
                                  color: Colors.white, fontSize: 16))),
                      SizedBox(height: 10),
                      ElevatedButton(
                          onPressed: () async {
                            await _auth.signOut();
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => AuthPage()));
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[400],
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(25)),
                              padding:
                              EdgeInsets.symmetric(vertical: 12)),
                          child: Text("Logout",
                              style: TextStyle(
                                  color: Colors.white, fontSize: 16))),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
