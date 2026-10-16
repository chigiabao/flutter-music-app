import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/auth_service.dart';
import '../services/music_api.dart';
import '../services/player_controller.dart';
import 'login_screen.dart';
import 'player_screen.dart';
import 'profile_screen.dart';
import '../widgets/add_song_dialog.dart';

class HomeScreen extends StatefulWidget {
  final AuthService auth;
  final PlayerController player;
  const HomeScreen({super.key, required this.auth, required this.player});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum HomeTab { all, liked, myUploads }

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  List<Song> _all = [];
  bool _loading = true;
  HomeTab _currentTab = HomeTab.all;
  String? _error;

  List<Song> get _myUploads => _all
      .where((s) =>
          s.uploaderUid != null && s.uploaderUid == widget.auth.uid)
      .toList();

  List<Song> _getTabSource(AuthService auth) {
    switch (_currentTab) {
      case HomeTab.all:
        return _all;
      case HomeTab.liked:
        return auth.liked;
      case HomeTab.myUploads:
        return _myUploads;
    }
  }

  List<Song> _getDisplayList(AuthService auth) {
    return MusicApi.filter(_getTabSource(auth), _search.text);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await MusicApi.getSongs();
      if (!mounted) return;
      setState(() => _all = r);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Không tải được danh sách: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openPlayer() => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) =>
              PlayerScreen(controller: widget.player, auth: widget.auth)));

  void _play(List<Song> list, int i) {
    widget.player.playQueue(list, i);
    _openPlayer();
  }

  void _showAddSongDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddSongDialog(
        uploaderUid: widget.auth.uid,
        onSongAdded: () {
          _load();
        },
      ),
    );
  }

  void _confirmDeleteSong(Song s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xóa bài hát "${s.title}"?'),
        content: const Text(
          'Bài hát này sẽ bị xóa vĩnh viễn khỏi danh sách và đám mây.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await MusicApi.deleteSong(s);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã xóa "${s.title}" thành công!'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi khi xóa bài hát: $e')),
                  );
                }
              }
              _load();
            },
            child: const Text('Xác nhận xóa'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip({
    required HomeTab tab,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _currentTab == tab;
    final primaryColor = Theme.of(context).colorScheme.primary;
    return ChoiceChip(
      selected: isSelected,
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : Colors.white60,
      ),
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : Colors.white70,
      ),
      backgroundColor: const Color(0xFF1F1B30),
      selectedColor: primaryColor,
      side: BorderSide(
        color: isSelected ? primaryColor : Colors.white12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (_) {
        if (tab == HomeTab.liked && !widget.auth.loggedIn) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LoginScreen(auth: widget.auth)),
          );
          return;
        }
        if (tab == HomeTab.myUploads && !widget.auth.loggedIn) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LoginScreen(auth: widget.auth)),
          );
          return;
        }
        setState(() => _currentTab = tab);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.auth;
    return ListenableBuilder(
      listenable: Listenable.merge([auth, widget.player]),
      builder: (context, _) {
        final list = _getDisplayList(auth);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Music Online'),
            actions: [
              IconButton(
                tooltip: 'Thêm bài hát mới',
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _showAddSongDialog,
              ),
              if (auth.loggedIn)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileScreen(auth: auth),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        backgroundImage: (auth.photoUrl != null &&
                                auth.photoUrl!.isNotEmpty)
                            ? NetworkImage(auth.photoUrl!)
                            : null,
                        child: (auth.photoUrl == null ||
                                auth.photoUrl!.isEmpty)
                            ? const Icon(Icons.person, size: 18)
                            : null,
                      ),
                    ),
                  ),
                )
              else
                IconButton(
                  tooltip: 'Đăng nhập',
                  icon: const Icon(Icons.account_circle_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LoginScreen(auth: auth),
                      ),
                    );
                  },
                ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(114),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: SearchBar(
                      controller: _search,
                      hintText: 'Tìm bài hát, nghệ sĩ...',
                      leading: const Icon(Icons.search),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildTabChip(
                          tab: HomeTab.all,
                          label: 'Khám phá (${_all.length})',
                          icon: Icons.explore_outlined,
                        ),
                        const SizedBox(width: 8),
                        _buildTabChip(
                          tab: HomeTab.liked,
                          label: 'Yêu thích (${auth.liked.length})',
                          icon: Icons.favorite_border,
                        ),
                        const SizedBox(width: 8),
                        _buildTabChip(
                          tab: HomeTab.myUploads,
                          label: 'Nhạc của tôi (${_myUploads.length})',
                          icon: Icons.cloud_upload_outlined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
          body: _body(list),
          bottomNavigationBar: widget.player.current == null
              ? null
              : _miniPlayer(widget.player.current!),
        );
      },
    );
  }

  Widget _body(List<Song> list) {
    if (_currentTab == HomeTab.all) {
      if (_loading) return const Center(child: CircularProgressIndicator());
      if (_error != null) {
        return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_error!),
            TextButton(onPressed: _load, child: const Text('Thử lại')),
          ]),
        );
      }
      if (_all.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.music_off, size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                'Firestore chưa có bài hát nào',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bạn có thể tự thêm bài hát thật hoặc nạp nhanh danh sách bài hát thật có sẵn.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Tự thêm bài hát'),
                    onPressed: _showAddSongDialog,
                  ),
                  FilledButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Nạp bài hát thật'),
                    onPressed: () async {
                      setState(() => _loading = true);
                      try {
                        await MusicApi.seed();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi khi nạp dữ liệu: $e')),
                          );
                        }
                      }
                      _load();
                    },
                  ),
                ],
              ),
            ]),
          ),
        );
      }
    }

    if (_currentTab == HomeTab.myUploads) {
      if (!widget.auth.loggedIn) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 56, color: Colors.white38),
                const SizedBox(height: 12),
                const Text(
                  'Vui lòng đăng nhập',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Đăng nhập để xem và quản lý các bài hát bạn đã tải lên.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text('Đăng nhập ngay'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => LoginScreen(auth: widget.auth)),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      if (list.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cloud_upload_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Bạn chưa tải lên bài hát nào',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Chọn file MP3 từ máy của bạn để thêm bài hát vào mục riêng này.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Tải lên bài hát mới'),
                  onPressed: _showAddSongDialog,
                ),
              ],
            ),
          ),
        );
      }
    }

    if (list.isEmpty) {
      return Center(
        child: Text(
          _currentTab == HomeTab.liked
              ? 'Bạn chưa thích bài hát nào'
              : 'Không tìm thấy bài hát phù hợp',
          style: const TextStyle(color: Colors.white60),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 90, top: 8),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final s = list[i];
        final liked = widget.auth.isLiked(s);
        final isPlaying = widget.player.current?.id == s.id;
        final isOwner = s.uploaderUid != null &&
            s.uploaderUid == widget.auth.uid;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isPlaying
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPlaying
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.04),
            ),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                s.artworkUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 50,
                  height: 50,
                  color: Colors.white10,
                  child: const Icon(Icons.music_note, color: Colors.white54),
                ),
              ),
            ),
            title: Text(
              s.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: isPlaying ? FontWeight.bold : FontWeight.w500,
                color: isPlaying
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white,
              ),
            ),
            subtitle: Text(
              s.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isPlaying)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.equalizer,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    liked ? Icons.favorite : Icons.favorite_border,
                    color: liked ? Colors.redAccent : Colors.white38,
                  ),
                  onPressed: () =>
                      requireLoginThenLike(context, widget.auth, s),
                ),
                if (isOwner)
                  IconButton(
                    tooltip: 'Xóa bài hát của bạn',
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    onPressed: () => _confirmDeleteSong(s),
                  ),
              ],
            ),
            onTap: () => _play(list, i),
            onLongPress: () {
              if (isOwner) {
                _confirmDeleteSong(s);
              }
            },
          ),
        );
      },
    );
  }

  Widget _miniPlayer(Song s) {
    final p = widget.player;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: InkWell(
          onTap: _openPlayer,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1A33),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          s.artworkUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 48,
                            height: 48,
                            color: Colors.white10,
                            child: const Icon(Icons.music_note),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              s.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          p.player.playing
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_filled_rounded,
                          size: 36,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: p.togglePlay,
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded, size: 28),
                        onPressed: p.next,
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: StreamBuilder<Duration?>(
                      stream: p.player.durationStream,
                      builder: (context, dSnap) {
                        final total = dSnap.data?.inMilliseconds.toDouble() ?? 1;
                        return StreamBuilder<Duration>(
                          stream: p.player.positionStream,
                          builder: (context, pSnap) {
                            final pos =
                                pSnap.data?.inMilliseconds.toDouble() ?? 0;
                            final progress = (total > 0 ? (pos / total) : 0.0)
                                .clamp(0.0, 1.0);
                            return LinearProgressIndicator(
                              value: progress,
                              minHeight: 2.5,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
