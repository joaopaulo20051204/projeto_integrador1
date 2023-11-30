import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(ListaCompras());
}

class ListaCompras extends StatefulWidget {
  @override
  _ListaComprasState createState() => _ListaComprasState();
}

class _ListaComprasState extends State<ListaCompras> {
  List<ShoppingItem> items = [];
  TextEditingController itemNameController = TextEditingController();
  TextEditingController itemValueController = TextEditingController();
  int selectedItemIndex = -1;
  late ShoppingList shoppingList;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    shoppingList = ModalRoute.of(context)!.settings.arguments as ShoppingList;
    _loadItems();
  }

  void _loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? itemsData = prefs.getStringList('shoppingItems_${shoppingList.name}');

    if (itemsData != null) {
      setState(() {
        items = itemsData.map((itemString) {
          Map<String, dynamic> itemMap = json.decode(itemString);
          return ShoppingItem.fromJson(itemMap);
        }).toList();
      });
    }
  }

  void _saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> itemsData = items.map((item) => json.encode(item.toJson())).toList();
    prefs.setStringList('shoppingItems_${shoppingList.name}', itemsData);
  }

  String _formatCurrency(double amount) {
    return 'R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  double _calculateSelectedTotal() {
    double total = 0;
    for (var item in items) {
      if (item.isComplete) {
        total += item.value * item.quantity;
      }
    }
    return total;
  }

  void _showTotalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Total dos Itens Selecionados'),
          content: Text('Total: ${_formatCurrency(_calculateSelectedTotal())}'),
          actions: [],
        );
      },
    );
  }

  Widget _buildList() {
    return Expanded(
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color:  Colors.white,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Dismissible(
                key: UniqueKey(),
                onDismissed: (direction) {
                  _removeItem(index);
                },
                background: Container(
                  color: Colors.red,
                  child: Icon(Icons.delete, color: Colors.black),
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20.0),
                ),
                child: ListTile(
                  onTap: () {
                    setState(() {
                      selectedItemIndex = index;
                      itemNameController.text = items[index].name;
                      itemValueController.text = items[index].value.toString();
                    });
                  },
                  leading: Checkbox(
                    value: items[index].isComplete,
                    onChanged: (newValue) {
                      _toggleItem(index);
                    },
                    activeColor: Colors.blue,
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          items[index].name,
                          style: TextStyle(
                            decoration: items[index].isComplete ? TextDecoration.lineThrough : TextDecoration.none,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove),
                            onPressed: () {
                              _decrementQuantity(index);
                            },
                          ),
                          Text(
                            items[index].quantity.toString(),
                            style: TextStyle(fontSize: 18),
                          ),
                          IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () {
                              _incrementQuantity(index);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  subtitle: Text('Valor: ${_formatCurrency(items[index].value)}'),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputFields() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: itemNameController,
                  onChanged: (value) {},
                  decoration: InputDecoration(
                    hintText: 'Nome do item',
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                  cursorColor: Colors.black,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: itemValueController,
                  onChanged: (value) {},
                  decoration: InputDecoration(
                    hintText: 'Valor (opcional)',
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.attach_money),
                      onPressed: () {
                        _showTotalDialog(context);
                        final newName = itemNameController.text.trim();
                        final newValue = double.tryParse(itemValueController.text);
                        if (newName.isNotEmpty) {
                          if (selectedItemIndex >= 0) {
                            _editItem(selectedItemIndex, newName, newValue);
                          } else {
                            _addItem(newName, newValue);
                          }
                        }
                      },
                    ),
                  ),
                  cursorColor: Colors.black,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [DecimalTextInputFormatter()],
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              final newName = itemNameController.text.trim();
              final newValue = double.tryParse(itemValueController.text);
              if (newName.isNotEmpty) {
                if (selectedItemIndex >= 0) {
                  _editItem(selectedItemIndex, newName, newValue);
                } else {
                  _addItem(newName, newValue);
                }
              }
            },
            child: Text(
              selectedItemIndex >= 0 ? 'Editar Item' : 'Adicionar à Lista',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(primary: Colors.blue),
          ),
          SizedBox(height: 10),
          // Outros botões ou widgets aqui
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(shoppingList.name),
      ),
      body: Column(
        children: [
          _buildList(),
          _buildInputFields(),
        ],
      ),
    );
  }

  void _addItem(String itemName, double? itemValue) {
    setState(() {
      items.add(ShoppingItem(name: itemName, value: itemValue ?? 0.0));
      itemNameController.clear();
      itemValueController.clear();
      _saveItems();
    });
  }

  void _editItem(int index, String newName, double? newValue) {
    setState(() {
      items[index].name = newName;
      items[index].value = newValue ?? 0.0;
      selectedItemIndex = -1;
      itemNameController.clear();
      itemValueController.clear();
      _saveItems();
    });
  }

  void _removeItem(int index) {
    setState(() {
      items.removeAt(index);
      selectedItemIndex = -1;
      _saveItems();
    });
  }

  void _toggleItem(int index) {
    setState(() {
      items[index].isComplete = !items[index].isComplete;

      if (items[index].isComplete) {
        final completedItem = items.removeAt(index);
        items.add(completedItem);
      }
      _saveItems();
    });
  }

  void _incrementQuantity(int index) {
    setState(() {
      items[index].quantity++;
      _saveItems();
    });
  }

  void _decrementQuantity(int index) {
    setState(() {
      if (items[index].quantity > 1) {
        items[index].quantity--;
        _saveItems();
      }
    });
  }
}

class ShoppingItem {
  String name;
  double value;
  bool isComplete;
  int quantity;

  ShoppingItem({required this.name, this.value = 0.0, this.isComplete = false, this.quantity = 1});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'isComplete': isComplete,
      'quantity': quantity,
    };
  }

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      name: json['name'],
      value: json['value'],
      isComplete: json['isComplete'],
      quantity: json['quantity'],
    );
  }
}

class DecimalTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text == '.' || newValue.text == ',') {
      return oldValue;
    }
    return newValue;
  }
}

class ShoppingList {
  String name;

  ShoppingList({required this.name});

  Map<String, dynamic> toJson() {
    return {'name': name};
  }

  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    return ShoppingList(name: json['name']);
  }
}
