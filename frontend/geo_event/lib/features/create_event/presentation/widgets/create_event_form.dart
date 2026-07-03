import 'package:flutter/material.dart';

import '../../../../core/widgets/surfaces/app_surface_card.dart';
import '../../../../shared/events/models/create_event_state.dart';

class CreateEventForm extends StatelessWidget {
  final CreateEventState state;
  final TextEditingController titleCtrl;
  final TextEditingController descriptionCtrl;
  final TextEditingController capacityCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController tagsCtrl;
  final TextEditingController accessibilityCtrl;
  final TextEditingController promoterCtrl;
  final DateTime? startAt;
  final DateTime? endAt;
  final String Function(DateTime value) formatDateTime;
  final Future<void> Function()? onPickStartDate;
  final Future<void> Function()? onPickEndDate;
  final ValueChanged<bool>? onFreeChanged;

  const CreateEventForm({
    super.key,
    required this.state,
    required this.titleCtrl,
    required this.descriptionCtrl,
    required this.capacityCtrl,
    required this.priceCtrl,
    required this.tagsCtrl,
    required this.accessibilityCtrl,
    required this.promoterCtrl,
    required this.startAt,
    required this.endAt,
    required this.formatDateTime,
    this.onPickStartDate,
    this.onPickEndDate,
    this.onFreeChanged,
  });

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('Basic info'),
              const SizedBox(height: 12),
              TextFormField(
                controller: titleCtrl,
                textInputAction: TextInputAction.next,
                enabled: !state.submitting,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Write a title for your event',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descriptionCtrl,
                enabled: !state.submitting,
                minLines: 5,
                maxLines: 7,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Write a description for your event',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('Attendance & schedule'),
              const SizedBox(height: 12),
              TextFormField(
                controller: capacityCtrl,
                enabled: !state.submitting,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Capacity',
                  hintText: 'How many people can attend?',
                ),
              ),
              const SizedBox(height: 12),
              PickerField(
                label: 'Start date',
                value: startAt == null
                    ? 'Pick a starting date'
                    : formatDateTime(startAt!),
                onTap: state.submitting ? null : onPickStartDate,
              ),
              const SizedBox(height: 12),
              PickerField(
                label: 'End date',
                value: endAt == null
                    ? 'Pick an ending date'
                    : formatDateTime(endAt!),
                onTap: state.submitting ? null : onPickEndDate,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('Pricing & details'),
              const SizedBox(height: 4),
              SwitchListTile.adaptive(
                value: state.isFree,
                onChanged: state.submitting ? null : onFreeChanged,
                contentPadding: EdgeInsets.zero,
                title: const Text('Free event'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: priceCtrl,
                enabled: !state.isFree && !state.submitting,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Price',
                  hintText: state.isFree
                      ? 'Free event selected'
                      : 'Enter ticket price',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: tagsCtrl,
                enabled: !state.submitting,
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  hintText: 'music, techno, live, outdoor',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: promoterCtrl,
                enabled: !state.submitting,
                decoration: const InputDecoration(
                  labelText: 'Promoter name',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: accessibilityCtrl,
                enabled: !state.submitting,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Accessibility info',
                  hintText: 'Wheelchair access, elevator, accessible toilet...',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SectionCard extends StatelessWidget {
  final Widget child;

  const SectionCard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: child,
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;

  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class PickerField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onTap != null;
    final isPlaceholder = value.toLowerCase().startsWith('pick ');

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          enabled: isEnabled,
        ),
        child: Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: isPlaceholder
                ? theme.textTheme.bodySmall?.color
                : theme.textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }
}

class InlineBanner extends StatelessWidget {
  final String message;
  final bool isError;

  const InlineBanner({
    super.key,
    required this.message,
    required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isError ? theme.colorScheme.error : theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.28),
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 13,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}