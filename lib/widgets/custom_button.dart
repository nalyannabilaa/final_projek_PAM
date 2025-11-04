import 'package:flutter/material.dart';

class CustomButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final double borderRadius;
  final double height;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? disabledColor;
  final IconData? icon;
  final bool iconRight;
  final bool isFullWidth;
  final double pressedScale; // Efek animasi saat ditekan

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor = Colors.white,
    this.borderRadius = 15,
    this.height = 55,
    this.fontSize = 16,
    this.fontWeight = FontWeight.bold,
    this.disabledColor = Colors.grey,
    this.icon,
    this.iconRight = false,
    this.isFullWidth = true,
    this.pressedScale = 0.96, // tombol sedikit mengecil saat ditekan
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() => _scale = widget.pressedScale);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.isLoading
        ? const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null && !widget.iconRight) ...[
                Icon(widget.icon, size: 22, color: widget.textColor),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: widget.fontSize,
                  fontWeight: widget.fontWeight,
                  letterSpacing: 1.2,
                ),
              ),
              if (widget.icon != null && widget.iconRight) ...[
                const SizedBox(width: 8),
                Icon(widget.icon, size: 22, color: widget.textColor),
              ],
            ],
          );

    final button = Material(
      color: widget.backgroundColor ?? const Color(0xFFE3DE61),
      borderRadius: BorderRadius.circular(widget.borderRadius),
      elevation: 5,
      shadowColor: Colors.black38,
      child: InkWell(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        splashColor: Colors.white24,
        highlightColor: Colors.transparent,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.isLoading ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          transform: Matrix4.identity()..scale(_scale),
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );

    return widget.isFullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}
