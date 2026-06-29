enum ContactMediaKind { photo, video, audio, fallback }

class ChildMediaAsset {
  const ChildMediaAsset({required this.kind, this.localPath, this.caption});

  final ContactMediaKind kind;
  final String? localPath;
  final String? caption;

  bool get isLocalFile => localPath != null && localPath!.isNotEmpty;

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'localPath': localPath,
    'caption': caption,
  };

  static ChildMediaAsset fromJson(Map<String, Object?> json) {
    return ChildMediaAsset(
      kind: ContactMediaKind.values.firstWhere(
        (kind) => kind.name == json['kind'],
        orElse: () => ContactMediaKind.fallback,
      ),
      localPath: json['localPath'] as String?,
      caption: json['caption'] as String?,
    );
  }
}
