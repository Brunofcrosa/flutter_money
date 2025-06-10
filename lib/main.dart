// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_money/paginas/autenticacao/login.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_money/servicos/banco_dados.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Garante que o banco de dados seja inicializado antes de iniciar o app.
  // Essencial para operações de banco de dados no startup.
  await BancoDados.instancia.database;

  // Inicializa os dados de formatação de data e hora para a localidade pt_BR.
  // Isso é importante para o `intl` funcionar corretamente com datas em português.
  await initializeDateFormatting('pt_BR', null);

  runApp(const FlutterMoney());
}

class FlutterMoney extends StatelessWidget {
  const FlutterMoney({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App de Finanças',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey, // Define a cor primária para o tema
        visualDensity: VisualDensity
            .adaptivePlatformDensity, // Adapta a densidade visual à plataforma
        appBarTheme: const AppBarTheme(
          backgroundColor:
              Colors.white, // Fundo da AppBar branco para combinar com a imagem
          foregroundColor:
              Colors.black, // Cor dos ícones e texto da AppBar preto
          elevation: 0, // Remove a sombra da AppBar para um visual mais clean
        ),
      ),
      home:
          const Login(), // Define a tela de Login como a tela inicial do aplicativo
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('pt', 'BR'),
      ], // Suporte a internacionalização
    );
  }
}
