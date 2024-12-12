import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AllReceiptsPage extends StatefulWidget {
  const AllReceiptsPage({super.key});

  @override
  State<AllReceiptsPage> createState() => _AllReceiptsPageState();
}

class _AllReceiptsPageState extends State<AllReceiptsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get user => _auth.currentUser;
  bool isEmpty = false;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('All Receipts'),
        ),
        body: const Center(child: Text('Please log in to view your receipts.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Receipts'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('receipts')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            isEmpty = true;

            return const Center(child: Text('No receipts available.'));
          } else {
            isEmpty = false;
          }

          var records = snapshot.data!.docs;

          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              var record = records[index].data() as Map<String, dynamic>;
              String storeName = record['storeName'] ?? 'Unknown Store';
              String category = record['category'] ?? 'Unknown';
              double amount = (record['totalAmount'] ?? 0.0).toDouble();
              String docId = records[index].id;

              return ListTile(
                leading: const Icon(Icons.receipt, color: Colors.blue),
                title: Text(
                  storeName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                    'Category: $category\nAmount: PHP ${amount.toStringAsFixed(2)}'),
                onTap: () => _viewPurchasedItems(context, record),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.green),
                      onPressed: () => _editReceipt(context, docId, record),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteReceipt(context, docId),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: isEmpty
          ? const SizedBox.shrink()
          : FloatingActionButton(
              onPressed: () => _deleteAllReceipts(context),
              backgroundColor: Colors.red,
              child: const Icon(Icons.delete_sweep),
            ),
    );
  }

  void _viewPurchasedItems(BuildContext context, Map<String, dynamic> record) {
    List purchasedItems = List.from(record['items'] ?? []);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Purchased Items"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: purchasedItems.length,
              itemBuilder: (context, index) {
                var item = purchasedItems[index];
                String itemName = item['item'] ?? 'Unknown';
                double itemPrice = (item['price'] ?? 0.0).toDouble();

                return ListTile(
                  title: Text(itemName),
                  subtitle: Text('PHP ${itemPrice.toStringAsFixed(2)}'),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Close"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editReceipt(
      BuildContext context, String docId, Map<String, dynamic> record) async {
    final TextEditingController storeNameController =
        TextEditingController(text: record['storeName'] ?? '');
    final TextEditingController amountController =
        TextEditingController(text: record['totalAmount'].toString());
    final TextEditingController categoryController =
        TextEditingController(text: record['category'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Receipt"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: storeNameController,
                decoration: const InputDecoration(labelText: "Store Name"),
              ),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Amount"),
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: "Category"),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Save"),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user!.uid)
                    .collection('receipts')
                    .doc(docId)
                    .update({
                  'storeName': storeNameController.text,
                  'totalAmount': double.parse(amountController.text),
                  'category': categoryController.text,
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteReceipt(BuildContext context, String docId) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Receipt"),
          content: const Text("Are you sure you want to delete this receipt?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Delete"),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user!.uid)
                    .collection('receipts')
                    .doc(docId)
                    .delete();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAllReceipts(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete All Receipts"),
          content: const Text(
              "Are you sure you want to delete all receipts? This action cannot be undone."),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Delete All"),
              onPressed: () async {
                var batch = FirebaseFirestore.instance.batch();
                var snapshots = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user!.uid)
                    .collection('receipts')
                    .get();
                for (var doc in snapshots.docs) {
                  batch.delete(doc.reference);
                }
                await batch.commit();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
