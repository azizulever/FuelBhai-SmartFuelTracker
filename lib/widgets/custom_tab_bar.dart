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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final horizontalPadding =
        screenWidth < 360 ? 12.0 : (screenWidth < 400 ? 14.0 : 16.0);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: isSmallScreen ? 4 : 6,
      ),
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
          padding: const EdgeInsets.all(3),
          child: Row(
            children: List.generate(
              widget.tabs.length,
              (index) => Expanded(child: _buildTabItem(index, isSmallScreen)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, bool isSmallScreen) {
    final isSelected = _selectedIndex == index;
    final shouldAddSpacing = index < widget.tabs.length - 1;

    return Padding(
      padding: EdgeInsets.only(
        right: shouldAddSpacing ? (isSmallScreen ? 3 : 4) : 0,
      ),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
          widget.onTabChanged(index);
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 7 : 9,
            horizontal: isSmallScreen ? 14 : 18,
          ),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border:
                isSelected ? Border.all(color: primaryColor, width: 1) : null,
          ),
          child: Center(
            child: Text(
              widget.tabs[index],
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? primaryColor : Colors.grey[700],
                height: 1.0,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
