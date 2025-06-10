// lib/paginas/historico/historico.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_money/paginas/historico/selecionar_mes.dart';
import 'package:flutter_money/servicos/banco_dados.dart';
import 'package:flutter_money/modelos/receita.dart';
import 'package:flutter_money/modelos/despesa.dart';
import 'package:flutter_money/paginas/receitas/formulario_receitas.dart'; // Importe para edição
import 'package:flutter_money/paginas/despesas/formulario_despesas.dart'; // Importe para edição

class HistoricoPage extends StatefulWidget {
  const HistoricoPage({super.key});

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  DateTime _mesSelecionado = DateTime.now();
  List<dynamic> _itens = []; // Lista para receitas e despesas
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarItensDoMes();
  }

  // Carrega as receitas e despesas do mês selecionado
  Future<void> _carregarItensDoMes() async {
    setState(() {
      _isLoading = true;
      _itens = []; // Limpa a lista antes de recarregar
    });

    try {
      final todasReceitas = await BancoDados.instancia
          .listarReceitas(); // Busca todas as receitas
      final todasDespesas = await BancoDados.instancia
          .listarDespesas(); // Busca todas as despesas

      // Filtra receitas do mês e ano selecionados
      final receitasDoMes = todasReceitas.where((r) {
        return r.data.month == _mesSelecionado.month &&
            r.data.year == _mesSelecionado.year;
      }).toList();

      // Filtra despesas do mês e ano selecionados
      final despesasDoMes = todasDespesas.where((d) {
        return d.dataVencimento.month == _mesSelecionado.month &&
            d.dataVencimento.year == _mesSelecionado.year;
      }).toList();

      setState(() {
        _itens = [...receitasDoMes, ...despesasDoMes]; // Combina as listas
        // Ordena por data, receitas primeiro, depois despesas.
        // Ou você pode definir uma ordem diferente, como a mais recente primeiro, independente do tipo.
        _itens.sort((a, b) {
          DateTime dataA = (a is Receita)
              ? a.data
              : (a as Despesa).dataVencimento;
          DateTime dataB = (b is Receita)
              ? b.data
              : (b as Despesa).dataVencimento;
          return dataB.compareTo(
            dataA,
          ); // Ordena da mais recente para a mais antiga
        });
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar itens: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar histórico: $e')));
    }
  }

  // Exibe um diálogo de confirmação antes de remover um item
  Future<void> _confirmarRemocao(int id, String tipoItem) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Usuário deve tocar no botão
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Remover $tipoItem?'),
          content: Text('Tem certeza que deseja remover este $tipoItem?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Remover', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Fecha o diálogo
                await _removerItem(id, tipoItem); // Chama a função de remoção
              },
            ),
          ],
        );
      },
    );
  }

  // Remove o item do banco de dados e recarrega a lista
  Future<void> _removerItem(int id, String tipoItem) async {
    try {
      if (tipoItem == 'receita') {
        await BancoDados.instancia.removerReceita(id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receita removida com sucesso!')),
        );
      } else if (tipoItem == 'despesa') {
        await BancoDados.instancia.removerDespesa(id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Despesa removida com sucesso!')),
        );
      }
      _carregarItensDoMes(); // Recarrega a lista após a remoção
    } catch (e) {
      print('Erro ao remover $tipoItem: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao remover $tipoItem: $e')));
    }
  }

  // Navega para o formulário de edição ou criação de item
  void _navegarParaFormulario({dynamic item}) async {
    if (item is Receita) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FormularioReceitas(receitaParaEdicao: item),
        ),
      );
    } else if (item is Despesa) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FormularioDespesas(
            tipoDespesa: item.tipo,
            despesaParaEdicao: item,
          ),
        ),
      );
    }
    _carregarItensDoMes(); // Recarrega a lista ao retornar do formulário
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Histórico de Transações',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Color(0xFF00C853)),
            onPressed: () async {
              final DateTime? pickedDate = await showDialog<DateTime>(
                context: context,
                builder: (BuildContext context) {
                  return Dialog(
                    child: SizedBox(
                      width:
                          300, // Largura fixa para o seletor de mês no diálogo
                      height:
                          400, // Altura fixa para o seletor de mês no diálogo
                      child: MonthSelector(
                        initialDate: _mesSelecionado,
                        onMonthSelected: (newDate) {
                          Navigator.of(
                            context,
                          ).pop(newDate); // Retorna a data selecionada
                        },
                        onYearChanged: (newDate) {
                          // Se o ano mudar, recarrega o seletor para o novo ano
                          setState(() {
                            _mesSelecionado = newDate;
                          });
                        },
                      ),
                    ),
                  );
                },
              );

              if (pickedDate != null && pickedDate != _mesSelecionado) {
                setState(() {
                  _mesSelecionado = pickedDate;
                });
                _carregarItensDoMes(); // Recarrega os itens para o novo mês/ano
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    DateFormat('MMMM y', 'pt_BR').format(_mesSelecionado),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: _itens.isEmpty
                      ? const Center(
                          child: Text('Nenhuma transação neste mês.'),
                        )
                      : ListView.builder(
                          itemCount: _itens.length,
                          itemBuilder: (context, index) {
                            final item = _itens[index];
                            if (item is Receita) {
                              return _buildReceitaCard(item);
                            } else if (item is Despesa) {
                              return _buildDespesaCard(item);
                            }
                            return const SizedBox.shrink(); // Caso algum tipo inesperado
                          },
                        ),
                ),
              ],
            ),
    );
  }

  // Constrói o Card para um item de Receita
  Widget _buildReceitaCard(Receita receita) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.arrow_upward, color: Colors.green),
        title: Text(
          receita.descricao?.isNotEmpty == true
              ? receita.descricao!
              : 'Receita sem descrição',
        ),
        subtitle: Text(DateFormat('dd/MM/yyyy').format(receita.data)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'R\$ ${receita.valor.toStringAsFixed(2).replaceAll('.', ',')}',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _navegarParaFormulario(item: receita),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () => _confirmarRemocao(receita.id!, 'receita'),
            ),
          ],
        ),
      ),
    );
  }

  // Constrói o Card para um item de Despesa
  Widget _buildDespesaCard(Despesa despesa) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.arrow_downward, color: Colors.red),
        title: Text(
          despesa.nome?.isNotEmpty == true
              ? despesa.nome!
              : despesa.descricao?.isNotEmpty == true
              ? despesa.descricao!
              : 'Despesa sem descrição',
        ),
        subtitle: Text(
          'Vencimento: ${DateFormat('dd/MM/yyyy').format(despesa.dataVencimento)}'
          '${despesa.numParcelas != null && despesa.numParcelas! > 1 ? ' (${despesa.numParcelas}x)' : ''}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'R\$ ${despesa.valor.toStringAsFixed(2).replaceAll('.', ',')}',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _navegarParaFormulario(item: despesa),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () => _confirmarRemocao(despesa.id!, 'despesa'),
            ),
          ],
        ),
      ),
    );
  }
}
