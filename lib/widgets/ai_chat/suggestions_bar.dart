import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class SuggestionsBar extends StatelessWidget {
  final List<String> suggestions;
  final bool isLoading;
  final Function(String) onSuggestionSelected;

  const SuggestionsBar({
    super.key,
    required this.suggestions,
    required this.isLoading,
    required this.onSuggestionSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty || isLoading) return const SizedBox.shrink();

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: suggestions.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ActionChip(
            backgroundColor: AppColors.primary.withOpacity(0.1),
            side: const BorderSide(color: AppColors.primaryLight, width: 0.5),
            label: Text(suggestions[index], style: const TextStyle(color: AppColors.primaryLight)),
            onPressed: () => onSuggestionSelected(suggestions[index]),
          ),
        ),
      ),
    );
  }
}