// lib/paginas/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_money/paginas/painel/painel.dart'; //
import 'package:flutter_money/paginas/historico/historico.dart'; //
import 'package:flutter_money/paginas/comprovantes/comprovantes.dart'; //

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 1; // Inicia na aba "Home" (Painel)

  // Lista dos widgets/páginas que serão exibidos conforme a seleção na barra de navegação.
  static final List<Widget> _widgetOptions = <Widget>[
    const HistoricoPage(), // Index 0: Histórico
    const Painel(), // Index 1: Painel (Home)
    const ComprovantesPage(), // Index 2: Comprovantes
  ];

  // Função chamada quando um item da BottomNavigationBar é tocado.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Atualiza o índice selecionado
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // O corpo do Scaffold muda de acordo com o item selecionado na BottomNavigationBar.
      // A AppBar é definida dentro de cada página individualmente para maior flexibilidade
      // e para permitir que cada página tenha seu próprio título e ações.
      body: Center(
        child: _widgetOptions.elementAt(
          _selectedIndex,
        ), // Exibe o widget correspondente ao índice
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(
              Icons.calendar_month,
            ), // Ícone para Histórico (calendário)
            label: 'Histórico',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home), // Ícone para Home (casa)
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.receipt,
            ), // Ícone para Comprovantes (recibo) - mais adequado que 'history'
            label: 'Comprovantes',
          ),
        ],
        currentIndex: _selectedIndex, // O item atualmente selecionado
        selectedItemColor:
            Colors.green[800], // Cor do ícone e label do item selecionado
        unselectedItemColor: Colors
            .grey[600], // Cor dos ícones e labels dos itens não selecionados
        onTap: _onItemTapped, // Callback quando um item é tocado
      ),
    );
  }
}
