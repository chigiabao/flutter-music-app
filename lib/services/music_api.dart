import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/song.dart';

/// Metadata bài hát lưu ở Firestore (collection `songs`).
/// Trường `audioUrl` là download URL của file mp3 trên Firebase Storage
/// (hoặc URL mp3 bất kỳ); app stream trực tiếp từ URL, không tải về máy.
class MusicApi {
  static final _songs = FirebaseFirestore.instance.collection('songs');

  static Future<List<Song>> getSongs() async {
    final snap = await _songs.orderBy('title').get();
    if (snap.docs.isEmpty) {
      try {
        await seed();
        final seeded = await _songs.orderBy('title').get();
        if (seeded.docs.isNotEmpty) {
          return seeded.docs
              .map((d) => Song.fromJson(d.data(), id: d.id))
              .toList();
        }
      } catch (_) {}
    }
    return snap.docs.map((d) => Song.fromJson(d.data(), id: d.id)).toList();
  }

  /// Tìm theo tên bài hoặc nghệ sĩ (lọc phía client trên danh sách đã tải).
  static List<Song> filter(List<Song> all, String term) {
    final q = term.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where((s) =>
            s.title.toLowerCase().contains(q) ||
            s.artist.toLowerCase().contains(q))
        .toList();
  }

  /// Thêm một bài hát thật vào Firestore.
  static Future<void> addSong({
    required String title,
    required String artist,
    required String artworkUrl,
    required String audioUrl,
    String? uploaderUid,
  }) async {
    final data = <String, dynamic>{
      'title': title.trim(),
      'artist': artist.trim(),
      'artworkUrl': artworkUrl.trim(),
      'audioUrl': audioUrl.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (uploaderUid != null) {
      data['uploaderUid'] = uploaderUid;
    }
    await _songs.add(data);
  }

  /// Tải file từ thiết bị lên Firebase Storage và trả về link streaming downloadURL.
  static Future<String> uploadFile({
    required PlatformFile file,
    required String folder, // 'songs' hoặc 'covers'
    void Function(double progress)? onProgress,
  }) async {
    final storage = FirebaseStorage.instance;

    final ext = file.extension?.toLowerCase() ?? '';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sanitizedName = file.name
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
        .replaceAll(' ', '_');
    final ref = storage.ref().child(folder).child('${timestamp}_$sanitizedName');

    SettableMetadata? metadata;
    if (folder == 'songs') {
      metadata = SettableMetadata(
        contentType: ext == 'mp3'
            ? 'audio/mpeg'
            : ext == 'wav'
                ? 'audio/wav'
                : ext == 'm4a'
                    ? 'audio/mp4'
                    : ext == 'ogg'
                        ? 'audio/ogg'
                        : 'audio/mpeg',
      );
    } else if (folder == 'covers') {
      metadata = SettableMetadata(
        contentType: ext == 'png'
            ? 'image/png'
            : ext == 'webp'
                ? 'image/webp'
                : 'image/jpeg',
      );
    }

    UploadTask task;
    final localPath = file.path;
    if (localPath != null && localPath.isNotEmpty && !kIsWeb) {
      task = ref.putFile(File(localPath), metadata);
    } else {
      final bytes = await file.readAsBytes();
      task = ref.putData(bytes, metadata);
    }

    if (onProgress != null) {
      task.snapshotEvents.listen((snapshot) {
        if (snapshot.totalBytes > 0) {
          final p = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(p.clamp(0.0, 1.0));
        }
      });
    }

    try {
      final snapshot = await task;
      return await snapshot.ref.getDownloadURL();
    } catch (_) {
      // Nếu Firebase Storage chưa kích hoạt hoặc bị lỗi, tự động tải lên Cloud lưu trữ công khai
      return await _uploadToCloudFallback(file);
    }
  }

  /// Tải file lên đám mây công khai để phát streaming online trực tiếp
  static Future<String> _uploadToCloudFallback(PlatformFile file) async {
    final boundary =
        '----WebKitFormBoundary${DateTime.now().millisecondsSinceEpoch}';
    final uri = Uri.parse('https://catbox.moe/user/api.php');
    final client = HttpClient();
    final request = await client.postUrl(uri);
    request.headers
        .set('content-type', 'multipart/form-data; boundary=$boundary');

    final bytes = file.path != null && !kIsWeb
        ? await File(file.path!).readAsBytes()
        : await file.readAsBytes();

    final postData = <int>[];
    void addField(String name, String value) {
      postData.addAll(utf8.encode('--$boundary\r\n'));
      postData.addAll(
          utf8.encode('Content-Disposition: form-data; name="$name"\r\n\r\n'));
      postData.addAll(utf8.encode('$value\r\n'));
    }

    addField('reqtype', 'fileupload');
    postData.addAll(utf8.encode('--$boundary\r\n'));
    postData.addAll(utf8.encode(
      'Content-Disposition: form-data; name="fileToUpload"; filename="${file.name}"\r\n',
    ));
    postData.addAll(utf8.encode('Content-Type: application/octet-stream\r\n\r\n'));
    postData.addAll(bytes);
    postData.addAll(utf8.encode('\r\n'));
    postData.addAll(utf8.encode('--$boundary--\r\n'));

    request.contentLength = postData.length;
    request.add(postData);

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    if (response.statusCode == 200 && responseBody.trim().startsWith('http')) {
      return responseBody.trim();
    }
    throw Exception('Lỗi khi tải lên file: $responseBody');
  }

  /// Xóa bài hát khỏi Firestore và dọn dẹp file trên Firebase Storage (nếu có).
  static Future<void> deleteSong(Song song) async {
    // 1. Xóa trong Firestore
    await _songs.doc(song.id).delete();

    // 2. Dọn dẹp file trên Storage nếu bài này được tải lên Cloud
    try {
      if (song.audioUrl.contains('firebasestorage.googleapis.com')) {
        await FirebaseStorage.instance.refFromURL(song.audioUrl).delete();
      }
    } catch (_) {}
    try {
      if (song.artworkUrl.contains('firebasestorage.googleapis.com')) {
        await FirebaseStorage.instance.refFromURL(song.artworkUrl).delete();
      }
    } catch (_) {}
  }

  /// Nạp danh sách các bài hát thật nổi tiếng có sẵn link MP3 streaming trực tiếp.
  /// Đối với nhạc của riêng bạn: upload file mp3 lên Firebase Storage,
  /// lấy Download URL và thêm qua form "Thêm bài hát".
  static Future<void> seed() async {
    final realSongs = [
      {
        'title': 'Faded',
        'artist': 'Alan Walker',
        'artworkUrl': 'https://samplesongs.netlify.app/album-arts/faded.jpg',
        'audioUrl': 'https://samplesongs.netlify.app/Faded.mp3',
      },
      {
        'title': 'Bad Liar',
        'artist': 'Imagine Dragons',
        'artworkUrl': 'https://samplesongs.netlify.app/album-arts/bad-liar.jpg',
        'audioUrl': 'https://samplesongs.netlify.app/Bad%20Liar.mp3',
      },
      {
        'title': 'Death Bed',
        'artist': 'Powfu',
        'artworkUrl': 'https://samplesongs.netlify.app/album-arts/death-bed.jpg',
        'audioUrl': 'https://samplesongs.netlify.app/Death%20Bed.mp3',
      },
      {
        'title': 'Without Me',
        'artist': 'Halsey',
        'artworkUrl': 'https://samplesongs.netlify.app/album-arts/without-me.jpg',
        'audioUrl': 'https://samplesongs.netlify.app/Without%20Me.mp3',
      },
      {
        'title': 'Solo',
        'artist': 'Clean Bandit',
        'artworkUrl': 'https://samplesongs.netlify.app/album-arts/solo.jpg',
        'audioUrl': 'https://samplesongs.netlify.app/Solo.mp3',
      },
      {
        'title': 'Hate Me',
        'artist': 'Ellie Goulding',
        'artworkUrl': 'https://samplesongs.netlify.app/album-arts/hate-me.jpg',
        'audioUrl': 'https://samplesongs.netlify.app/Hate%20Me.mp3',
      },
      {
        'title': 'Night Owl',
        'artist': 'Broke For Free',
        'artworkUrl':
            'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?w=400',
        'audioUrl':
            'https://files.freemusicarchive.org/storage-freemusicarchive-org/music/WFMU/Broke_For_Free/Directionless_EP/Broke_For_Free_-_01_-_Night_Owl.mp3',
      },
      {
        'title': 'Enthusiast',
        'artist': 'Tours',
        'artworkUrl':
            'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=400',
        'audioUrl':
            'https://files.freemusicarchive.org/storage-freemusicarchive-org/music/no_curator/Tours/Enthusiast/Tours_-_01_-_Enthusiast.mp3',
      },
    ];

    final batch = FirebaseFirestore.instance.batch();
    for (var i = 0; i < realSongs.length; i++) {
      final s = realSongs[i];
      final n = i + 1;
      batch.set(_songs.doc('song${n.toString().padLeft(2, '0')}'), s);
    }
    await batch.commit();
  }
}
