import 'child_media_asset.dart';

class FamilyContact {
  const FamilyContact({
    required this.id,
    required this.displayName,
    required this.relationship,
    required this.avatarText,
    required this.accentColorValue,
    this.isTrusted = true,
    this.isManuallyAllowed = true,
    this.localMedia = const ChildMediaAsset(kind: ContactMediaKind.fallback),
  });

  final String id;
  final String displayName;
  final String relationship;
  final String avatarText;
  final int accentColorValue;
  final bool isTrusted;
  final bool isManuallyAllowed;
  final ChildMediaAsset localMedia;

  FamilyContact copyWith({
    String? id,
    String? displayName,
    String? relationship,
    String? avatarText,
    int? accentColorValue,
    bool? isTrusted,
    bool? isManuallyAllowed,
    ChildMediaAsset? localMedia,
  }) {
    return FamilyContact(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      relationship: relationship ?? this.relationship,
      avatarText: avatarText ?? this.avatarText,
      accentColorValue: accentColorValue ?? this.accentColorValue,
      isTrusted: isTrusted ?? this.isTrusted,
      isManuallyAllowed: isManuallyAllowed ?? this.isManuallyAllowed,
      localMedia: localMedia ?? this.localMedia,
    );
  }

  Map<String, Object?> toJson() => {
    'displayName': displayName,
    'relationship': relationship,
    'avatarText': avatarText,
    'accentColorValue': accentColorValue,
    'isTrusted': isTrusted,
    'isManuallyAllowed': isManuallyAllowed,
    'localMedia': localMedia.toJson(),
  };

  static FamilyContact fromJson(String id, Map<String, Object?> json) {
    final mediaJson = json['localMedia'];

    return FamilyContact(
      id: id,
      displayName: json['displayName'] as String? ?? 'Family',
      relationship: json['relationship'] as String? ?? 'Loved one',
      avatarText: json['avatarText'] as String? ?? 'FH',
      accentColorValue: json['accentColorValue'] as int? ?? 0xFFE85D43,
      isTrusted: json['isTrusted'] as bool? ?? true,
      isManuallyAllowed: json['isManuallyAllowed'] as bool? ?? true,
      localMedia: mediaJson is Map
          ? ChildMediaAsset.fromJson(Map<String, Object?>.from(mediaJson))
          : const ChildMediaAsset(kind: ContactMediaKind.fallback),
    );
  }
}
