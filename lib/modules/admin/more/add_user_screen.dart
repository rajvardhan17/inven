import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/app_theme.dart';

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
      SnackBar(
        content: Text("User assigned as $role"),
        backgroundColor: AppTheme.surface2,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 🗑 DELETE USER
  Future<void> _deleteUser(String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            /// 🔥 HEADER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: AppTheme.accentGrad,
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
                            const Icon(Icons.arrow_back, color: AppTheme.bg),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        "Approve Users",
                        style: TextStyle(
                            color: AppTheme.bg,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  /// 🔍 SEARCH
                  TextField(
                    style: const TextStyle(color: AppTheme.textPrimary),
                    onChanged: (val) {
                      setState(() {
                        searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Search user...",
                      hintStyle:
                          const TextStyle(color: AppTheme.textSecondary),
                      filled: true,
                      fillColor: AppTheme.surface,
                      prefixIcon: const Icon(Icons.search,
                          color: AppTheme.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppTheme.border),
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
                    .where('role', isEqualTo: 'user')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  var users = _filter(snapshot.data!.docs);

                  if (users.isEmpty) {
                    return const Center(
                      child: Text(
                        "No pending users",
                        style:
                            TextStyle(color: AppTheme.textSecondary),
                      ),
                    );
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
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      AppTheme.accentSoft,
                                  child: const Icon(Icons.person,
                                      color: AppTheme.accent),
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
                                              color:
                                                  AppTheme.textPrimary,
                                              fontWeight:
                                                  FontWeight.bold,
                                              fontSize: 16)),
                                      const SizedBox(height: 4),
                                      Text(user['phone'] ?? '',
                                          style: const TextStyle(
                                              color:
                                                  AppTheme.textSecondary)),
                                      Text(user['email'] ?? '',
                                          style: const TextStyle(
                                              color:
                                                  AppTheme.textMuted,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),

                                /// DELETE
                                IconButton(
                                  onPressed: () => _deleteUser(uid),
                                  icon: const Icon(Icons.delete,
                                      color: AppTheme.red),
                                )
                              ],
                            ),

                            const SizedBox(height: 10),

                            /// ACTION BUTTONS
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _changeRole(uid, "salesman"),
                                    icon: const Icon(Icons.work, size: 18),
                                    label: const Text("Salesman"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          AppTheme.accent,
                                      foregroundColor: AppTheme.bg,
                                      padding:
                                          const EdgeInsets.symmetric(
                                              vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _changeRole(uid, "distributor"),
                                    icon: const Icon(
                                        Icons.local_shipping,
                                        size: 18),
                                    label: const Text("Distributor"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          AppTheme.surface2,
                                      foregroundColor:
                                          AppTheme.textPrimary,
                                      padding:
                                          const EdgeInsets.symmetric(
                                              vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10),
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