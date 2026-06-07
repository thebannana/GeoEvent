import 'package:flutter/material.dart';

import '../../../../shared/events/models/create_event_state.dart';
import 'create_event_form.dart';

class CreateEventTaxonomySection extends StatelessWidget {
  final CreateEventState state;
  final ValueChanged<int?> onSegmentChanged;
  final ValueChanged<int?> onGenreChanged;
  final ValueChanged<int?> onSubGenreChanged;

  const CreateEventTaxonomySection({
    super.key,
    required this.state,
    required this.onSegmentChanged,
    required this.onGenreChanged,
    required this.onSubGenreChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Category'),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: state.segmentId,
            isExpanded: true,
            items: state.segments
                .map(
                  (item) => DropdownMenuItem<int>(
                    value: item.segmentId,
                    child: Text(item.name),
                  ),
                )
                .toList(),
            onChanged: state.submitting ? null : onSegmentChanged,
            decoration: const InputDecoration(
              labelText: 'Segment',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: state.genreId,
            isExpanded: true,
            items: state.genres
                .map(
                  (item) => DropdownMenuItem<int>(
                    value: item.genreId,
                    child: Text(item.name),
                  ),
                )
                .toList(),
            onChanged: state.segmentId == null ||
                    state.genresLoading ||
                    state.submitting
                ? null
                : onGenreChanged,
            decoration: InputDecoration(
              labelText: 'Genre',
              suffixIcon: state.genresLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: state.subGenreId,
            isExpanded: true,
            items: state.subGenres
                .map(
                  (item) => DropdownMenuItem<int>(
                    value: item.subGenreId,
                    child: Text(item.name),
                  ),
                )
                .toList(),
            onChanged:
                state.genreId == null || state.subGenresLoading || state.submitting
                    ? null
                    : onSubGenreChanged,
            decoration: InputDecoration(
              labelText: 'Subgenre',
              suffixIcon: state.subGenresLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}