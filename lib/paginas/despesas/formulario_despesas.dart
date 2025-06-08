// flutter_money/lib/paginas/despesas/formulario_despesas.dart
import 'package:flutter/material.dart';
import 'package:flutter_money/modelos/despesa.dart';
import 'package:flutter_money/servicos/banco_dados.dart';
import 'package:intl/intl.dart';

class FormularioDespesas extends StatefulWidget {
  final TipoDespesa tipoDespesa;
  final Despesa? despesaParaEdicao;

  const FormularioDespesas({
    super.key,
    required this.tipoDespesa,
    this.despesaParaEdicao,
  });

  @override
  State<FormularioDespesas> createState() => _FormularioDespesasState();
}

class _FormularioDespesasState extends State<FormularioDespesas> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeDespesaController = TextEditingController();
  final TextEditingController _valorDespesaController = TextEditingController();
  final TextEditingController _numParcelasController = TextEditingController();
  final TextEditingController _dataVencimentoController =
      TextEditingController();
  final TextEditingController _descricaoDespesaAvulsaController =
      TextEditingController();

  DateTime _dataSelecionada = DateTime.now();

  @override
  void initState() {
    super.initState();

    if (widget.despesaParaEdicao != null) {
      final despesa = widget.despesaParaEdicao!;
      _nomeDespesaController.text = despesa.nome ?? '';

      _valorDespesaController.text = NumberFormat.currency(
        locale: 'pt_BR',
        symbol: '',
        decimalDigits: 2,
      ).format(despesa.valor);
      _numParcelasController.text = despesa.numParcelas?.toString() ?? '';
      _dataSelecionada = despesa.dataVencimento;
      _dataVencimentoController.text = DateFormat(
        'dd/MM/yyyy',
      ).format(_dataSelecionada);
      _descricaoDespesaAvulsaController.text = despesa.descricao ?? '';
    } else {
      _dataVencimentoController.text = DateFormat(
        'dd/MM/yyyy',
      ).format(DateTime.now());
    }
  }

  @override
  void dispose() {
    _nomeDespesaController.dispose();
    _valorDespesaController.dispose();
    _numParcelasController.dispose();
    _dataVencimentoController.dispose();
    _descricaoDespesaAvulsaController.dispose();
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
        _dataVencimentoController.text = DateFormat(
          'dd/MM/yyyy',
        ).format(_dataSelecionada);
      });
    }
  }

  void _salvarDespesa() async {
    if (_formKey.currentState!.validate()) {
      String valorText = _valorDespesaController.text
          .replaceAll('R\$', '')
          .replaceAll('.', '')
          .replaceAll(',', '.')
          .trim();
      double? valor = double.tryParse(valorText);

      if (valor == null || valor <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Por favor, insira um valor positivo e válido para a despesa.',
            ),
          ),
        );
        return;
      }

      Despesa novaDespesa;
      if (widget.tipoDespesa == TipoDespesa.fixa) {
        int? numParcelas;

        if (_numParcelasController.text.isNotEmpty) {
          numParcelas = int.tryParse(_numParcelasController.text);
          if (numParcelas == null || numParcelas <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Número de parcelas inválido. Insira um número inteiro positivo.',
                ),
              ),
            );
            return;
          }
        }

        if (_nomeDespesaController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Por favor, insira um nome para a despesa fixa.'),
            ),
          );
          return;
        }

        novaDespesa = Despesa(
          id: widget.despesaParaEdicao?.id,
          nome: _nomeDespesaController.text.trim(),
          valor: valor,
          numParcelas: numParcelas,
          dataVencimento: _dataSelecionada,
          tipo: TipoDespesa.fixa,
        );
      } else {
        if (_descricaoDespesaAvulsaController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Por favor, insira uma descrição para a despesa avulsa.',
              ),
            ),
          );
          return;
        }

        novaDespesa = Despesa(
          id: widget.despesaParaEdicao?.id,
          valor: valor,
          descricao: _descricaoDespesaAvulsaController.text.trim(),
          dataVencimento: _dataSelecionada,
          tipo: TipoDespesa.avulsa,
        );
      }

      try {
        if (widget.despesaParaEdicao == null) {
          await BancoDados.instancia.inserirDespesa(novaDespesa);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Despesa salva com sucesso!')),
          );
        } else {
          await BancoDados.instancia.atualizarDespesa(novaDespesa);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Despesa atualizada com sucesso!')),
          );
        }

        Navigator.of(context).pop();
      } catch (e) {
        print('Erro ao salvar despesa: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao salvar despesa: $e. Verifique os dados e tente novamente.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.tipoDespesa == TipoDespesa.fixa
              ? (widget.despesaParaEdicao == null
                    ? 'Nova Despesa Fixa/Parcelada'
                    : 'Editar Despesa Fixa/Parcelada')
              : (widget.despesaParaEdicao == null
                    ? 'Nova Despesa Avulsa'
                    : 'Editar Despesa Avulsa'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.tipoDespesa == TipoDespesa.fixa) ...[
                TextFormField(
                  controller: _nomeDespesaController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da Despesa (ex: Aluguel, Celular)',
                    prefixIcon: Icon(Icons.description),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, insira o nome da despesa.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ] else if (widget.tipoDespesa == TipoDespesa.avulsa) ...[
                TextFormField(
                  controller: _descricaoDespesaAvulsaController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descrição (ex: Mercado, Uber)',
                    hintText: 'Detalhes da despesa avulsa',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.short_text),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, insira uma descrição para a despesa.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _valorDespesaController,
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
                  final cleanValue = value
                      .replaceAll('.', '')
                      .replaceAll(',', '.');
                  if (double.tryParse(cleanValue) == null) {
                    return 'Valor inválido. Use números e vírgula/ponto.';
                  }
                  if (double.parse(cleanValue) <= 0) {
                    return 'O valor deve ser positivo.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (widget.tipoDespesa == TipoDespesa.fixa) ...[
                TextFormField(
                  controller: _numParcelasController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Número de Parcelas (deixe vazio para 1)',
                    hintText: 'Ex: 12 ou 1',
                    prefixIcon: Icon(Icons.format_list_numbered),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (int.tryParse(value) == null ||
                          int.parse(value) <= 0) {
                        return 'Número de parcelas inválido. Deve ser um número inteiro positivo.';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => _selecionarData(context),
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _dataVencimentoController,
                      decoration: const InputDecoration(
                        labelText: 'Data do Vencimento da 1ª Parcela',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, selecione a data de vencimento.';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ] else if (widget.tipoDespesa == TipoDespesa.avulsa) ...[
                GestureDetector(
                  onTap: () => _selecionarData(context),
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _dataVencimentoController,
                      decoration: const InputDecoration(
                        labelText: 'Data da Despesa',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, selecione a data da despesa.';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _salvarDespesa,
                  child: const Text('Salvar Despesa'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
