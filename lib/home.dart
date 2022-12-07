import 'package:bluetooth_printer/print.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomHome extends StatelessWidget {
  CustomHome({super.key});

  final List<Map<String, dynamic>> data = [
    {'title': 'Milk', 'price': 200.50, 'qty': 10},
    {'title': 'Chocolate', 'price': 400.50, 'qty': 5},
    {'title': 'Sugar', 'price': 240.50, 'qty': 8},
    {'title': 'Flour', 'price': 100.50, 'qty': 3},
    {'title': 'Eggs', 'price': 40.50, 'qty': 7},
    {'title': 'Shoes', 'price': 200.00, 'qty': 2},
    {'title': 'Short', 'price': 6800.50, 'qty': 1},
    {'title': 'Shirt', 'price': 1100.50, 'qty': 4},
  ];

  final f = NumberFormat("\$###,###.00", "en_US");

  @override
  Widget build(BuildContext context) {
    num total = 0;
    total = data
        .map((e) => e['price'] * e['qty'])
        .reduce((value, element) => value + element);
    return Scaffold(
      appBar: AppBar(title: const Text("Thermal Printer")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: data.length,
              itemBuilder: (c, i) {
                return ListTile(
                  title: Text(
                    data[i]['title'].toString(),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${f.format(data[i]['price'])} x ${data[i]['qty'].toString()}",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  trailing: Text(f.format(data[i]['price'] * data[i]['qty'])),
                  leading: const Icon(
                    Icons.list,
                    size: 15.0,
                  ),
                );
              },
            ),
          ),
          Container(
            color: Colors.grey.shade300,
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Text(
                  "Total: ${f.format(total)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  width: 50.0,
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PrintPage(data: data),
                        ),
                      );
                    },
                    icon: const Icon(Icons.print),
                    label: const Text(
                      'Print',
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.purple.shade500,
                      foregroundColor: Colors.white,
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
