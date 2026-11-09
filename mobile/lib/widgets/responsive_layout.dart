import 'package:flutter/material.dart';

/// Wrapper responsivo que centraliza e limita a largura máxima do conteúdo em telas grandes (Desktop/Web).
/// Garante que o aplicativo mantenha a proporção ideal de design móvel/tablet sem esticar excessivamente.
class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.maxWidth = 860,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

