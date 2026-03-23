import 'package:flutter/material.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, String>> salesmen = [
    {"name": "Rahul", "phone": "9876543210"},
  ];

  List<Map<String, String>> distributors = [
    {"name": "Amit", "phone": "9123456780"},
  ];

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  // 🔹 Add User Dialog
  void _showAddUserDialog(bool isSalesman) {
    TextEditingController name = TextEditingController();
    TextEditingController phone = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isSalesman ? "Add Salesman" : "Add Distributor"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: phone,
              decoration: const InputDecoration(labelText: "Phone"),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                if (isSalesman) {
                  salesmen.add({
                    "name": name.text,
                    "phone": phone.text,
                  });
                } else {
                  distributors.add({
                    "name": name.text,
                    "phone": phone.text,
                  });
                }
              });
              Navigator.pop(context);
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  // 🔹 Delete
  void _deleteUser(int index, bool isSalesman) {
    setState(() {
      if (isSalesman) {
        salesmen.removeAt(index);
      } else {
        distributors.removeAt(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Manage Users"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Salesman"),
            Tab(text: "Distributor"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(salesmen, true),
          _buildList(distributors, false),
        ],
      ),
    );
  }

  // 🔹 List UI
  Widget _buildList(List<Map<String, String>> list, bool isSalesman) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => _showAddUserDialog(isSalesman),
              icon: const Icon(Icons.add),
              label: Text(isSalesman ? "Add Salesman" : "Add Distributor"),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final user = list[index];

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
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
                          Text(user["name"]!,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(user["phone"]!,
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _deleteUser(index, isSalesman),
                      icon: const Icon(Icons.delete, color: Colors.red),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
