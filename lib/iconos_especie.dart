import 'package:flutter/material.dart';

import 'theme.dart';

/// Ícono de línea de la cabeza de cada especie, con el estilo del logo de AgroRegister
/// (trazo verde redondeado y relleno suave). [especie] es una clave de `especies`.
class IconoEspecie extends StatelessWidget {
  const IconoEspecie(this.especie, {super.key, this.size = 24, this.color = AppColors.primary, this.semanticLabel});

  final String especie;
  final double size;
  final Color color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
        label: semanticLabel,
        child: CustomPaint(size: Size.square(size), painter: _Cabeza(especie, color)),
      );
}

class _Cabeza extends CustomPainter {
  _Cabeza(this.especie, this.color);

  final String especie;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100); // se dibuja en una cuadrícula de 100 × 100
    final trazo = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final suave = Paint()..color = color.withValues(alpha: 0.16);
    final medio = Paint()..color = color.withValues(alpha: 0.38);
    final lleno = Paint()..color = color;

    void figura(Path p, [Paint? relleno]) {
      canvas.drawPath(p, relleno ?? suave);
      canvas.drawPath(p, trazo);
    }

    void ojos(double y, [double sep = 11]) {
      canvas.drawCircle(Offset(50 - sep, y), 4.2, lleno);
      canvas.drawCircle(Offset(50 + sep, y), 4.2, lleno);
    }

    switch (especie) {
      case 'Equino': // cara alargada, orejas en punta, crin y lucero
        figura(Path()
          ..moveTo(36, 22)
          ..lineTo(33, 5)
          ..lineTo(45, 17)
          ..close());
        figura(Path()
          ..moveTo(64, 22)
          ..lineTo(67, 5)
          ..lineTo(55, 17)
          ..close());
        figura(Path()
          ..moveTo(50, 14)
          ..cubicTo(72, 14, 77, 28, 74, 46)
          ..cubicTo(72, 58, 70, 66, 70, 76)
          ..cubicTo(70, 94, 30, 94, 30, 76)
          ..cubicTo(30, 66, 28, 58, 26, 46)
          ..cubicTo(23, 28, 28, 14, 50, 14)
          ..close());
        canvas.drawPath(
            Path()
              ..moveTo(42, 13)
              ..quadraticBezierTo(50, 3, 60, 9)
              ..quadraticBezierTo(53, 14, 51, 22),
            trazo);
        canvas.drawPath(
            Path() // lucero en la frente
              ..moveTo(50, 26)
              ..lineTo(55, 33)
              ..lineTo(50, 40)
              ..lineTo(45, 33)
              ..close(),
            lleno);
        figura(Path()..addOval(const Rect.fromLTRB(35, 66, 65, 90)), medio);
        canvas.drawOval(const Rect.fromLTRB(41, 74, 47, 82), lleno);
        canvas.drawOval(const Rect.fromLTRB(53, 74, 59, 82), lleno);
        ojos(48, 14);
      case 'Ovino': // lana esponjada, orejas de lado y cara oscura
        // Se unen los círculos para que solo se vea el contorno exterior de la lana.
        var lana = Path();
        for (final (x, y) in [(30.0, 34.0), (36.0, 22.0), (50.0, 16.0), (64.0, 22.0), (70.0, 34.0), (50.0, 30.0)]) {
          lana = Path.combine(
              PathOperation.union, lana, Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: 12)));
        }
        canvas.drawPath(lana, suave);
        canvas.drawPath(lana, trazo);
        figura(Path()..addOval(const Rect.fromLTRB(6, 40, 30, 54)));
        figura(Path()..addOval(const Rect.fromLTRB(70, 40, 94, 54)));
        figura(
            Path()
              ..moveTo(50, 30)
              ..cubicTo(68, 30, 70, 48, 66, 64)
              ..cubicTo(62, 82, 56, 90, 50, 90)
              ..cubicTo(44, 90, 38, 82, 34, 64)
              ..cubicTo(30, 48, 32, 30, 50, 30)
              ..close(),
            medio);
        ojos(52, 9);
        canvas.drawPath(
            Path()
              ..moveTo(44, 74)
              ..lineTo(50, 79)
              ..lineTo(56, 74)
              ..moveTo(50, 79)
              ..lineTo(50, 84),
            trazo..strokeWidth = 4);
        trazo.strokeWidth = 6;
      case 'Porcino': // cabeza redonda, orejas caídas y trompa
        figura(Path()
          ..moveTo(24, 34)
          ..lineTo(18, 8)
          ..lineTo(42, 22)
          ..close());
        figura(Path()
          ..moveTo(76, 34)
          ..lineTo(82, 8)
          ..lineTo(58, 22)
          ..close());
        figura(Path()..addOval(const Rect.fromLTRB(16, 18, 84, 88)));
        figura(Path()..addOval(const Rect.fromLTRB(33, 56, 67, 80)), medio);
        canvas.drawOval(const Rect.fromLTRB(40, 63, 46, 73), lleno);
        canvas.drawOval(const Rect.fromLTRB(54, 63, 60, 73), lleno);
        ojos(44, 13);
      default: // Bovino: cuernos, orejas a los lados y hocico ancho
        canvas.drawPath(
            Path()
              ..moveTo(32, 26)
              ..quadraticBezierTo(16, 24, 18, 6),
            trazo);
        canvas.drawPath(
            Path()
              ..moveTo(68, 26)
              ..quadraticBezierTo(84, 24, 82, 6),
            trazo);
        figura(Path()
          ..moveTo(30, 34)
          ..quadraticBezierTo(12, 30, 6, 40)
          ..quadraticBezierTo(16, 50, 32, 46)
          ..close());
        figura(Path()
          ..moveTo(70, 34)
          ..quadraticBezierTo(88, 30, 94, 40)
          ..quadraticBezierTo(84, 50, 68, 46)
          ..close());
        figura(Path()
          ..moveTo(50, 20)
          ..cubicTo(68, 20, 72, 30, 70, 48)
          ..cubicTo(69, 58, 70, 64, 70, 70)
          ..lineTo(30, 70)
          ..cubicTo(30, 64, 31, 58, 30, 48)
          ..cubicTo(28, 30, 32, 20, 50, 20)
          ..close());
        figura(Path()..addRRect(RRect.fromLTRBR(26, 62, 74, 92, const Radius.circular(15))), medio);
        canvas.drawOval(const Rect.fromLTRB(36, 72, 44, 81), lleno);
        canvas.drawOval(const Rect.fromLTRB(56, 72, 64, 81), lleno);
        ojos(44, 10);
    }
  }

  @override
  bool shouldRepaint(_Cabeza old) => old.especie != especie || old.color != color;
}

/// Ícono de la especie seguido de un texto en una línea (tarjetas, listas y selectores).
Widget conIconoEspecie(String especie, Widget texto, {double size = 16, Color color = AppColors.primary}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconoEspecie(especie, size: size, color: color),
        const SizedBox(width: 6),
        Flexible(child: texto),
      ],
    );
