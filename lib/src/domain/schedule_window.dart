import 'family_contact.dart';

class ScheduleWindow {
  const ScheduleWindow({
    required this.id,
    required this.label,
    required this.startMinute,
    required this.endMinute,
    required this.allowedContactIds,
    this.weekdays = const {},
    this.isEnabled = true,
  }) : assert(startMinute >= 0 && startMinute < 24 * 60),
       assert(endMinute >= 0 && endMinute < 24 * 60);

  final String id;
  final String label;
  final int startMinute;
  final int endMinute;
  final Set<String> allowedContactIds;
  final Set<int> weekdays;
  final bool isEnabled;

  bool contains(DateTime dateTime) {
    if (!isEnabled) {
      return false;
    }

    if (weekdays.isNotEmpty && !weekdays.contains(dateTime.weekday)) {
      return false;
    }

    final minuteOfDay = dateTime.hour * 60 + dateTime.minute;
    if (startMinute == endMinute) {
      return true;
    }

    if (startMinute < endMinute) {
      return minuteOfDay >= startMinute && minuteOfDay < endMinute;
    }

    return minuteOfDay >= startMinute || minuteOfDay < endMinute;
  }

  List<FamilyContact> activeContacts(
    List<FamilyContact> contacts,
    DateTime dateTime,
  ) {
    if (!contains(dateTime)) {
      return const [];
    }

    return contacts
        .where((contact) => contact.isTrusted)
        .where((contact) => contact.isManuallyAllowed)
        .where((contact) => allowedContactIds.contains(contact.id))
        .toList(growable: false);
  }

  String get timeLabel =>
      '${_formatMinute(startMinute)} - ${_formatMinute(endMinute)}';

  Map<String, Object?> toJson() => {
    'label': label,
    'startMinute': startMinute,
    'endMinute': endMinute,
    'allowedContactIds': allowedContactIds.toList(),
    'weekdays': weekdays.toList(),
    'isEnabled': isEnabled,
  };

  static ScheduleWindow fromJson(String id, Map<String, Object?> json) {
    final allowedContactIds = json['allowedContactIds'];
    final weekdays = json['weekdays'];

    return ScheduleWindow(
      id: id,
      label: json['label'] as String? ?? 'Family time',
      startMinute: json['startMinute'] as int? ?? 0,
      endMinute: json['endMinute'] as int? ?? 0,
      allowedContactIds: Set<String>.from(
        allowedContactIds is List
            ? allowedContactIds.whereType<String>()
            : const [],
      ),
      weekdays: Set<int>.from(
        weekdays is List ? weekdays.whereType<int>() : const [],
      ),
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  static String _formatMinute(int minute) {
    final hour = minute ~/ 60;
    final minutes = minute % 60;
    return '${hour.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}
