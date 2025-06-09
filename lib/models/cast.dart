class Cast {
  final String name;
  final String? profilePath;
  final String character;

  Cast({required this.name, this.profilePath, required this.character});

  factory Cast.fromJson(Map<String, dynamic> json) {
    return Cast(
      name: json['name'],
      profilePath: json['profile_path'],
      character: json['character'],
    );
  }
}
