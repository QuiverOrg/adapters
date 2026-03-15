class FrameworkInfo {
  final String name;
  final String? version;
  const FrameworkInfo({required this.name, this.version});
  Map<String, dynamic> toJson() => {'name': name, 'version': ?version};
}
