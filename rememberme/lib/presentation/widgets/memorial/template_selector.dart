import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TemplateSelector extends StatelessWidget {
  final String? selectedTemplateId;
  final Function(String) onTemplateSelected;

  const TemplateSelector({
    super.key,
    this.selectedTemplateId,
    required this.onTemplateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final templates = [
      {'id': 'template-1', 'name': 'Klassisch', 'icon': Icons.article},
      {'id': 'template-2', 'name': 'Modern', 'icon': Icons.auto_awesome},
      {'id': 'template-3', 'name': 'Elegant', 'icon': Icons.diamond},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        final isSelected = template['id'] == selectedTemplateId;

        return GestureDetector(
          onTap: () => onTemplateSelected(template['id'] as String),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  template['icon'] as IconData,
                  size: 40,
                  color: isSelected ? AppColors.primary : Colors.grey[600],
                ),
                const SizedBox(height: 8),
                Text(
                  template['name'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.primary : Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
