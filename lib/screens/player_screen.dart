import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';
import '../services/auth_service.dart';
import '../services/player_controller.dart';
import 'login_screen.dart';

String _fmt(Duration d) =>
    '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

class PlayerScreen extends StatelessWidget {
  final PlayerController controller;
  final AuthService auth;
  const PlayerScreen({super.key, required this.controller, required this.auth});

  /// Playlist hiện tại: chọn một bài để phát.
  void _showPlaylist(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.playlist_play, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'Danh sách phát (${controller.queue.length})',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: controller.queue.length,
                itemBuilder: (context, i) {
                  final s = controller.queue[i];
                  final isCurrent = i == controller.index;
                  return ListTile(
                    selected: isCurrent,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        s.artworkUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(Icons.music_note),
                      ),
                    ),
                    title: Text(
                      s.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    subtitle: Text(s.artist, maxLines: 1),
                    trailing: isCurrent
                        ? Icon(Icons.equalizer,
                            color: Theme.of(context).colorScheme.primary)
                        : null,
                    onTap: () => controller.playQueue(controller.queue, i),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([controller, auth]),
      builder: (context, _) {
        final song = controller.current;
        if (song == null) return const Scaffold(body: SizedBox());
        final player = controller.player;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Đang phát'),
            actions: [
              IconButton(
                icon: Icon(
                  auth.isLiked(song) ? Icons.favorite : Icons.favorite_border,
                  color: auth.isLiked(song) ? Colors.red : null,
                ),
                onPressed: () => requireLoginThenLike(context, auth, song),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(children: [
              Expanded(
                child: Center(
                  child: Container(
                    constraints:
                        const BoxConstraints(maxHeight: 320, maxWidth: 320),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.3),
                          blurRadius: 32,
                          spreadRadius: 4,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Image.network(
                          song.artworkUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: Theme.of(context).colorScheme.surface,
                            child: const Icon(Icons.music_note, size: 100),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                song.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                song.artist,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
              ),
              if (controller.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    controller.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 13,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              StreamBuilder<Duration?>(
                stream: player.durationStream,
                builder: (context, dSnap) {
                  final total = dSnap.data ?? Duration.zero;
                  return StreamBuilder<Duration>(
                    stream: player.positionStream,
                    builder: (context, pSnap) {
                      final pos = pSnap.data ?? Duration.zero;
                      final max = total.inMilliseconds.toDouble();
                      return Column(children: [
                        Slider(
                          value: pos.inMilliseconds
                              .toDouble()
                              .clamp(0, max > 0 ? max : 1),
                          max: max > 0 ? max : 1,
                          onChanged: max > 0
                              ? (v) =>
                                  player.seek(Duration(milliseconds: v.toInt()))
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_fmt(pos),
                                  style: const TextStyle(
                                      color: Colors.white60, fontSize: 12)),
                              Text(_fmt(total),
                                  style: const TextStyle(
                                      color: Colors.white60, fontSize: 12)),
                            ],
                          ),
                        ),
                      ]);
                    },
                  );
                },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.shuffle,
                      color: controller.isShuffle
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white38,
                    ),
                    tooltip: 'Phát ngẫu nhiên',
                    onPressed: controller.toggleShuffle,
                  ),
                  IconButton(
                    iconSize: 38,
                    icon: const Icon(Icons.skip_previous_rounded),
                    onPressed: controller.previous,
                  ),
                  StreamBuilder<PlayerState>(
                    stream: player.playerStateStream,
                    builder: (context, snap) {
                      final st = snap.data;
                      final loading = st != null &&
                          (st.processingState == ProcessingState.loading ||
                              st.processingState == ProcessingState.buffering);
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.4),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: IconButton(
                          iconSize: 42,
                          color: Colors.white,
                          padding: const EdgeInsets.all(12),
                          icon: loading
                              ? const SizedBox(
                                  width: 42,
                                  height: 42,
                                  child: Padding(
                                    padding: EdgeInsets.all(8),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : Icon(
                                  player.playing
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                ),
                          onPressed: controller.togglePlay,
                        ),
                      );
                    },
                  ),
                  IconButton(
                    iconSize: 38,
                    icon: const Icon(Icons.skip_next_rounded),
                    onPressed: controller.next,
                  ),
                  IconButton(
                    icon: Icon(
                      controller.loopMode == LoopMode.one
                          ? Icons.repeat_one
                          : Icons.repeat,
                      color: controller.loopMode != LoopMode.off
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white38,
                    ),
                    tooltip: 'Lặp lại',
                    onPressed: controller.toggleLoop,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                icon: const Icon(Icons.queue_music),
                label: Text('Danh sách phát (${controller.queue.length})'),
                onPressed: () => _showPlaylist(context),
              ),
            ]),
          ),
        );
      },
    );
  }
}

/// Like yêu cầu đăng nhập: chưa đăng nhập thì mở màn hình đăng nhập trước.
Future<void> requireLoginThenLike(
    BuildContext context, AuthService auth, Song song) async {
  if (!auth.loggedIn) {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => LoginScreen(auth: auth)));
    if (!auth.loggedIn) return;
  }
  await auth.toggleLike(song);
}
