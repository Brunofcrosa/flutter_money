import 'package:flutter/material.dart';
import 'package:flutter_money/paginas/autenticacao/login.dart';
import 'package:flutter_money/servicos/banco_dados.dart';

class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _senhaAtualController = TextEditingController();
  final TextEditingController _novaSenhaController = TextEditingController();
  final TextEditingController _confirmaNovaSenhaController =
      TextEditingController();

  Future<void> _alterarSenha() async {
    if (_formKey.currentState!.validate()) {
      print('Senha atual: ${_senhaAtualController.text}');
      print('Nova senha: ${_novaSenhaController.text}');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha alterada com sucesso (simulado)!')),
      );

      _senhaAtualController.clear();
      _novaSenhaController.clear();
      _confirmaNovaSenhaController.clear();
    }
  }

  Future<void> _exportarDados() async {
    try {
      final receitas = await BancoDados.instancia.listarReceitas();
      final despesas = await BancoDados.instancia.listarDespesas();
      final comprovantes = await BancoDados.instancia.listarComprovantes();

      print('Receitas para exportar: ${receitas.length}');
      print('Despesas para exportar: ${despesas.length}');
      print('Comprovantes para exportar: ${comprovantes.length}');

      String csvContent = "Tipo,Nome/Descricao,Valor,Data\n";
      for (var r in receitas) {
        csvContent +=
            "Ganho,${r.descricao ?? ''},${r.valor},${r.data.toIso8601String().split('T')[0]}\n";
      }
      for (var d in despesas) {
        csvContent +=
            "Despesa,${d.nome ?? d.descricao ?? ''},${d.valor},${d.dataVencimento.toIso8601String().split('T')[0]}\n";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dados exportados com sucesso (simulado)!'),
        ),
      );
    } catch (e) {
      print('Erro ao exportar dados: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao exportar dados: $e')));
    }
  }

  void _sairDaConta() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const Login()),
      (Route<dynamic> route) => false,
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Você saiu da sua conta.')));
  }

  @override
  void dispose() {
    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    _confirmaNovaSenhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alterar Senha',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _senhaAtualController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Senha Atual',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, digite sua senha atual.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _novaSenhaController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Nova Senha',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, digite sua nova senha.';
                          }
                          if (value.length < 6) {
                            return 'A nova senha deve ter no mínimo 6 caracteres.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmaNovaSenhaController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirmar Nova Senha',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, confirme sua nova senha.';
                          }
                          if (value != _novaSenhaController.text) {
                            return 'As senhas não coincidem.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _alterarSenha,
                          child: const Text('Salvar Nova Senha'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.download),
                    title: const Text('Exportar Dados'),
                    onTap: _exportarDados,
                  ),
                  const Divider(height: 0),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'Sair da Conta',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: _sairDaConta,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
