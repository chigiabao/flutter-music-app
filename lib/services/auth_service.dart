import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/song.dart';

/// Quản lý xác thực người dùng và thông tin cá nhân.
/// Danh sách bài đã thích lưu tại Firestore: users/{uid}/likes/{songId}.
class AuthService extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  StreamSubscription<User?>? _userSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _likesSub;
  List<Song> _liked = [];

  AuthService() {
    _userSub = _auth.userChanges().listen((u) {
      _likesSub?.cancel();
      _liked = [];
      if (u != null) {
        _likesSub = _likesRef(u.uid).snapshots().listen((snap) {
          _liked = snap.docs
              .map((d) => Song.fromJson(d.data(), id: d.id))
              .toList();
          notifyListeners();
        }, onError: (_) {});
      }
      notifyListeners();
    });
  }

  CollectionReference<Map<String, dynamic>> _likesRef(String uid) =>
      FirebaseFirestore.instance.collection('users/$uid/likes');

  User? get currentUser => _auth.currentUser;
  String? get uid => _auth.currentUser?.uid;
  String? get user => _auth.currentUser?.email;
  String? get displayName => _auth.currentUser?.displayName;
  String? get photoUrl => _auth.currentUser?.photoURL;
  bool get loggedIn => _auth.currentUser != null;
  List<Song> get liked => List.unmodifiable(_liked);

  /// Đăng ký tài khoản mới kèm Tên hiển thị và Avatar
  Future<String?> register({
    required String name,
    required String email,
    required String password,
    String? avatarUrl,
  }) async {
    final n = name.trim();
    final e = email.trim();
    final p = password.trim();

    if (n.isEmpty) return 'Vui lòng nhập tên người dùng';
    if (e.isEmpty) return 'Vui lòng nhập địa chỉ Email';
    if (!e.contains('@') || !e.contains('.')) {
      return 'Định dạng Email không hợp lệ (ví dụ: test@gmail.com)';
    }
    if (p.isEmpty) return 'Vui lòng nhập Mật khẩu';
    if (p.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';

    return _run(() async {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: e,
        password: p,
      );
      if (cred.user != null) {
        final photo = (avatarUrl != null && avatarUrl.trim().isNotEmpty)
            ? avatarUrl.trim()
            : 'https://api.dicebear.com/7.x/bottts/png?seed=$n';
        await cred.user!.updateDisplayName(n);
        await cred.user!.updatePhotoURL(photo);

        // Lưu thông tin người dùng vào Firestore
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'displayName': n,
          'email': e,
          'photoUrl': photo,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Đăng nhập bằng Email và Mật khẩu
  Future<String?> login(String email, String password) {
    final e = email.trim();
    final p = password.trim();
    if (e.isEmpty) return Future.value('Vui lòng nhập địa chỉ Email');
    if (p.isEmpty) return Future.value('Vui lòng nhập Mật khẩu');
    return _run(() =>
        _auth.signInWithEmailAndPassword(email: e, password: p));
  }

  /// Cập nhật thông tin người dùng (Tên & Avatar)
  Future<String?> updateProfile({
    required String name,
    required String avatarUrl,
  }) async {
    final u = _auth.currentUser;
    if (u == null) return 'Chưa đăng nhập';
    final n = name.trim();
    final a = avatarUrl.trim();

    if (n.isEmpty) return 'Tên người dùng không được để trống';

    return _run(() async {
      await u.updateDisplayName(n);
      if (a.isNotEmpty) {
        await u.updatePhotoURL(a);
      }
      await FirebaseFirestore.instance.collection('users').doc(u.uid).set({
        'displayName': n,
        'email': u.email,
        'photoUrl': a.isNotEmpty ? a : u.photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      notifyListeners();
    });
  }

  Future<String?> _run(Future<void> Function() action) async {
    try {
      await action();
      return null;
    } on FirebaseAuthException catch (e) {
      return switch (e.code) {
        'invalid-email' => 'Email không đúng định dạng',
        'weak-password' => 'Mật khẩu tối thiểu 6 ký tự',
        'email-already-in-use' => 'Email này đã được đăng ký',
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' =>
          'Sai email hoặc mật khẩu',
        'network-request-failed' => 'Không có kết nối mạng',
        'operation-not-allowed' =>
          'Chưa bật Sign-in method Email/Password trong Firebase Console',
        'channel-error' =>
          'Vui lòng nhập đầy đủ Email và Mật khẩu',
        _ => 'Lỗi (${e.code}): ${e.message ?? ''}',
      };
    } catch (e) {
      return 'Lỗi: $e';
    }
  }

  Future<void> logout() => _auth.signOut();

  bool isLiked(Song s) => _liked.any((e) => e.id == s.id);

  Future<void> toggleLike(Song s) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final doc = _likesRef(uid).doc(s.id);
    if (isLiked(s)) {
      await doc.delete();
    } else {
      await doc.set(s.toJson());
    }
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _likesSub?.cancel();
    super.dispose();
  }
}
