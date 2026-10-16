import 'package:flutter_test/flutter_test.dart';
import 'package:th6_2324801030001/models/song.dart';
import 'package:th6_2324801030001/services/music_api.dart';

void main() {
  const a = Song(id: 'a', title: 'Sunrise', artist: 'X', artworkUrl: '', audioUrl: 'u');
  const b = Song(id: 'b', title: 'Rain', artist: 'Y', artworkUrl: '', audioUrl: 'u');

  test('Song JSON round trip', () {
    expect(Song.fromJson(a.toJson()).title, 'Sunrise');
  });

  test('search filters by title or artist', () {
    expect(MusicApi.filter([a, b], 'rain'), [b]);
    expect(MusicApi.filter([a, b], 'x'), [a]);
    expect(MusicApi.filter([a, b], ''), [a, b]);
  });
}
