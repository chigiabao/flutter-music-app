import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final AuthService auth;
  const ProfileScreen({super.key, required this.auth});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameCtrl;
  late String _selectedAvatar;
  bool _busy = false;
  String? _error;
  String? _success;

  static const List<String> _sampleAvatars = [
    'https://api.dicebear.com/7.x/bottts/png?seed=MusicDj',
    'https://api.dicebear.com/7.x/bottts/png?seed=Vocalist',
    'https://api.dicebear.com/7.x/bottts/png?seed=BeatMaker',
    'https://api.dicebear.com/7.x/bottts/png?seed=Guitarist',
    'https://api.dicebear.com/7.x/bottts/png?seed=Pianist',
    'https://api.dicebear.com/7.x/bottts/png?seed=Rapper',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: widget.auth.displayName ?? widget.auth.user?.split('@').first ?? 'Người dùng',
    );
    _selectedAvatar = widget.auth.photoUrl ?? _sampleAvatars[0];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });

    final err = await widget.auth.updateProfile(
      name: _nameCtrl.text,
      avatarUrl: _selectedAvatar,
    );

    if (!mounted) return;
    setState(() {
      _busy = false;
      if (err == null) {
        _success = 'Cập nhật thông tin thành công!';
      } else {
        _error = err;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.auth;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý tài khoản'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar to viền phát sáng
            Center(
              child: Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 3.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.network(
                    _selectedAvatar,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: Theme.of(context).colorScheme.surface,
                      child: const Icon(Icons.person, size: 60),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              auth.displayName ?? 'Người dùng',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              auth.user ?? '',
              style: const TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 20),

            // Card thống kê
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Icon(Icons.favorite, color: Colors.redAccent, size: 28),
                      const SizedBox(height: 4),
                      Text(
                        '${auth.liked.length}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Bài yêu thích',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 40, color: Colors.white10),
                  Column(
                    children: [
                      Icon(Icons.verified_user,
                          color: Theme.of(context).colorScheme.primary, size: 28),
                      const SizedBox(height: 4),
                      const Text(
                        'Thành viên',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Đã kích hoạt',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Đổi Avatar của bạn:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            const SizedBox(height: 10),

            // Danh sách avatar mẫu
            SizedBox(
              height: 56,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _sampleAvatars.length,
                itemBuilder: (context, i) {
                  final url = _sampleAvatars[i];
                  final isSelected = _selectedAvatar == url;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAvatar = url;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundImage: NetworkImage(url),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),

            // Input Tên người dùng
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Tên hiển thị',
                prefixIcon: const Icon(Icons.badge_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (_success != null)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  _success!,
                  style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                ),
              ),

            const SizedBox(height: 24),

            // Nút Lưu thay đổi
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Lưu thay đổi', style: TextStyle(fontSize: 16)),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _busy ? null : _save,
              ),
            ),
            const SizedBox(height: 14),

            // Nút Đăng xuất
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text('Đăng xuất',
                    style: TextStyle(color: Colors.redAccent, fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  auth.logout();
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
