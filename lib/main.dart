import 'package:flutter/material.dart';
import 'package:flutter_money/paginas/autenticacao/login.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_money/servicos/banco_dados.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await BancoDados.instancia.database;

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
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const Login(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('pt', 'BR')],
    );
  }
}
