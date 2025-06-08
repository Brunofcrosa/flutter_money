import 'package:flutter/material.dart';
import 'package:flutter_money/paginas/receitas/formulario_receitas.dart';
import 'package:flutter_money/paginas/despesas/formulario_despesas.dart';
import 'package:flutter_money/modelos/despesa.dart';
import 'package:flutter_money/servicos/banco_dados.dart';
import 'package:flutter_money/paginas/comprovantes/comprovantes.dart';
import 'package:flutter_money/paginas/historico/historico.dart';
import 'package:flutter_money/paginas/configuracoes/configuracoes.dart';
import 'package:intl/intl.dart';

class Painel extends StatefulWidget {
  const Painel({super.key});

  @override
  State<Painel> createState() => _PainelState();
}

class _PainelState extends State<Painel> {
  double _totalGanhos = 0.0;
  double _totalDespesasFixas = 0.0;
  double _totalDespesasAvulsas = 0.0;
  double _saldoAtual = 0.0;
  bool _isLoading = true;
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  @override
  void initState() {
    super.initState();
    _carregarDadosDashboard();
  }

  Future<void> _carregarDadosDashboard() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final receitas = await BancoDados.instancia.listarReceitas();
      final despesas = await BancoDados.instancia.listarDespesas();

      double ganhos = 0.0;
      double despesasFixas = 0.0;
      double despesasAvulsas = 0.0;

      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;

      for (var r in receitas) {
        if (r.data.month == currentMonth && r.data.year == currentYear) {
          ganhos += r.valor;
        }
      }

      for (var d in despesas) {
        if (d.dataVencimento.month == currentMonth &&
            d.dataVencimento.year == currentYear) {
          if (d.tipo == TipoDespesa.fixa) {
            despesasFixas += d.valor;
          } else {
            despesasAvulsas += d.valor;
          }
        }
      }

      setState(() {
        _totalGanhos = ganhos;
        _totalDespesasFixas = despesasFixas;
        _totalDespesasAvulsas = despesasAvulsas;
        _saldoAtual =
            _totalGanhos - (_totalDespesasFixas + _totalDespesasAvulsas);
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar dados do dashboard: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Financeira'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConfiguracoesPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarDadosDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildResumoFinanceiro(),
                    const SizedBox(height: 24),
                    _buildBotoesPrincipais(context),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildResumoFinanceiro() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo de ${DateFormat.MMMMEEEEd('pt_BR').format(DateTime.now())}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            _buildResumoItem('Total de Ganhos:', _totalGanhos, Colors.green),
            _buildResumoItem(
              'Total de Despesas Fixas:',
              _totalDespesasFixas,
              Colors.red,
            ),
            _buildResumoItem(
              'Total de Despesas Avulsas:',
              _totalDespesasAvulsas,
              Colors.orange,
            ),
            const Divider(height: 20),
            _buildResumoItem(
              'Saldo Atual:',
              _saldoAtual,
              _saldoAtual >= 0 ? Colors.blue : Colors.red.shade700,
              isSaldo: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoItem(
    String titulo,
    double valor,
    Color cor, {
    bool isSaldo = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSaldo ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            _currencyFormat.format(valor),
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSaldo ? FontWeight.bold : FontWeight.normal,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotoesPrincipais(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16.0,
      mainAxisSpacing: 16.0,
      children: [
        _construirBotaoAcao(
          context,
          Icons.add,
          'Adicionar Ganho',
          Colors.green.shade100,
          () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FormularioReceitas(),
              ),
            );
            _carregarDadosDashboard();
          },
        ),
        _construirBotaoAcao(
          context,
          Icons.remove,
          'Adicionar Despesa',
          Colors.red.shade100,
          () async {
            _mostrarOpcoesDespesa(context);
            _carregarDadosDashboard();
          },
        ),
        _construirBotaoAcao(
          context,
          Icons.camera_alt,
          'Capturar Nota Fiscal',
          Colors.blue.shade100,
          () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ComprovantesPage()),
            );
          },
        ),
        _construirBotaoAcao(
          context,
          Icons.history,
          'Ver Histórico',
          Colors.purple.shade100,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistoricoPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _construirBotaoAcao(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.black87),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarOpcoesDespesa(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Tipo de Despesa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Despesa Fixa / Parcelada'),
                onTap: () {
                  Navigator.of(dialogContext).pop();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FormularioDespesas(
                        tipoDespesa: TipoDespesa.fixa,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.shopping_cart),
                title: const Text('Despesa Avulsa'),
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FormularioDespesas(
                        tipoDespesa: TipoDespesa.avulsa,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
