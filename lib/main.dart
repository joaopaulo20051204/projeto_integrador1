import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:listadecompras/tela2.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(ListaDeCompras());
}

class ListaDeCompras extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista de Compras',
      initialRoute: '/',
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue,
        ),
        primaryColor: Colors.black,
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.black,
        ),
      ),
      routes: {
        '/': (context) => ListaComprasInicial(),
        '/novaLista': (context) => ListaCompras(),
        '/detalhesLista': (context) => ListaCompras(),
      },
    );
  }
}

class ListaComprasInicial extends StatefulWidget {
  @override
  _ListaComprasInicialState createState() => _ListaComprasInicialState();
}

class _ListaComprasInicialState extends State<ListaComprasInicial> {
  List<ShoppingList> lists = [];

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  void _loadLists() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final List<String>? listsData = prefs.getStringList('shoppingLists');
      lists = listsData?.map((listString) {
        final Map<String, dynamic> listMap = json.decode(listString);
        return ShoppingList.fromJson(listMap);
      }).toList() ?? [];
    });
  }

  void _saveLists() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> listsData = lists.map((list) => json.encode(list.toJson())).toList();
    prefs.setStringList('shoppingLists', listsData);
  }

  void _addList(String listName) {
    setState(() {
      final ShoppingList newList = ShoppingList(name: listName);
      lists.add(newList);
      _saveLists();
    });
  }

  void _removeList(int index) {
    setState(() {
      lists.removeAt(index);
      _saveLists();
    });
  }

  void _removeAllLists() {
    setState(() {
      lists.clear();
      _saveLists();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Compras'),
        actions: [
          PopupMenuButton<String>(
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'deleteAll',
                  child: Text('Deletar tudo'),
                ),
                PopupMenuItem<String>(
                  value: 'settings',
                  child: Text('Configurações'),
                ),
              ];
            },
            onSelected: (value) {
              if (value == 'deleteAll') {
                _removeAllLists();
              } else if (value == 'settings') {
                print('Configurações selecionadas');
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/fundo.png'), 
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: lists.length,
                itemBuilder: (context, index) {
                  return Dismissible(
                    key: UniqueKey(),
                    onDismissed: (direction) {
                      _removeList(index);
                    },
                    background: Container(
                      color: Colors.red,
                      child: Icon(Icons.delete, color: Colors.black),
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: 15.0),
                    ),
                    child: ListTile(
                      onTap: () {
                        Navigator.pushNamed(context, '/detalhesLista', arguments: lists[index]);
                      },
                      title: Text(lists[index].name),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return _buildAddListDialog();
            },
          );
        },
        child: Icon(
          Icons.add,
        ),
        shape: CircleBorder(),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildAddListDialog() {
    String newListName = '';

    return AlertDialog(
      title: Text('Adicionar Lista'),
      backgroundColor: Colors.white,
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              onChanged: (value) {
                newListName = value;
              },
              decoration: InputDecoration(
                hintText: 'Digite o nome da lista',
                prefixIcon: Icon(Icons.search),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
              ),
            ),
            SizedBox(height: 19.0),
            ElevatedButton(
              onPressed: () {
                _addList(newListName);
                Navigator.pop(context);
              },
              child: Text(
                'Adicionar',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
