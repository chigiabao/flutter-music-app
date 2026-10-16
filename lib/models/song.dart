class Song {
  final String id;
  final String title;
  final String artist;
  final String artworkUrl;
  final String audioUrl;
  final String? uploaderUid;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.artworkUrl,
    required this.audioUrl,
    this.uploaderUid,
  });

  factory Song.fromJson(Map<String, dynamic> j, {String? id}) => Song(
        id: id ?? (j['id'] as String? ?? ''),
        title: j['title'] as String? ?? 'Unknown',
        artist: j['artist'] as String? ?? 'Unknown',
        artworkUrl: j['artworkUrl'] as String? ?? '',
        audioUrl: j['audioUrl'] as String? ?? '',
        uploaderUid: j['uploaderUid'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'artworkUrl': artworkUrl,
        'audioUrl': audioUrl,
        if (uploaderUid != null) 'uploaderUid': uploaderUid,
      };
}
