import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Um widget seletor de mês e ano.
///
/// Permite ao usuário navegar entre anos e selecionar meses específicos.
class MonthSelector extends StatefulWidget {
  /// O mês e ano atualmente selecionados.
  final DateTime initialDate;

  /// Callback chamado quando um novo mês é selecionado.
  final ValueChanged<DateTime> onMonthSelected;

  /// Callback chamado quando o ano é alterado.
  final ValueChanged<DateTime> onYearChanged;

  const MonthSelector({
    super.key,
    required this.initialDate,
    required this.onMonthSelected,
    required this.onYearChanged,
  });

  @override
  State<MonthSelector> createState() => _MonthSelectorState();
}

class _MonthSelectorState extends State<MonthSelector> {
  // Mês e ano atualmente selecionados dentro deste widget.
  late DateTime _currentSelectedDate;

  // Formatador de data para exibir os nomes dos meses.
  final DateFormat _monthNameFormat = DateFormat.MMMM('pt_BR');

  @override
  void initState() {
    super.initState();
    _currentSelectedDate = widget.initialDate;
  }

  @override
  void didUpdateWidget(covariant MonthSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Atualiza a data interna se a data inicial do widget for alterada externamente.
    if (widget.initialDate != oldWidget.initialDate) {
      _currentSelectedDate = widget.initialDate;
    }
  }

  /// Altera o ano exibido e notifica o callback [onYearChanged].
  void _changeYear(int delta) {
    setState(() {
      _currentSelectedDate = DateTime(
        _currentSelectedDate.year + delta,
        _currentSelectedDate.month, // Mantém o mês ao mudar o ano
      );
    });
    widget.onYearChanged(_currentSelectedDate);
  }

  /// Seleciona um mês específico e notifica o callback [onMonthSelected].
  void _selectMonth(int month) {
    setState(() {
      _currentSelectedDate = DateTime(_currentSelectedDate.year, month);
    });
    widget.onMonthSelected(_currentSelectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Removida a largura fixa de 120 pixels.
      // Agora, o MonthSelector vai se ajustar ao espaço disponível.
      // Se ele for o único filho de um Center, ele se centralizará e terá largura intrínseca.
      // Se ele for filho de um Expanded, ele preencherá o Expanded.
      // Neste caso, como é filho de Center, ele usará a largura de seus filhos (a lista de meses).
      color: Colors.grey[100], // Cor de fundo para a barra lateral
      child: Column(
        mainAxisSize: MainAxisSize
            .min, // Faz a coluna ocupar o mínimo de espaço horizontal necessário
        children: [
          // Navegação de ano
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 18),
                  onPressed: () => _changeYear(-1), // Ano anterior
                ),
                Text(
                  _currentSelectedDate.year.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 18),
                  onPressed: () => _changeYear(1), // Próximo ano
                ),
              ],
            ),
          ),
          // Expanded para a ListView.builder:
          // Como MonthSelector não está mais dentro de um Row ou Column com outros Expandeds,
          // o Expanded aqui pode tentar ocupar todo o espaço vertical restante.
          // Para evitar isso e garantir que a lista de meses não se expanda infinitamente
          // se não estiver dentro de um layout restritivo, é comum envolver o ListView.builder
          // em um SizedBox ou Container com altura limitada, ou garantir que o pai tenha altura.
          // No entanto, se o MonthSelector é o único conteúdo do body, ele pode se expandir.
          // Para o propósito de preencher a tela sem overflow e ser o foco,
          // manter o Expanded é geralmente ok se a tela é grande o suficiente.
          Expanded(
            child: ListView.builder(
              itemCount: 12, // 12 meses
              itemBuilder: (context, index) {
                final monthNumber = index + 1;
                final monthName = _monthNameFormat.format(
                  DateTime(_currentSelectedDate.year, monthNumber),
                );
                final isSelected = _currentSelectedDate.month == monthNumber;

                return GestureDetector(
                  onTap: () => _selectMonth(monthNumber),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.green[100] : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.green : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        monthName.toUpperCase(),
                        style: TextStyle(
                          color: isSelected
                              ? Colors.green[800]
                              : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
