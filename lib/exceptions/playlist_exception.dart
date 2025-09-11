class PlaylistException implements Exception {
  final String message;
  final String code;

  PlaylistException(this.message, this.code);

  @override
  String toString() {
    return 'PlaylistException: $message (code: $code)';
  }
}
