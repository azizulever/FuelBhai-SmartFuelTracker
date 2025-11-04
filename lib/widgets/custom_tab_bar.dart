import 'package:flutter/material.dart';
import 'package:mileage_calculator/utils/theme.dart';

class CustomTabBar extends StatefulWidget {
  final List<String> tabs;
  final Function(int) onTabChanged;
  final int initialIndex;

  const CustomTabBar({
    Key? key,
    required this.tabs,
    required this.onTabChanged,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<CustomTabBar> createState() => _CustomTabBarState();
}

class _CustomTabBarState extends State<CustomTabBar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey[200]!,
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Row(
            children: List.generate(
              widget.tabs.length,
              (index) => Expanded(child: _buildTabItem(index)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(int index) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        widget.onTabChanged(index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: isSelected ? Border.all(color: primaryColor, width: 1) : null,
        ),
        child: Center(
          child: Text(
            widget.tabs[index],
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? primaryColor : Colors.grey[700],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
