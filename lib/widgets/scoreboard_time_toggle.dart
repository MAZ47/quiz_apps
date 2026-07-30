import 'package:flutter/material.dart';

class ScoreboardTimeToggle extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const ScoreboardTimeToggle({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: SegmentedButton<String>(
        segments: [
          ButtonSegment(value: 'all', label: Text('All Time')),
          ButtonSegment(value: 'month', label: Text('This Month')),
          ButtonSegment(value: 'week', label: Text('This Week')),
        ],
        selected: {selectedFilter},
        onSelectionChanged: (Set<String> newSelection) {
          // Handle selection change
          onFilterChanged(newSelection.first);
        },
      ),
    );
  }
}
