import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String)? onChanged;
  final VoidCallback? onFilterTap;
  final bool showFilterIcon;
  final EdgeInsetsGeometry? padding;

  const CustomSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'Cari ekspedisi...',
    this.onChanged,
    this.onFilterTap,
    this.showFilterIcon = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.grey[600],
              size: 24,
            ),
            suffixIcon: showFilterIcon
                ? IconButton(
                    icon: Icon(
                      Icons.tune,
                      color: Colors.grey[600],
                      size: 24,
                    ),
                    onPressed: onFilterTap ?? () {},
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF2D3436),
          ),
        ),
      ),
    );
  }
}