import 'package:flutter/material.dart';
import 'package:flutter_money/modelos/receita.dart';
import 'package:flutter_money/servicos/banco_dados.dart';
import 'package:intl/intl.dart';

class FormularioReceitas extends StatefulWidget {
  final Receita? receitaParaEdicao;

  const FormularioReceitas({super.key, this.receitaParaEdicao});

  @override
  State<FormularioReceitas> createState() => _FormularioReceitasState();
}

class _FormularioReceitasState extends State<FormularioReceitas> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _dataController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();

  DateTime _dataSelecionada = DateTime.now();

  @override
  void initState() {
    super.initState();

    if (widget.receitaParaEdicao != null) {
      _valorController.text = widget.receitaParaEdicao!.valor
          .toStringAsFixed(2)
          .replaceAll('.', ',');
      _dataSelecionada = widget.receitaParaEdicao!.data;
      _dataController.text = DateFormat('dd/MM/yyyy').format(_dataSelecionada);
      _descricaoController.text = widget.receitaParaEdicao!.descricao ?? '';
    } else {
      _dataController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    }
  }

  @override
  void dispose() {
    _valorController.dispose();
    _dataController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null && picked != _dataSelecionada) {
      setState(() {
        _dataSelecionada = picked;
        _dataController.text = DateFormat(
          'dd/MM/yyyy',
        ).format(_dataSelecionada);
      });
    }
  }

  void _salvarReceita() async {
    if (_formKey.currentState!.validate()) {
      double valor =
          double.tryParse(_valorController.text.replaceAll(',', '.')) ?? 0.0;
      if (valor <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('O valor da receita deve ser positivo.'),
          ),
        );
        return;
      }

      final novaReceita = Receita(
        id: widget.receitaParaEdicao?.id,
        valor: valor,
        data: _dataSelecionada,
        descricao: _descricaoController.text.trim(),
      );

      try {
        if (widget.receitaParaEdicao == null) {
          await BancoDados.instancia.inserirReceita(novaReceita);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Receita salva com sucesso!')),
          );
        } else {
          await BancoDados.instancia.atualizarReceita(novaReceita);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Receita atualizada com sucesso!')),
          );
        }
        Navigator.of(context).pop();
      } catch (e) {
        print('Erro ao salvar receita: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao salvar receita: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.receitaParaEdicao == null
              ? 'Nova Receita (Ganho)'
              : 'Editar Receita (Ganho)',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _valorController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  prefixText: 'R\$ ',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o valor.';
                  }
                  if (double.tryParse(value.replaceAll(',', '.')) == null) {
                    return 'Valor inválido. Use números e vírgula/ponto.';
                  }
                  if (double.parse(value.replaceAll(',', '.')) <= 0) {
                    return 'O valor deve ser positivo.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _selecionarData(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _dataController,
                    decoration: const InputDecoration(
                      labelText: 'Data',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, selecione a data.';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  hintText: 'Ex: Salário, Venda de item, Freelance',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _salvarReceita,
                  child: const Text('Salvar Receita'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
