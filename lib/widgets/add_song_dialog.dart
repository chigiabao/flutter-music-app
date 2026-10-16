import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/music_api.dart';

class AddSongDialog extends StatefulWidget {
  final VoidCallback onSongAdded;
  final String? uploaderUid;

  const AddSongDialog({
    super.key,
    required this.onSongAdded,
    this.uploaderUid,
  });

  @override
  State<AddSongDialog> createState() => _AddSongDialogState();
}

class _AddSongDialogState extends State<AddSongDialog> {
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _audioUrlController = TextEditingController();
  final _artworkUrlController = TextEditingController();

  PlatformFile? _audioFile;
  int _audioFileSize = 0;

  PlatformFile? _coverFile;
  Uint8List? _coverBytes;

  int _selectedPresetIndex = 0;
  bool _useCustomCover = false;
  bool _showManualUrl = false;

  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';

  static const List<Map<String, String>> _presets = [
    {
      'name': 'Neon',
      'url': 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&q=80',
    },
    {
      'name': 'Cyber',
      'url': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500&q=80',
    },
    {
      'name': 'Acoustic',
      'url': 'https://images.unsplash.com/photo-1487180144351-b8472da7d491?w=500&q=80',
    },
    {
      'name': 'Lofi',
      'url': 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?w=500&q=80',
    },
    {
      'name': 'Vinyl',
      'url': 'https://images.unsplash.com/photo-1539375665275-f9de415ef9ac?w=500&q=80',
    },
    {
      'name': 'Sunset',
      'url': 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&q=80',
    },
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _audioUrlController.dispose();
    _artworkUrlController.dispose();
    super.dispose();
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _cleanFileNameToTitle(String fileName) {
    var name = fileName;
    final dot = name.lastIndexOf('.');
    if (dot > 0) name = name.substring(0, dot);
    name = name.replaceAll('_', ' ').replaceAll('-', ' ').trim();
    return name;
  }

  Future<void> _pickAudioFile() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'wav', 'aac', 'flac', 'ogg'],
      );
      if (file != null) {
        final length = (await file.length()) ?? file.lengthSync() ?? 0;
        setState(() {
          _audioFile = file;
          _audioFileSize = length;
          if (_titleController.text.trim().isEmpty) {
            _titleController.text = _cleanFileNameToTitle(file.name);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi chọn file nhạc: $e')),
        );
      }
    }
  }

  Future<void> _pickCoverImage() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.image,
      );
      if (file != null) {
        Uint8List? bytes;
        if (file.path == null || kIsWeb) {
          bytes = await file.readAsBytes();
        }
        setState(() {
          _coverFile = file;
          _coverBytes = bytes;
          _useCustomCover = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi chọn ảnh bìa: $e')),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    final title = _titleController.text.trim();
    final artist = _artistController.text.trim().isEmpty
        ? 'Nghệ sĩ chưa rõ'
        : _artistController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên bài hát!')),
      );
      return;
    }

    final hasAudioFile = _audioFile != null;
    final hasAudioUrl = _audioUrlController.text.trim().isNotEmpty;

    if (!hasAudioFile && !hasAudioUrl) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn file nhạc từ máy hoặc nhập URL MP3!'),
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Đang chuẩn bị...';
    });

    try {
      String finalAudioUrl = '';
      String finalArtworkUrl = '';

      // 1. Upload Cover Image if picked from device
      if (_useCustomCover && _coverFile != null) {
        setState(() => _uploadStatus = 'Đang tải ảnh bìa lên...');
        finalArtworkUrl = await MusicApi.uploadFile(
          file: _coverFile!,
          folder: 'covers',
          onProgress: (_) {},
        );
      } else if (_artworkUrlController.text.trim().isNotEmpty) {
        finalArtworkUrl = _artworkUrlController.text.trim();
      } else {
        finalArtworkUrl = _presets[_selectedPresetIndex]['url']!;
      }

      // 2. Upload Audio file if picked from device
      if (hasAudioFile) {
        setState(() => _uploadStatus = 'Đang tải bài hát lên máy chủ (0%)...');
        finalAudioUrl = await MusicApi.uploadFile(
          file: _audioFile!,
          folder: 'songs',
          onProgress: (p) {
            if (mounted) {
              setState(() {
                _uploadProgress = p;
                _uploadStatus =
                    'Đang tải bài hát lên máy chủ (${(p * 100).toInt()}%)...';
              });
            }
          },
        );
      } else {
        finalAudioUrl = _audioUrlController.text.trim();
      }

      // 3. Save song record to Firestore
      setState(() => _uploadStatus = 'Đang lưu vào danh sách bài hát...');
      await MusicApi.addSong(
        title: title,
        artist: artist,
        artworkUrl: finalArtworkUrl,
        audioUrl: finalAudioUrl,
        uploaderUid: widget.uploaderUid,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Đã thêm bài hát "$title" thành công!'),
                ),
              ],
            ),
          ),
        );
        widget.onSongAdded();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
              'Lỗi khi thêm bài hát: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return PopScope(
      canPop: !_isUploading,
      child: Dialog(
        backgroundColor: const Color(0xFF171426),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.library_music_rounded,
                          color: primaryColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thêm bài hát mới',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Chọn nhạc và ảnh trực tiếp từ máy của bạn',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_isUploading)
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // 1. File Nhạc từ thiết bị
                const Text(
                  '1. FILE NHẠC TỪ MÁY *',
                  style: TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                if (_audioFile == null)
                  InkWell(
                    onTap: _isUploading ? null : _pickAudioFile,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF201B35),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.file_upload_outlined,
                              color: primaryColor,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Nhấn để chọn file nhạc từ thiết bị',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Hỗ trợ file .mp3, .m4a, .wav, .flac',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF201B35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF10B981).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.audiotrack_rounded,
                            color: Color(0xFF10B981),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _audioFile!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_formatFileSize(_audioFileSize)} • Sẵn sàng tải lên',
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!_isUploading)
                          IconButton(
                            tooltip: 'Chọn file khác',
                            icon: const Icon(Icons.sync_rounded,
                                color: Colors.white70),
                            onPressed: _pickAudioFile,
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: 18),

                // 2. Thông tin bài hát
                const Text(
                  '2. THÔNG TIN BÀI HÁT',
                  style: TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleController,
                  enabled: !_isUploading,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Tên bài hát *',
                    hintText: 'VD: Nơi Này Có Anh',
                    prefixIcon:
                        const Icon(Icons.music_note, color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF201B35),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _artistController,
                  enabled: !_isUploading,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Nghệ sĩ',
                    hintText: 'VD: Sơn Tùng M-TP',
                    prefixIcon:
                        const Icon(Icons.person_outline, color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF201B35),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),

                const SizedBox(height: 18),

                // 3. Ảnh bìa (Artwork)
                const Text(
                  '3. ẢNH BÌA BÀI HÁT',
                  style: TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),

                // Nút chọn ảnh từ thiết bị
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: _useCustomCover
                                ? primaryColor
                                : Colors.white24,
                          ),
                          backgroundColor: _useCustomCover
                              ? primaryColor.withValues(alpha: 0.12)
                              : const Color(0xFF201B35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _isUploading ? null : _pickCoverImage,
                        icon: Icon(
                          _useCustomCover
                              ? Icons.image_rounded
                              : Icons.photo_camera_back_outlined,
                          size: 18,
                          color: _useCustomCover ? primaryColor : Colors.white70,
                        ),
                        label: Text(
                          _useCustomCover
                              ? 'Ảnh máy: ${_coverFile?.name ?? "Đã chọn"}'
                              : 'Chọn ảnh từ máy',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                _useCustomCover ? Colors.white : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                    if (_useCustomCover) ...[
                      const SizedBox(width: 8),
                      // Preview thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 42,
                          height: 42,
                          child: _coverFile?.path != null && !kIsWeb
                              ? Image.file(
                                  File(_coverFile!.path!),
                                  fit: BoxFit.cover,
                                )
                              : (_coverBytes != null
                                  ? Image.memory(
                                      _coverBytes!,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(color: Colors.white12)),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Bỏ ảnh máy',
                        icon: const Icon(Icons.cancel_outlined,
                            color: Colors.white54, size: 20),
                        onPressed: _isUploading
                            ? null
                            : () {
                                setState(() {
                                  _coverFile = null;
                                  _coverBytes = null;
                                  _useCustomCover = false;
                                });
                              },
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 10),

                // Hoặc chọn ảnh mẫu có sẵn
                const Text(
                  'Hoặc chọn ảnh bìa mẫu có sẵn:',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _presets.length,
                    itemBuilder: (context, index) {
                      final item = _presets[index];
                      final isSelected =
                          !_useCustomCover && _selectedPresetIndex == index;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: _isUploading
                              ? null
                              : () {
                                  setState(() {
                                    _useCustomCover = false;
                                    _coverFile = null;
                                    _coverBytes = null;
                                    _selectedPresetIndex = index;
                                  });
                                },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? primaryColor
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item['url']!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      color: Colors.white12,
                                      child: const Icon(Icons.music_note,
                                          size: 16),
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: 0.45),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 14),

                // Toggle tùy chọn nhập link trực tiếp
                InkWell(
                  onTap: () =>
                      setState(() => _showManualUrl = !_showManualUrl),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          _showManualUrl
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_right,
                          color: Colors.white54,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Tùy chọn nâng cao (Nhập URL trực tiếp)',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_showManualUrl) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _audioUrlController,
                    enabled: !_isUploading,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'URL Nhạc MP3 trực tiếp',
                      hintText: 'https://.../song.mp3',
                      filled: true,
                      fillColor: const Color(0xFF201B35),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _artworkUrlController,
                    enabled: !_isUploading,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'URL Ảnh bìa trực tiếp',
                      hintText: 'https://.../cover.jpg',
                      filled: true,
                      fillColor: const Color(0xFF201B35),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ],

                // Upload progress indicator
                if (_isUploading) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF201B35),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF8B5CF6),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _uploadStatus,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_uploadProgress > 0) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: _uploadProgress,
                              minHeight: 6,
                              backgroundColor: Colors.white12,
                              color: const Color(0xFF8B5CF6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 22),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!_isUploading)
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Hủy',
                            style: TextStyle(color: Colors.white60)),
                      ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isUploading ? null : _handleSubmit,
                      icon: _isUploading
                          ? const SizedBox.shrink()
                          : const Icon(Icons.cloud_upload_rounded, size: 18),
                      label: Text(
                        _isUploading ? 'Đang tải lên...' : 'Tải lên & Thêm',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
