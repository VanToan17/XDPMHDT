import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MoviePlayerScreen extends StatefulWidget {
  final String movieId;
  final String episodeId;

  const MoviePlayerScreen({
    super.key,
    required this.movieId,
    required this.episodeId,
  });

  @override
  State<MoviePlayerScreen> createState() => _MoviePlayerScreenState();
}

class _MoviePlayerScreenState extends State<MoviePlayerScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _showControls = true;
  bool _hasError = false;
  bool _isFullscreen = false;
  String _errorMessage = '';

  Map<String, dynamic>? episode;
  Future<void> _logView() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 0;
      print('👤 User ID for log view: $userId');

      if (userId <= 0) {
        print('⚠️ User ID không hợp lệ, không ghi nhận lượt xem');
        return;
      }

      final result = await ApiService.logView(
        filmId: int.parse(widget.movieId),
        contentId: int.tryParse(currentEpisodeId),
        userId: userId,
      );
      if (result['status'] == 'success') {
        print('👁️ Đã ghi nhận lượt xem thành công');
      } else {
        print('⚠️ Ghi nhận lượt xem thất bại: ${result['message']}');
      }
    } catch (e) {
      print('❌ Lỗi khi ghi nhận lượt xem: $e');
    }
  }

  Map<String, dynamic>? film;
  List<dynamic> episodes = [];
  List<dynamic> filteredEpisodes = [];
  List<dynamic> categories = [];
  List<int> seasons = [];
  int selectedSeason = 1;
  String selectedType = 'movie';
  String currentEpisodeId = '';
  bool isLoading = true;

  bool isLiked = false;
  bool isLikeLoading = false;

  @override
  void initState() {
    super.initState();
    currentEpisodeId = widget.episodeId;
    fetchMovieDetail();
    fetchAndPlay();
    _hideControlsAfterDelay();
  }

  Future<void> _saveLikeStatus(bool liked) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('liked_${widget.movieId}', liked);
  }

  Future<bool> _loadLikeStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('liked_${widget.movieId}') ?? false;
  }

  Future<void> fetchMovieDetail() async {
    try {
      final response = await ApiService.fetchMovieById(
        int.parse(widget.movieId),
      );
      print('📥 API response: $response');

      if (response['status'] == 'success') {
        final data = response['data'];
        final filmData = data['film'];
        final contents = data['contents'] as List;
        final categoryData = data['categories'] as List?;

        if (filmData != null && contents.isNotEmpty) {
          final currentEpisode = contents.firstWhere(
            (ep) => ep['id'].toString() == currentEpisodeId,
            orElse: () => contents.first,
          );

          final currentType = currentEpisode['type'] ?? 'movie';

          final localLikeStatus = await _loadLikeStatus();

          final apiLikeStatus = filmData['is_liked'] == true;
          final apiTotalLikes = filmData['total_likes'] ?? 0;

          setState(() {
            film = filmData;
            episodes = contents;
            categories = categoryData ?? [];
            selectedType = currentType;
            isLiked = localLikeStatus;
            film!['total_likes'] = apiTotalLikes;
            film!['is_liked'] = localLikeStatus;
            isLoading = false;
          });

          _updateSeasonsAndEpisodes(updateSeason: true);

          print('🎬 Film loaded: ${filmData['title']}');
          print('🎭 Selected type: $selectedType');
          print('❤️ Local like status: $localLikeStatus');
          print('❤️ API like status: $apiLikeStatus');
          print('👍 API total likes: $apiTotalLikes');
        } else {
          print('⚠️ Film data null hoặc contents rỗng');
          setState(() => isLoading = false);
        }
      } else {
        print('❌ Response status không thành công: ${response['message']}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('❌ Lỗi fetchMovieDetail: $e');
      setState(() => isLoading = false);
    }
  }

  void _updateSeasonsAndEpisodes({bool updateSeason = false}) {
    final seasonKey = selectedType == 'movie' ? 'movie_season' : 'season';
    final allSeasons =
        episodes
            .where((ep) => ep['type'] == selectedType)
            .map((e) => e[seasonKey] ?? 1)
            .map((s) => int.tryParse(s.toString()) ?? 1)
            .toSet()
            .toList()
          ..sort();

    setState(() {
      seasons = allSeasons;
      if (updateSeason && allSeasons.isNotEmpty) {
        selectedSeason = allSeasons.first;
      }
      filteredEpisodes = episodes
          .where(
            (ep) =>
                ep['type'] == selectedType &&
                (ep[seasonKey] ?? 1) == selectedSeason,
          )
          .toList();
    });
  }

  Future<void> _handleLike() async {
    if (isLikeLoading || film == null) return;

    setState(() {
      isLikeLoading = true;
    });

    try {
      final result = await ApiService.toggleLikeFilmOrEpisode(
        filmId: int.parse(widget.movieId),
        contentId: int.tryParse(widget.episodeId),
        isCurrentlyLiked: isLiked,
      );
      print(
        '📤 Sending like with filmId=${widget.movieId}, contentId=${widget.episodeId}',
      );
      print('📥 Like API response: $result');

      if (result['status'] == 'success') {
        final newLikeStatus = result['liked'] == true;

        final currentLikes = film!['total_likes'] ?? 0;
        int newTotalLikes;

        if (newLikeStatus && !isLiked) {
          newTotalLikes = currentLikes + 1;
        } else if (!newLikeStatus && isLiked) {
          newTotalLikes = currentLikes > 0 ? currentLikes - 1 : 0;
        } else {
          newTotalLikes = currentLikes;
        }

        await _saveLikeStatus(newLikeStatus);

        setState(() {
          isLiked = newLikeStatus;
          film!['total_likes'] = newTotalLikes;
          film!['is_liked'] = newLikeStatus;
        });

        print(
          '✅ Like updated successfully - New status: $isLiked, Total: $newTotalLikes',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isLiked ? '❤️ Đã thích phim!' : '💔 Đã bỏ thích phim!',
            ),
            duration: const Duration(seconds: 1),
            backgroundColor: isLiked ? Colors.green : Colors.orange,
          ),
        );
      } else {
        print('❌ Like API failed: ${result['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Lỗi khi cập nhật trạng thái thích',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Lỗi khi xử lý like: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi kết nối: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLikeLoading = false;
      });
    }
  }

  void _hideControlsAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _showControls) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _hideControlsAfterDelay();
    }
  }

  Future<void> _toggleFullscreen() async {
    if (!mounted) return;

    try {
      final isPlaying = _controller?.value.isPlaying ?? false;
      final currentPosition = _controller?.value.position ?? Duration.zero;

      setState(() {
        _isFullscreen = !_isFullscreen;
      });

      if (_isFullscreen) {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.immersiveSticky,
          overlays: [],
        );
      } else {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
        );
      }

      await Future.delayed(const Duration(milliseconds: 100));

      if (_controller != null && _isInitialized && mounted) {
        if (currentPosition > Duration.zero) {
          await _controller!.seekTo(currentPosition);
        }
        if (isPlaying) {
          await _controller!.play();
        }
      }

      if (mounted) {
        setState(() {
          _showControls = true;
        });
        _hideControlsAfterDelay();
      }
    } catch (e) {
      print('❌ Lỗi khi chuyển đổi chế độ toàn màn hình: $e');

      if (mounted) {
        setState(() {
          _isFullscreen = false;
        });

        try {
          await SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
          ]);
          await SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.manual,
            overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
          );
        } catch (resetError) {
          print('❌ Lỗi khi reset orientation: $resetError');
        }
      }
    }
  }

  Future<void> _switchToEpisode(String newEpisodeId) async {
    if (newEpisodeId == currentEpisodeId) return;

    setState(() {
      currentEpisodeId = newEpisodeId;
      _isInitialized = false;
      _hasError = false;
    });

    await fetchAndPlay();
  }

  Future<void> fetchAndPlay() async {
    try {
      setState(() {
        _hasError = false;
        _errorMessage = '';
      });

      final ep = await ApiService.getPlayableItemById(
        filmId: int.parse(widget.movieId),
        contentId: int.parse(currentEpisodeId),
      );

      if (ep != null && ep['source'] != null) {
        String videoUrl = ApiService.resolveVideoUrl(ep['source']);
        print('🎬 Video URL: $videoUrl');

        if (videoUrl.contains('/storage/storage/')) {
          videoUrl = videoUrl.replaceAll('/storage/storage/', '/storage/');
        }

        final uri = Uri.tryParse(videoUrl);
        if (uri == null || !uri.hasAbsolutePath) {
          throw Exception('URL video không hợp lệ: $videoUrl');
        }

        await _initializeController(videoUrl);

        setState(() {
          episode = ep;
        });
      } else {
        throw Exception('Không tìm thấy nội dung hoặc thiếu source');
      }
    } catch (e) {
      print('❌ Lỗi khi lấy và phát nội dung: $e');
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _initializeController(String videoUrl) async {
    try {
      await _controller?.dispose();

      final controller = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        httpHeaders: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36',
        },
      );

      controller.addListener(() {
        if (controller.value.hasError) {
          print(
            '❌ Video Controller Error: ${controller.value.errorDescription}',
          );
          setState(() {
            _hasError = true;
            _errorMessage =
                controller.value.errorDescription ?? 'Lỗi không xác định';
          });
        }
      });

      await controller.initialize();

      if (!controller.value.isInitialized) {
        throw Exception('Không thể khởi tạo video player');
      }

      await controller.setLooping(true);
      await controller.play();
      await _logView();

      setState(() {
        _controller = controller;
        _isInitialized = true;
        _hasError = false;
      });

      print('✅ Video được khởi tạo thành công');
    } catch (e) {
      print('❌ Lỗi khởi tạo controller: $e');
      throw e;
    }
  }

  Future<void> _retryPlayback() async {
    setState(() {
      _isInitialized = false;
      _hasError = false;
    });
    await fetchAndPlay();
  }

  @override
  void dispose() {
    _controller?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '${duration.inHours > 0 ? '${twoDigits(duration.inHours)}:' : ''}$minutes:$seconds';
  }

  Widget _buildVideoPlayer() {
    if (_hasError) {
      return Container(
        height: _isFullscreen ? MediaQuery.of(context).size.height : 200,
        width: _isFullscreen
            ? MediaQuery.of(context).size.width
            : double.infinity,
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 8),
                const Text(
                  'Không thể tải video',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _retryPlayback,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        height: _isFullscreen ? MediaQuery.of(context).size.height : 200,
        width: _isFullscreen
            ? MediaQuery.of(context).size.width
            : double.infinity,
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.blue),
              SizedBox(height: 12),
              Text(
                'Đang tải video...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: _isFullscreen ? MediaQuery.of(context).size.height : 200,
      width: _isFullscreen
          ? MediaQuery.of(context).size.width
          : double.infinity,
      color: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleControls,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              ),
            ),
          ),
          if (_showControls && _controller != null) _buildVideoControls(),
        ],
      ),
    );
  }

  Widget _buildVideoControls() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black54,
            Colors.transparent,
            Colors.transparent,
            Colors.black87,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () {
                        if (_isFullscreen) {
                          _toggleFullscreen();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    Expanded(
                      child: Text(
                        episode != null
                            ? (episode!['movie_name'] ?? 'Video')
                            : 'Đang phát...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!_isFullscreen)
                      IconButton(
                        icon: const Icon(
                          Icons.settings,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          // TODO: Implement settings
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _controller!.value.isPlaying
                      ? _controller!.pause()
                      : _controller!.play();
                });
                _hideControlsAfterDelay();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(_isFullscreen ? 12 : 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  VideoProgressIndicator(
                    _controller!,
                    allowScrubbing: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    colors: const VideoProgressColors(
                      playedColor: Colors.red,
                      backgroundColor: Colors.white24,
                      bufferedColor: Colors.white60,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        _formatDuration(_controller!.value.position),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (_isFullscreen) ...[
                        PopupMenuButton<double>(
                          icon: const Icon(
                            Icons.speed,
                            color: Colors.white,
                            size: 20,
                          ),
                          color: Colors.grey[800],
                          onSelected: (speed) {
                            _controller!.setPlaybackSpeed(speed);
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 0.5,
                              child: Text(
                                '0.5x',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 0.75,
                              child: Text(
                                '0.75x',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 1.0,
                              child: Text(
                                '1.0x',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 1.25,
                              child: Text(
                                '1.25x',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 1.5,
                              child: Text(
                                '1.5x',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 2.0,
                              child: Text(
                                '2.0x',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                      ],
                      const Spacer(),
                      Text(
                        _formatDuration(_controller!.value.duration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: Icon(
                          _isFullscreen
                              ? Icons.fullscreen_exit
                              : Icons.fullscreen,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: _toggleFullscreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    if (categories.isEmpty) return const SizedBox();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thể loại: ',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        Expanded(
          child: Wrap(
            spacing: 8,
            children: categories.map((cat) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  cat['category_name'] ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: TextButton.icon(
            onPressed: isLikeLoading ? null : _handleLike,
            icon: isLikeLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                      key: ValueKey(isLiked),
                      size: 18,
                      color: isLiked ? Colors.blue : Colors.white,
                    ),
                  ),
            label: Text(
              'Thích (${film?['total_likes'] ?? 0})',
              style: TextStyle(
                color: isLiked ? Colors.blue : Colors.white60,
                fontWeight: isLiked ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: isLiked
                  ? Colors.blue.withOpacity(0.2)
                  : Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isLiked ? Colors.blue : Colors.white24,
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.visibility, color: Colors.white60, size: 16),
              const SizedBox(width: 4),
              Text(
                '${film?['total_views'] ?? 0}',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.thumb_up, color: Colors.white60, size: 16),
              const SizedBox(width: 4),
              Text(
                '${film?['total_likes'] ?? 0}',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdowns() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Loại nội dung:',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: ['movie', 'episode'].map((type) {
            final isSelected = selectedType == type;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: OutlinedButton(
                onPressed: () {
                  setState(() => selectedType = type);
                  _updateSeasonsAndEpisodes(updateSeason: true);
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: isSelected
                      ? Colors.blue
                      : Colors.transparent,
                  side: BorderSide(
                    color: isSelected ? Colors.blue : Colors.white54,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  type == 'movie' ? 'Movie' : 'Episode',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (seasons.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Seasons:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: seasons.map((s) {
              final isSelected = s == selectedSeason;
              return ChoiceChip(
                label: Text('Season $s'),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => selectedSeason = s);
                  _updateSeasonsAndEpisodes();
                },
                selectedColor: Colors.blue,
                backgroundColor: Colors.grey[800],
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSeasonSelector() {
    if (seasons.length <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chọn Season:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: seasons.map((s) {
              final isSelected = s == selectedSeason;
              return ChoiceChip(
                label: Text('Season $s'),
                selected: isSelected,
                onSelected: (_) => setState(() => selectedSeason = s),
                selectedColor: Colors.blue,
                backgroundColor: Colors.grey[800],
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeList() {
    if (filteredEpisodes.isEmpty) {
      return const Center(
        child: Text(
          'Không có tập nào',
          style: TextStyle(color: Colors.white60),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Danh sách tập:',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: filteredEpisodes.map((ep) {
              final episodeId = ep['id']?.toString();
              final episodeNumber =
                  ep['episode_number'] ?? filteredEpisodes.indexOf(ep) + 1;
              final isSelected = episodeId == currentEpisodeId;

              return ChoiceChip(
                label: Text('Tập $episodeNumber'),
                selected: isSelected,
                onSelected: (selected) {
                  if (episodeId != null) {
                    _switchToEpisode(episodeId);
                  }
                },
                selectedColor: Colors.blue,
                backgroundColor: Colors.grey[800],
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isSelected ? Colors.blue : Colors.grey[700]!,
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                materialTapTargetSize: MaterialTapTargetSize.padded,
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : film == null
          ? const Center(
              child: Text(
                'Không thể tải thông tin phim',
                style: TextStyle(color: Colors.white),
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  if (_isFullscreen)
                    _buildVideoPlayer()
                  else
                    Expanded(flex: 2, child: _buildVideoPlayer()),
                  if (!_isFullscreen)
                    Expanded(
                      flex: 3,
                      child: ListView(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 16,
                        ),
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      ApiService.resolveImageUrl(
                                        film!['img'] ?? '',
                                      ),
                                      width: 100,
                                      height: 150,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                width: 100,
                                                height: 150,
                                                color: Colors.grey[800],
                                                child: const Icon(
                                                  Icons.movie,
                                                  color: Colors.white,
                                                  size: 40,
                                                ),
                                              ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 6,
                                    right: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.thumb_up,
                                            color: Colors.white70,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${film?['total_likes'] ?? 0}',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      film!['title'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildStats(),
                                    const SizedBox(height: 12),
                                    Text(
                                      film!['description'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                        height: 1.4,
                                      ),
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildCategories(),
                          const SizedBox(height: 16),
                          _buildActionButtons(),
                          const SizedBox(height: 24),
                          _buildDropdowns(),
                          const SizedBox(height: 0),
                          _buildEpisodeList(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
