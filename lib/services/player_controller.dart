import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';

/// Quản lý phát nhạc + playlist hiện tại (stream từ URL).
class PlayerController extends ChangeNotifier {
  final AudioPlayer player = AudioPlayer();
  List<Song> _queue = [];
  int _index = -1;
  String? error;
  bool _isShuffle = false;
  LoopMode _loopMode = LoopMode.off;

  PlayerController() {
    player.playerStateStream.listen((s) {
      if (s.processingState == ProcessingState.completed) {
        _onSongCompleted();
      }
      notifyListeners();
    });
  }

  List<Song> get queue => _queue;
  int get index => _index;
  Song? get current =>
      _index >= 0 && _index < _queue.length ? _queue[_index] : null;
  bool get isShuffle => _isShuffle;
  LoopMode get loopMode => _loopMode;

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  void toggleLoop() {
    if (_loopMode == LoopMode.off) {
      _loopMode = LoopMode.all;
    } else if (_loopMode == LoopMode.all) {
      _loopMode = LoopMode.one;
    } else {
      _loopMode = LoopMode.off;
    }
    notifyListeners();
  }

  Future<void> _onSongCompleted() async {
    if (_queue.isEmpty) return;
    if (_loopMode == LoopMode.one) {
      await player.seek(Duration.zero);
      player.play();
    } else if (_isShuffle && _queue.length > 1) {
      final nextIdx = Random().nextInt(_queue.length);
      await _playAt(nextIdx == _index ? (nextIdx + 1) % _queue.length : nextIdx);
    } else {
      await next();
    }
  }

  Future<void> playQueue(List<Song> songs, int index) async {
    _queue = List.from(songs);
    await _playAt(index);
  }

  Future<void> _playAt(int i) async {
    if (_queue.isEmpty) return;
    _index = (i + _queue.length) % _queue.length;
    error = null;
    notifyListeners();
    try {
      await player.setUrl(current!.audioUrl);
      player.play();
    } catch (e) {
      error = 'Không phát được bài hát này. Hãy kiểm tra kết nối mạng.';
      notifyListeners();
    }
  }

  Future<void> next() async {
    if (_isShuffle && _queue.length > 1) {
      final nextIdx = Random().nextInt(_queue.length);
      await _playAt(nextIdx == _index ? (nextIdx + 1) % _queue.length : nextIdx);
    } else {
      await _playAt(_index + 1);
    }
  }

  Future<void> previous() async {
    // Quá 3 giây thì tua về đầu bài, ngược lại về bài trước.
    if (player.position > const Duration(seconds: 3)) {
      await player.seek(Duration.zero);
    } else {
      await _playAt(_index - 1);
    }
  }

  void togglePlay() => player.playing ? player.pause() : player.play();

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }
}
