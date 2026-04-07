import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  String searchQuery = "";

  /// 🔍 FILTER
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filter(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> list) {
    return list.where((doc) {
      String name = doc.data()['name'] ?? '';
      String phone = doc.data()['phone'] ?? '';
      return name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          phone.contains(searchQuery);
    }).toList();
  }

  /// ⚙️ CHANGE ROLE
  Future<void> _changeRole(String uid, String role) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'role': role});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("User assigned as $role")),
    );
  }

  /// 🗑 DELETE USER
  Future<void> _deleteUser(String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            /// 🔥 HEADER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6A82FB), Color(0xFF4A90E2)],
                ),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        "Approve Users",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  /// 🔍 SEARCH
                  TextField(
                    onChanged: (val) {
                      setState(() {
                        searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Search user...",
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// 🔥 LIST
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'user') // ⭐ IMPORTANT
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  var users = _filter(snapshot.data!.docs);

                  if (users.isEmpty) {
                    return const Center(
                        child: Text("No pending users"));
                  }

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      var user = users[index].data();
                      String uid = users[index].id;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 10,
                              color: Colors.black.withOpacity(0.05),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.orange.withOpacity(0.1),
                                  child: const Icon(Icons.person,
                                      color: Colors.orange),
                                ),
                                const SizedBox(width: 12),

                                /// USER INFO
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(user['name'] ?? '',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16)),
                                      const SizedBox(height: 4),
                                      Text(user['phone'] ?? '',
                                          style: const TextStyle(
                                              color: Colors.grey)),
                                      Text(user['email'] ?? '',
                                          style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),

                                /// DELETE
                                IconButton(
                                  onPressed: () => _deleteUser(uid),
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                )
                              ],
                            ),

                            const SizedBox(height: 10),

                            /// ACTION BUTTONS
                            /// ACTION BUTTONS
                            Row(
                                children: [
                                    Expanded(
                                        child: ElevatedButton.icon(
                                            onPressed: () => _changeRole(uid, "salesman"),
                                            icon: const Icon(Icons.work, color: Colors.white),
                                            label: const Text(
                                                "Salesman",
                                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue.shade700,
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                ),
                                            ),
                                        ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                        child: ElevatedButton.icon(
                                            onPressed: () => _changeRole(uid, "distributor"),
                                            icon: const Icon(Icons.local_shipping, color: Colors.white),
                                            label: const Text(
                                                "Distributor",
                                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green.shade700,
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                ),        
                                            ),
                                        ),
                                    ),
                                ],
                              )
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}