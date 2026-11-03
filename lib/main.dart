import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ProductPage(),
  ));
}

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final products = FirebaseFirestore.instance.collection('products');
  final search = TextEditingController();
  final minPrice = TextEditingController();
  final maxPrice = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    minPrice.dispose();
    maxPrice.dispose();
    super.dispose();
  }

  void reset() {
    search.clear();
    minPrice.clear();
    maxPrice.clear();
    setState(() {});
  }

  String? filterError() {
    final minText = minPrice.text.trim();
    final maxText = maxPrice.text.trim();
    final min = double.tryParse(minText);
    final max = double.tryParse(maxText);

    if (minText.isNotEmpty &&
        (min == null || !min.isFinite || min < 0)) {
      return 'Enter a valid minimum price.';
    }

    if (maxText.isNotEmpty &&
        (max == null || !max.isFinite || max < 0)) {
      return 'Enter a valid maximum price.';
    }

    if (min != null && max != null && min > max) {
      return 'Minimum price cannot exceed maximum price.';
    }

    return null;
  }

  Future<void> editProduct([
    QueryDocumentSnapshot<Map<String, dynamic>>? doc,
  ]) async {
    final name = TextEditingController(
      text: doc?.data()['name']?.toString() ?? '',
    );
    final price = TextEditingController(
      text: doc?.data()['price']?.toString() ?? '',
    );

    String? error;
    bool saving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, update) => AlertDialog(
          title: Text(doc == null ? 'Add Product' : 'Edit Product'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                enabled: !saving,
                decoration: const InputDecoration(
                  labelText: 'Name',
                ),
              ),
              TextField(
                controller: price,
                enabled: !saving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Price',
                ),
              ),
              if (error != null)
                Text(
                  error!,
                  style: const TextStyle(color: Colors.red),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: saving
                  ? null
                  : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: saving
                  ? null
                  : () async {
                      final productName = name.text.trim();
                      final amount = double.tryParse(price.text.trim());

                      if (productName.isEmpty ||
                          amount == null ||
                          !amount.isFinite ||
                          amount < 0) {
                        update(() {
                          error = 'Enter a name and a valid price (0 or more).';
                        });
                        return;
                      }

                      update(() {
                        saving = true;
                        error = null;
                      });

                      try {
                        final data = {
                          'name': productName,
                          'price': amount,
                        };

                        if (doc == null) {
                          await products.add(data);
                        } else {
                          await products.doc(doc.id).update(data);
                        }

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                      } on FirebaseException catch (e) {
                        if (dialogContext.mounted) {
                          update(() {
                            error = e.message ?? 'Save failed.';
                          });
                        }
                      } catch (e) {
                        if (dialogContext.mounted) {
                          update(() {
                            error = 'Save failed: $e';
                          });
                        }
                      } finally {
                        if (dialogContext.mounted) {
                          update(() => saving = false);
                        }
                      }
                    },
              child: Text(saving ? 'Saving...' : 'Save'),
            ),
          ],
        ),
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 250));
    name.dispose();
    price.dispose();
  }

  Future<void> deleteProduct(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('Delete ${doc.data()['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await products.doc(doc.id).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted.')),
        );
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Delete failed.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = filterError();
    final min = double.tryParse(minPrice.text.trim());
    final max = double.tryParse(maxPrice.text.trim());
    final query = search.text.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Autumn Product Manager'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => editProduct(),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Search names',
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minPrice,
                    onChanged: (_) => setState(() {}),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Min price',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: maxPrice,
                    onChanged: (_) => setState(() {}),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Max price',
                    ),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: reset,
                child: const Text('Reset'),
              ),
            ),
            if (error != null)
              Text(
                error,
                style: const TextStyle(color: Colors.red),
              ),
            Expanded(
              child: error != null
                  ? const SizedBox()
                  : StreamBuilder<
                      QuerySnapshot<Map<String, dynamic>>>(
                      stream: products.snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text(
                            'Firestore error: ${snapshot.error}',
                          );
                        }

                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final all = snapshot.data!.docs;

                        if (all.isEmpty) {
                          return const Center(
                            child: Text('No products yet.'),
                          );
                        }

                        final matches = all.where((doc) {
                          final data = doc.data();
                          final name = data['name'];
                          final price = data['price'];

                          if (name is! String || price is! num) {
                            return false;
                          }

                          final amount = price.toDouble();

                          return amount.isFinite &&
                              name.trim().toLowerCase().contains(query) &&
                              (min == null || amount >= min) &&
                              (max == null || amount <= max);
                        }).toList();

                        if (matches.isEmpty) {
                          return const Center(
                            child: Text('No products found.'),
                          );
                        }

                        return ListView.builder(
                          itemCount: matches.length,
                          itemBuilder: (context, index) {
                            final doc = matches[index];
                            final data = doc.data();

                            return ListTile(
                              title: Text(data['name'] as String),
                              subtitle: Text(
                                'ID: ${doc.id}\n'
                                '\$${(data['price'] as num).toStringAsFixed(2)}',
                              ),
                              isThreeLine: true,
                              trailing: Wrap(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    tooltip: 'Edit',
                                    onPressed: () => editProduct(doc),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    tooltip: 'Delete',
                                    onPressed: () => deleteProduct(doc),
                                  ),
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