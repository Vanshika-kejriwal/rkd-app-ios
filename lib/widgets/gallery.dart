import 'dart:io';
import 'package:business_app/permissions/permitrequest.dart';
import 'package:business_app/widgets/mediaviewer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
// import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
// import 'package:video_player/video_player.dart';

class CompleteGalleryScreen extends StatefulWidget {
  final List<Map<String, dynamic>> mediaItems;

  const CompleteGalleryScreen({super.key, required this.mediaItems});

  @override
  State<CompleteGalleryScreen> createState() => _CompleteGalleryScreenState();
}

class _CompleteGalleryScreenState extends State<CompleteGalleryScreen> {
  final Set<int> _selectedIndexes = {};
  bool _isMultiSelectMode = false;

  bool _isVideo(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.mp4') ||
        lower.contains('.mov') ||
        lower.contains('.avi');
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndexes.contains(index)) {
        _selectedIndexes.remove(index);
        if (_selectedIndexes.isEmpty) _isMultiSelectMode = false;
      } else {
        _selectedIndexes.add(index);
        _isMultiSelectMode = true;
      }
    });
  }

  Future<void> _downloadAndShareDirectly() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text("Preparing files..."),
              ],
            ),
          ),
        ),
      ),
    );

    final client = HttpClient();
    final tempDir = await getTemporaryDirectory();
    List<XFile> filesToShare = [];

    final selectedUrls = _selectedIndexes
        .map((index) => widget.mediaItems[index]['url_or_path'].toString())
        .toList();

    for (String url in selectedUrls) {
      try {
        String directUrl = url.replaceAll('?dl=0', '?raw=1');
        String extension = _isVideo(directUrl) ? 'mp4' : 'jpg';
        String tempPath =
            '${tempDir.path}/share_${DateTime.now().microsecondsSinceEpoch}.$extension';
        File tempFile = File(tempPath);

        final request = await client.getUrl(Uri.parse(directUrl));
        final response = await request.close();

        if (response.statusCode == 200) {
          await response.pipe(tempFile.openWrite());
          filesToShare.add(XFile(tempPath));
        }
      } catch (e) {
        debugPrint("Sharing download failed: $e");
      }
    }
    client.close();

    if (mounted) Navigator.pop(context);

    if (filesToShare.isNotEmpty) {
      await SharePlus.instance.share(ShareParams(files: filesToShare));
      for (var file in filesToShare) {
        final localFile = File(file.path);
        if (await localFile.exists()) {
          await localFile.delete();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.grey[900],
        title: Text(
          _isMultiSelectMode
              ? '${_selectedIndexes.length} Selected'
              : 'Gallery',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          if (_isMultiSelectMode)
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: _downloadAndShareDirectly,
            ),
          if (_isMultiSelectMode)
            IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () async{
              // download selected files to device
              await _downloadSelectedFiles();
            },
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(4),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: widget.mediaItems.length,
        itemBuilder: (context, index) {
          final item = widget.mediaItems[index];
          final url = item['url_or_path'].toString();
          final directUrl = url.replaceAll('?dl=0', '?raw=1');
          final isSelected = _selectedIndexes.contains(index);

          return GestureDetector(
            onLongPress: () => _toggleSelection(index),
            onTap: () {
              if (_isMultiSelectMode) {
                _toggleSelection(index);
              } else {
                // HERE: Open the full-screen swiper when tapped normally
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScreenSwiperScreen(
                      mediaItems: widget.mediaItems,
                      initialIndex: index,
                    ),
                  ),
                );
              }
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                _isVideo(directUrl)
                    ? Container(
                        color: Colors.grey[800],
                        child: const Center(
                            child: Icon(Icons.play_circle_outline,
                                color: Colors.white, size: 40)),
                      )
                    : CachedNetworkImage(
                        imageUrl: directUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: Colors.grey[900]),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.broken_image, color: Colors.white),
                      ),
                if (isSelected) ...[
                  Container(color: Colors.black45),
                  const Positioned(
                    top: 8,
                    right: 8,
                    child:
                        Icon(Icons.check_circle, color: Colors.blue, size: 28),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _downloadSelectedFiles() async {
    // 1. Show a loader so the user knows downloading is happening
    final hasPermission = await requestStoragePermission();
    if (!hasPermission) return; // Halt execution if permission was denied

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text("Saving to device gallery..."),
              ],
            ),
          ),
        ),
      ),
    );

    final client = HttpClient();
    final tempDir = await getTemporaryDirectory();
    int successCount = 0;

    // Extract selected URLs from your list state
    final selectedUrls = _selectedIndexes
        .map((index) => widget.mediaItems[index]['url_or_path'].toString())
        .toList();

    for (String url in selectedUrls) {
      try {
        String directUrl = url.replaceAll('?dl=0', '?raw=1');
        String extension = _isVideo(directUrl) ? 'mp4' : 'jpg';
        String tempPath =
            '${tempDir.path}/download_${DateTime.now().microsecondsSinceEpoch}.$extension';
        File tempFile = File(tempPath);

        // Stream file over HTTP
        final request = await client.getUrl(Uri.parse(directUrl));
        final response = await request.close();

        if (response.statusCode == 200) {
          await response.pipe(tempFile.openWrite());

          // Save directly to device Camera Roll/Photos app using gal
          if (extension == 'mp4') {
            await Gal.putVideo(tempPath);
          } else {
            await Gal.putImage(tempPath);
          }
          successCount++;
        }

        // Delete the temporary cache copy immediately
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (e) {
        debugPrint("Error downloading file: $e");
      }
    }
    client.close();

    // 2. Dismiss loading dialog
    if (mounted) Navigator.pop(context);

    // 3. Reset multi-select UI mode state
    setState(() {
      _selectedIndexes.clear();
      _isMultiSelectMode = false;
    });

    // 4. Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Successfully downloaded $successCount file(s) to Gallery!')),
      );
    }
  }
}
