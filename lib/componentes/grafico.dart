// lib/componentes/grafico.dart (antigo pie_chart_painter.dart)
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui' as ui; // Para acessar ui.TextDirection
import 'package:intl/intl.dart';

// Novo widget que encapsula a lógica de cálculo e visualização do gráfico.
class GraficoPizza extends StatelessWidget {
  final double saldo;
  final double totalDespesasFixas;
  final double totalDespesasAvulsas;
  final NumberFormat currencyFormat;

  const GraficoPizza({
    super.key,
    required this.saldo,
    required this.totalDespesasFixas,
    required this.totalDespesasAvulsas,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    // Calculo das proporções para o gráfico
    // O total movimentado para calcular as proporções das "fatias" do gráfico
    // Agora, o total para o gráfico será a soma absoluta de todos os valores.
    final totalParaGrafico =
        totalDespesasFixas.abs() + totalDespesasAvulsas.abs() + saldo.abs();

    double percentualDespesasFixas = totalParaGrafico > 0
        ? (totalDespesasFixas / totalParaGrafico)
        : 0;
    double percentualDespesasAvulsas = totalParaGrafico > 0
        ? (totalDespesasAvulsas / totalParaGrafico)
        : 0;
    double percentualSaldo = saldo > 0 && totalParaGrafico > 0
        ? (saldo / totalParaGrafico)
        : 0;

    return SizedBox(
      width: 200, // Tamanho fixo do círculo para o gráfico
      height: 200,
      child: CustomPaint(
        painter: _PieChartPainter(
          // Instancia o pintor, que agora é privado neste arquivo
          saldo: saldo,
          totalDespesasFixas: totalDespesasFixas,
          totalDespesasAvulsas: totalDespesasAvulsas,
          percentualDespesasFixas: percentualDespesasFixas,
          percentualDespesasAvulsas: percentualDespesasAvulsas,
          percentualSaldo: percentualSaldo,
          currencyFormat: currencyFormat,
        ),
      ),
    );
  }
}

// Classe CustomPainter que desenha o gráfico de pizza, agora privada e auxiliar.
class _PieChartPainter extends CustomPainter {
  final double saldo;
  final double totalDespesasFixas;
  final double totalDespesasAvulsas;
  final double percentualDespesasFixas;
  final double percentualDespesasAvulsas;
  final double percentualSaldo;
  final NumberFormat currencyFormat;

  _PieChartPainter({
    required this.saldo,
    required this.totalDespesasFixas,
    required this.totalDespesasAvulsas,
    required this.percentualDespesasFixas,
    required this.percentualDespesasAvulsas,
    required this.percentualSaldo,
    required this.currencyFormat,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final innerRadius = radius * 0.5; // Raio do círculo central branco

    // Cores exatas (aproximadas) da imagem
    final Paint paintGastosFixos = Paint()
      ..color = const Color(0xFFD9FFB8); // Verde claro
    final Paint paintGastosAvulsos = Paint()
      ..color = const Color(0xFF90EE90); // Verde médio/claro
    final Paint paintSaldo = Paint()
      ..color = const Color(0xFF008000); // Verde escuro

    double startAngle = -pi / 2; // Começa no topo (12 horas)

    // Desenha a fatia de Gastos Fixos
    if (percentualDespesasFixas > 0) {
      final sweepAngle = 2 * pi * percentualDespesasFixas;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paintGastosFixos,
      );
      _drawText(
        canvas,
        center,
        radius,
        innerRadius,
        startAngle,
        sweepAngle,
        'Gastos Fixos',
        currencyFormat.format(totalDespesasFixas),
        const Color(0xFF000000),
        12.0,
      ); // Cor do texto preto
      startAngle += sweepAngle;
    }

    // Desenha a fatia de Gastos Avulsos
    if (percentualDespesasAvulsas > 0) {
      final sweepAngle = 2 * pi * percentualDespesasAvulsas;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paintGastosAvulsos,
      );
      _drawText(
        canvas,
        center,
        radius,
        innerRadius,
        startAngle,
        sweepAngle,
        'Gastos Avulsos',
        currencyFormat.format(totalDespesasAvulsas),
        const Color(0xFF000000),
        12.0,
      ); // Cor do texto preto
      startAngle += sweepAngle;
    }

    // Desenha a fatia de Saldo
    if (percentualSaldo > 0) {
      final sweepAngle = 2 * pi * percentualSaldo;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paintSaldo,
      );
      _drawText(
        canvas,
        center,
        radius,
        innerRadius,
        startAngle,
        sweepAngle,
        'Saldo',
        currencyFormat.format(saldo),
        const Color(0xFF000000),
        12.0,
      ); // Cor do texto preto
      startAngle += sweepAngle;
    }

    // Desenha o círculo central branco
    final Paint paintCenter = Paint()..color = Colors.white;
    canvas.drawCircle(center, innerRadius, paintCenter);
  }

  // Método auxiliar para desenhar texto dentro das fatias do gráfico
  void _drawText(
    Canvas canvas,
    Offset center,
    double outerRadius,
    double innerRadius,
    double startAngle,
    double sweepAngle,
    String label,
    String value,
    Color textColor,
    double fontSize,
  ) {
    // Calcula o ângulo médio da fatia
    final midAngle = startAngle + sweepAngle / 2;

    // Calcula a posição do texto (um pouco para fora do centro, mas dentro da fatia)
    final textRadius =
        (outerRadius + innerRadius) / 2 +
        60; // Ajusta a distância do texto do centro
    final x = center.dx + textRadius * cos(midAngle);
    final y = center.dy + textRadius * sin(midAngle);

    final textSpan = TextSpan(
      text:
          '$label\n${value.replaceAll('R\$ ', '')}', // Removendo "R$" e espaço para caber melhor
      style: TextStyle(
        color: textColor,
        fontSize: fontSize,
        fontWeight: FontWeight.bold, // Deixa o texto em negrito
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, y - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    _PieChartPainter oldPainter = oldDelegate as _PieChartPainter;
    return oldPainter.saldo != saldo ||
        oldPainter.totalDespesasFixas != totalDespesasFixas ||
        oldPainter.totalDespesasAvulsas != totalDespesasAvulsas ||
        oldPainter.percentualDespesasFixas != percentualDespesasFixas ||
        oldPainter.percentualDespesasAvulsas != percentualDespesasAvulsas ||
        oldPainter.percentualSaldo != percentualSaldo;
  }
}
