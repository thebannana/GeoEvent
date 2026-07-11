import 'package:flutter/material.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/feedback/app_spinner.dart';
import '../../../../core/widgets/surfaces/app_surface_card.dart';
import '../../../../shared/events/models/create_event_state.dart';
import 'create_event_form.dart';

class CreateEventTaxonomySection extends StatelessWidget {
  final CreateEventState state;
  final ValueChanged<int?>? onSegmentChanged;
  final ValueChanged<int?>? onGenreChanged;
  final ValueChanged<int?>? onSubGenreChanged;

  const CreateEventTaxonomySection({
    super.key,
    required this.state,
    this.onSegmentChanged,
    this.onGenreChanged,
    this.onSubGenreChanged,
  });

  @override
  Widget build(BuildContext context) {
    final canEdit = !state.submitting;
    final hasSegment = Validators.selectionRequired(
          state.segmentId,
          fieldName: 'Segment',
        ) ==
        null;
    final hasGenre = Validators.selectionRequired(
          state.genreId,
          fieldName: 'Genre',
        ) ==
        null;

    final canPickGenre = canEdit && hasSegment && !state.genresLoading;
    final canPickSubGenre = canEdit && hasGenre && !state.subGenresLoading;

    return AppSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Category'),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: state.segmentId,
            isExpanded: true,
            items: state.segments
                .map(
                  (item) => DropdownMenuItem<int>(
                    value: item.segmentId,
                    child: Text(item.name),
                  ),
                )
                .toList(),
            onChanged: canEdit ? onSegmentChanged : null,
            decoration: const InputDecoration(
              labelText: 'Segment',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: state.genreId,
            isExpanded: true,
            items: state.genres
                .map(
                  (item) => DropdownMenuItem<int>(
                    value: item.genreId,
                    child: Text(item.name),
                  ),
                )
                .toList(),
            onChanged: canPickGenre ? onGenreChanged : null,
            decoration: InputDecoration(
              labelText: 'Genre',
              hintText: !hasSegment
                  ? 'Select a segment first'
                  : state.genresLoading
                      ? 'Loading genres...'
                      : 'Select a genre',
              suffixIcon: state.genresLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: AppSpinner(size: 16, strokeWidth: 2),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: state.subGenreId,
            isExpanded: true,
            items: state.subGenres
                .map(
                  (item) => DropdownMenuItem<int>(
                    value: item.subGenreId,
                    child: Text(item.name),
                  ),
                )
                .toList(),
            onChanged: canPickSubGenre ? onSubGenreChanged : null,
            decoration: InputDecoration(
              labelText: 'Subgenre',
              hintText: !hasGenre
                  ? 'Select a genre first'
                  : state.subGenresLoading
                      ? 'Loading subgenres...'
                      : 'Select a subgenre',
              suffixIcon: state.subGenresLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: AppSpinner(size: 16, strokeWidth: 2),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}