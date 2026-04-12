import 'package:flutter/material.dart';

class SalesmanScreen extends StatefulWidget {
    @override
    State<SalesmanScreen> createState() => _SalesmanScreenState();
}

class _SalesmanScreenState extends State<SalesmanScreen> {
    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: Text('Salesman Home'),
            ),
            body: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Text(
                            'Welcome to Salesman Dashboard',
                            style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                            onPressed: () {},
                            child: Text('View Orders'),
                        ),
                        SizedBox(height: 12),
                        ElevatedButton(
                            onPressed: () {},
                            child: Text('Add New Sale'),
                        ),
                    ],
                ),
            ),
        );
    }
}