// flutter_money/lib/paginas/historico/historico_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_money/modelos/receita.dart';
import 'package:flutter_money/modelos/despesa.dart';
import 'package:flutter_money/servicos/banco_dados.dart';

enum TipoTransacaoFiltro { todos, ganho, despesaFixa, despesaAvulsa }

class HistoricoPage extends StatefulWidget {
  const HistoricoPage({super.key});

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  DateTime _mesSelecionado = DateTime.now();
  TipoTransacaoFiltro _tipoFiltro = TipoTransacaoFiltro.todos;
  List<dynamic> _transacoes = [];
  bool _isLoading = true;
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _carregarTransacoes();
  }

  Future<void> _carregarTransacoes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Receita> receitas = await BancoDados.instancia.listarReceitas();
      List<Despesa> despesas = await BancoDados.instancia.listarDespesas();

      List<dynamic> transacoesFiltradas = [];

      for (var r in receitas) {
        if (r.data.year == _mesSelecionado.year &&
            r.data.month == _mesSelecionado.month) {
          transacoesFiltradas.add(r);
        }
      }

      for (var d in despesas) {
        if (d.dataVencimento.year == _mesSelecionado.year &&
            d.dataVencimento.month == _mesSelecionado.month) {
          transacoesFiltradas.add(d);
        }
      }

      if (_tipoFiltro == TipoTransacaoFiltro.ganho) {
        transacoesFiltradas = transacoesFiltradas.whereType<Receita>().toList();
      } else if (_tipoFiltro == TipoTransacaoFiltro.despesaFixa) {
        transacoesFiltradas = transacoesFiltradas
            .whereType<Despesa>()
            .where((d) => d.tipo == TipoDespesa.fixa)
            .toList();
      } else if (_tipoFiltro == TipoTransacaoFiltro.despesaAvulsa) {
        transacoesFiltradas = transacoesFiltradas
            .whereType<Despesa>()
            .where((d) => d.tipo == TipoDespesa.avulsa)
            .toList();
      }

      transacoesFiltradas.sort((a, b) {
        DateTime dataA = a is Receita ? a.data : (a as Despesa).dataVencimento;
        DateTime dataB = b is Receita ? b.data : (b as Despesa).dataVencimento;
        return dataB.compareTo(dataA);
      });

      setState(() {
        _transacoes = transacoesFiltradas;
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar transações: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar histórico: $e')));
    }
  }

  Future<bool> _verificarComprovanteVinculado(int idDespesa) async {
    final comprovantes = await BancoDados.instancia
        .listarComprovantesPorDespesa(idDespesa);
    return comprovantes.isNotEmpty;
  }

  Future<void> _selecionarMes(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _mesSelecionado,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDatePickerMode: DatePickerMode.year,
      locale: const Locale('pt', 'BR'),
    );

    if (picked != null && picked != _mesSelecionado) {
      setState(() {
        _mesSelecionado = picked;
      });
      _carregarTransacoes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Transações'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _selecionarMes(context),
          ),
          DropdownButton<TipoTransacaoFiltro>(
            value: _tipoFiltro,
            icon: const Icon(Icons.filter_list, color: Colors.white),
            underline: const SizedBox(),
            onChanged: (TipoTransacaoFiltro? newValue) {
              setState(() {
                _tipoFiltro = newValue!;
              });
              _carregarTransacoes();
            },
            items: const <DropdownMenuItem<TipoTransacaoFiltro>>[
              DropdownMenuItem(
                value: TipoTransacaoFiltro.todos,
                child: Text('Todos', style: TextStyle(color: Colors.black)),
              ),
              DropdownMenuItem(
                value: TipoTransacaoFiltro.ganho,
                child: Text('Ganhos', style: TextStyle(color: Colors.green)),
              ),
              DropdownMenuItem(
                value: TipoTransacaoFiltro.despesaFixa,
                child: Text(
                  'Despesas Fixas',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              DropdownMenuItem(
                value: TipoTransacaoFiltro.despesaAvulsa,
                child: Text(
                  'Despesas Avulsas',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transacoes.isEmpty
          ? Center(
              child: Text(
                'Nenhuma transação encontrada para ${DateFormat('MMMM y', 'pt_BR').format(_mesSelecionado)} com o filtro selecionado.',
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _transacoes.length,
              itemBuilder: (context, index) {
                final transacao = _transacoes[index];
                if (transacao is Receita) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ListTile(
                      leading: const Icon(
                        Icons.arrow_upward,
                        color: Colors.green,
                      ),
                      title: Text(transacao.descricao ?? 'Ganho'),
                      subtitle: Text(_dateFormat.format(transacao.data)),
                      trailing: Text(
                        _currencyFormat.format(transacao.valor),
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {},
                    ),
                  );
                } else if (transacao is Despesa) {
                  final despesa = transacao;
                  return FutureBuilder<bool>(
                    future: _verificarComprovanteVinculado(despesa.id!),
                    builder: (context, snapshot) {
                      bool temComprovante = snapshot.data ?? false;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ListTile(
                          leading: Icon(
                            Icons.arrow_downward,
                            color: despesa.tipo == TipoDespesa.fixa
                                ? Colors.red
                                : Colors.orange,
                          ),
                          title: Text(
                            despesa.nome ?? despesa.descricao ?? 'Despesa',
                          ),
                          subtitle: Text(
                            _dateFormat.format(despesa.dataVencimento),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currencyFormat.format(despesa.valor),
                                style: TextStyle(
                                  color: despesa.tipo == TipoDespesa.fixa
                                      ? Colors.red
                                      : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (temComprovante) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.attach_file,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                              ],
                            ],
                          ),
                          onTap: () {},
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
    );
  }
}
