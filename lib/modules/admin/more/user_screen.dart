import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String searchQuery = "";

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  /// 🔍 FILTER USERS
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filter(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> list) {
    return list.where((doc) {
      String name = doc.data()['name'] ?? '';
      String phone = doc.data()['phone'] ?? '';
      return name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          phone.contains(searchQuery);
    }).toList();
  }

  /// 🗑 DELETE USER
  Future<void> _deleteUser(String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).delete();
  }

  /// ⚙️ CHANGE ROLE
  Future<void> _changeRole(String uid, String newRole) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'role': newRole});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            /// 🔥 HEADER WITH BACK BUTTON
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6A82FB), Color(0xFF4A90E2)],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      /// 🔙 BACK BUTTON
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Manage Users",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  /// 🔍 SEARCH BAR
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
                  const SizedBox(height: 12),
                ],
              ),
            ),

            /// 🔥 TABS
            TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              tabs: const [
                Tab(text: "Salesmen"),
                Tab(text: "Distributors"),
              ],
            ),

            /// 🔥 LIST
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRoleList("salesman"),
                  _buildRoleList("distributor"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📋 LIST OF USERS BY ROLE
  Widget _buildRoleList(String role) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: role)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var users = _filter(snapshot.data!.docs);

        if (users.isEmpty) return const Center(child: Text("No users found"));

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            var user = users[index].data();
            String uid = users[index].id;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.deepPurple.withOpacity(0.1),
                    child: const Icon(Icons.person, color: Colors.deepPurple),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user['name'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(user['phone'] ?? '',
                            style: const TextStyle(color: Colors.grey)),
                        Text("Role: ${user['role'] ?? 'user'}",
                            style: const TextStyle(
                                color: Colors.black54, fontSize: 12)),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == "delete") {
                        _deleteUser(uid);
                      } else {
                        _changeRole(uid, value);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: "salesman",
                        child: Text("Assign Salesman"),
                      ),
                      const PopupMenuItem(
                        value: "distributor",
                        child: Text("Assign Distributor"),
                      ),
                      const PopupMenuItem(
                        value: "delete",
                        child: Text("Delete User",
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}