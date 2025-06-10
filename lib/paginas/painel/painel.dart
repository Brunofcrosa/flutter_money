// lib/paginas/painel/painel.dart
import 'package:flutter/material.dart';
import 'package:flutter_money/paginas/receitas/formulario_receitas.dart';
import 'package:flutter_money/paginas/despesas/formulario_despesas.dart';
import 'package:flutter_money/modelos/despesa.dart';
import 'package:flutter_money/servicos/banco_dados.dart';
import 'package:flutter_money/paginas/configuracoes/configuracoes.dart';
import 'package:intl/intl.dart';
import 'package:flutter_money/componentes/grafico.dart'; // Importa o novo widget GraficoPizza

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
        leading: IconButton(
          icon: const Icon(
            Icons.settings,
            color: Color(
              0xFF00C853,
            ), // Cor verde exata da imagem para a engrenagem
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ConfiguracoesPage(),
              ),
            );
          },
        ),
        title: const Text(
          'Saldo do mês atual',
          style: TextStyle(
            color: Colors.black, // Título preto
            fontWeight: FontWeight.bold,
            fontSize: 20, // Ajuste de tamanho para o título
          ),
        ),
        centerTitle: true, // Centraliza o título no AppBar
        actions: [
          IconButton(
            icon: const Icon(
              Icons.person,
              color: Color(
                0xFF00C853,
              ), // Cor verde exata da imagem para o ícone de pessoa
            ),
            onPressed: () {
              // TODO: Implementar navegação para a tela de perfil do usuário
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Funcionalidade de perfil em desenvolvimento.'),
                ),
              );
            },
          ),
        ],
        backgroundColor: Colors.white, // Fundo branco para o AppBar
        elevation: 0, // Remove a sombra abaixo da AppBar
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            ) // Exibe indicador de carregamento
          : RefreshIndicator(
              onRefresh:
                  _carregarDadosDashboard, // Permite "puxar para atualizar"
              child: SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(), // Garante que pode rolar mesmo com pouco conteúdo
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment
                      .center, // Centraliza elementos na coluna
                  children: [
                    // Seção do gráfico de pizza e informações de saldo
                    _buildSecaoGraficoSaldo(),
                    const SizedBox(
                      height: 40,
                    ), // Espaço entre o gráfico e os botões
                    // Seção dos botões de ação (Adicionar Ganho/Despesa)
                    _buildBotoesAcaoPrincipais(),
                  ],
                ),
              ),
            ),
    );
  }

  // Constrói a seção visual do gráfico de pizza e os valores de saldo.
  // Observação: Este é um gráfico SIMULADO usando CustomPaint. Para gráficos reais e interativos,
  // seriam necessárias bibliotecas como `fl_chart` ou `charts_flutter`.
  Widget _buildSecaoGraficoSaldo() {
    return Stack(
      alignment: Alignment.center, // Centraliza os filhos da Stack
      children: [
        GraficoPizza(
          // Usando o novo widget GraficoPizza
          saldo: _saldoAtual,
          totalDespesasFixas: _totalDespesasFixas,
          totalDespesasAvulsas: _totalDespesasAvulsas,
          currencyFormat: _currencyFormat,
        ),
        Text(
          _currencyFormat.format(_saldoAtual), // Valor do saldo atual no centro
          style: const TextStyle(
            fontSize: 17, // Mantém o tamanho do texto central
            fontWeight: FontWeight.bold,
            color: Colors.black, // Cor do texto do saldo
          ),
        ),
      ],
    );
  }

  // Constrói os botões principais de ação (Adicionar Ganho e Adicionar Despesa).
  Widget _buildBotoesAcaoPrincipais() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment
              .spaceEvenly, // Distribui o espaço igualmente entre os botões
          children: [
            // Botão para adicionar ganho
            _construirBotaoAcao(
              context,
              Icons.add,
              'Adicionar\nGanho Extra', // Texto em duas linhas
              const Color(0xFFC8E6C9), // Fundo verde claro para ganho
              () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FormularioReceitas(),
                  ),
                ).then(
                  (_) => _carregarDadosDashboard(),
                ); // Recarrega o dashboard ao retornar
              },
              iconColor: const Color(0xFF00C853), // Ícone verde forte
              textColor: Colors.black, // Texto preto
            ),
            // Botão para adicionar despesa
            _construirBotaoAcao(
              context,
              Icons.remove,
              'Adicionar\nDespesa', // Texto em duas linhas
              const Color(0xFFFFCDD2), // Fundo vermelho claro para despesa
              () {
                _mostrarOpcoesDespesa(
                  context,
                ); // Mostra diálogo de opções de despesa
              },
              iconColor: const Color(0xFFD32F2F), // Ícone vermelho forte
              textColor: Colors.black, // Texto preto
            ),
          ],
        ),
      ],
    );
  }

  // Função utilitária para construir botões de ação com estilo customizado.
  Widget _construirBotaoAcao(
    BuildContext context,
    IconData icon,
    String label,
    Color backgroundColor,
    VoidCallback onTap, {
    Color? iconColor,
    Color? textColor,
  }) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: backgroundColor,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 20.0,
              horizontal: 10.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: iconColor ?? Colors.black87),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Exibe um diálogo para o usuário escolher o tipo de despesa (Fixa/Parcelada ou Avulsa).
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
                  ).then((_) => _carregarDadosDashboard());
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
                  ).then((_) => _carregarDadosDashboard());
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
