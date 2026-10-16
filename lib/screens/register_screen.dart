import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  final AuthService auth;
  const RegisterScreen({super.key, required this.auth});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  String? _error;
  bool _busy = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // Danh sách các avatar mẫu phong cách âm nhạc
  static const List<String> _sampleAvatars = [
    'https://api.dicebear.com/7.x/bottts/png?seed=MusicDj',
    'https://api.dicebear.com/7.x/bottts/png?seed=Vocalist',
    'https://api.dicebear.com/7.x/bottts/png?seed=BeatMaker',
    'https://api.dicebear.com/7.x/bottts/png?seed=Guitarist',
    'https://api.dicebear.com/7.x/bottts/png?seed=Pianist',
    'https://api.dicebear.com/7.x/bottts/png?seed=Rapper',
  ];

  late String _selectedAvatar;

  @override
  void initState() {
    super.initState();
    _selectedAvatar = _sampleAvatars[0];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final confirm = _confirmPassCtrl.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Vui lòng nhập tên người dùng');
      return;
    }
    if (email.isEmpty) {
      setState(() => _error = 'Vui lòng nhập địa chỉ Email');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _error = 'Email không hợp lệ (Ví dụ: user@gmail.com)');
      return;
    }
    if (pass.isEmpty) {
      setState(() => _error = 'Vui lòng nhập Mật khẩu');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Mật khẩu phải có tối thiểu 6 ký tự');
      return;
    }
    if (pass != confirm) {
      setState(() => _error = 'Mật khẩu nhập lại không khớp!');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final err = await widget.auth.register(
      name: name,
      email: email,
      password: pass,
      avatarUrl: _selectedAvatar,
    );

    if (!mounted) return;
    if (err == null) {
      // Đăng ký thành công -> Đóng về trang chủ
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _error = err;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký tài khoản')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview Avatar
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        _selectedAvatar,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(Icons.person, size: 50),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Chọn Avatar đại diện của bạn:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70),
            ),
            const SizedBox(height: 10),

            // Danh sách avatar chọn nhanh
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
            const SizedBox(height: 16),

            // Tên người dùng
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Tên người dùng *',
                hintText: 'Ví dụ: Anh Quân',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),

            // Email
            TextField(
              controller: _emailCtrl,
              decoration: InputDecoration(
                labelText: 'Email *',
                hintText: 'vidu@gmail.com',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),

            // Mật khẩu
            TextField(
              controller: _passCtrl,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Mật khẩu *',
                hintText: 'Tối thiểu 6 ký tự',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),

            // Nhập lại mật khẩu
            TextField(
              controller: _confirmPassCtrl,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Nhập lại Mật khẩu *',
                hintText: 'Khớp với mật khẩu trên',
                prefixIcon: const Icon(Icons.lock_reset_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onSubmitted: (_) => _submit(),
            ),

            // Báo lỗi
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(top: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Nút đăng ký
            SizedBox(
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Đăng ký ngay',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 12),

            // Nút chuyển sang Đăng nhập
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Đã có tài khoản?', style: TextStyle(color: Colors.white70)),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đăng nhập ngay'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
