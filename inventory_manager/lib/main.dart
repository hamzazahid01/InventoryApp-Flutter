import 'package:flutter/material.dart';
import 'add_product_screen.dart';
import 'product_model.dart';

void main() {
  runApp(const InventoryApp());
}

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static List<Product> products = [];

  void addProduct(Product p) {
    setState(() {
      products.add(p);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventory Dashboard"),
      ),

      body: Column(
        children: [

          const SizedBox(height: 10),

          // ADD BUTTON
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddProductScreen(),
                ),
              );

              if (result != null && result is Product) {
                addProduct(result);
              }
            },
            child: const Text("Add Product"),
          ),

          const SizedBox(height: 10),

          // PRODUCT LIST
          Expanded(
            child: products.isEmpty
                ? const Center(
              child: Text("No products yet"),
            )
                : ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final p = products[index];

                return Card(
                  child: ListTile(
                    title: Text(p.name),
                    subtitle: Text(
                      "Price: ${p.price} | Stock: ${p.stock}",
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}