enum AppRole {
  childWall,
  parent,
  relative;

  String get label => switch (this) {
    AppRole.childWall => 'Child wall',
    AppRole.parent => 'Parent',
    AppRole.relative => 'Relative',
  };
}
