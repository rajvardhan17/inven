import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/app_theme.dart';

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
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            /// 🔥 HEADER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: AppTheme.accentGrad,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppTheme.bg),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Manage Users",
                        style: TextStyle(
                          color: AppTheme.bg,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
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
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: "Search user...",
                      hintStyle:
                          const TextStyle(color: AppTheme.textSecondary),
                      filled: true,
                      fillColor: AppTheme.surface,
                      prefixIcon: const Icon(Icons.search,
                          color: AppTheme.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSm),
                        borderSide:
                            const BorderSide(color: AppTheme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSm),
                        borderSide:
                            const BorderSide(color: AppTheme.border),
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
              labelColor: AppTheme.accent,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.accent,
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

  /// 📋 LIST OF USERS
  Widget _buildRoleList(String role) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: role)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.accent),
          );
        }

        var users = _filter(snapshot.data!.docs);

        if (users.isEmpty) {
          return const Center(
            child: Text("No users found",
                style: TextStyle(color: AppTheme.textSecondary)),
          );
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            var user = users[index].data();
            String uid = users[index].id;

            return Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.border),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.accentSoft,
                    child: const Icon(Icons.person,
                        color: AppTheme.accent),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['name'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user['phone'] ?? '',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          "Role: ${user['role'] ?? 'user'}",
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  PopupMenuButton<String>(
                    color: AppTheme.surface2,
                    onSelected: (value) {
                      if (value == "delete") {
                        _deleteUser(uid);
                      } else {
                        _changeRole(uid, value);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: "salesman",
                        child: Text("Assign Salesman"),
                      ),
                      PopupMenuItem(
                        value: "distributor",
                        child: Text("Assign Distributor"),
                      ),
                      PopupMenuItem(
                        value: "delete",
                        child: Text("Delete User",
                            style: TextStyle(color: AppTheme.red)),
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