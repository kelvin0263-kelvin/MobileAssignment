import 'package:flutter/material.dart';
import '../utils/app_utils.dart';

class SegmentItem {
  final IconData? icon; // ignored for now
  final String label;

  const SegmentItem({this.icon, required this.label});
}

class PillSegmentedControl extends StatelessWidget {
  final List<SegmentItem> items;
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final double height;
  final EdgeInsetsGeometry padding;
  final TextStyle? textStyle; // 👈 新增

  const PillSegmentedControl({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onChanged,
    this.height = 44,
    this.padding = const EdgeInsets.all(6),
    this.textStyle, // 👈 新增
  }) : assert(currentIndex >= 0);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final int count = items.length;
        final insets = padding.resolve(Directionality.of(context));
        final double innerWidth = width - insets.left - insets.right;
        final double segmentWidth = innerWidth / count;

        return Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.inputFill, // subtle background
            borderRadius: BorderRadius.circular(height),
          ),
          child: Stack(
            children: [
              // Selected pill indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                left: insets.left + segmentWidth * currentIndex,
                top: insets.top,
                width: segmentWidth,
                height: height - insets.top - insets.bottom,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(height),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),

              // Segments row
              Padding(
                padding: insets,
                child: Row(
                  children: List.generate(count, (index) {
                    final bool selected = index == currentIndex;
                    final item = items[index];
                    final Color fg = selected ? AppColors.primary : AppColors.textPrimary;

                    return Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(height),
                        onTap: () => onChanged(index),
                        child: Container(
                          height: height - insets.vertical,
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  item.label,
                                  overflow: TextOverflow.ellipsis,
                                  style: (textStyle ?? AppTextStyles.body2).copyWith(
                                    color: fg,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


