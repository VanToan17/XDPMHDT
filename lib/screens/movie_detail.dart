import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_group_9/widgets/user_session.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';

class MovieDetails extends StatefulWidget {
  final int id;
  const MovieDetails({super.key, required this.id});

  @override
  State<MovieDetails> createState() => _MovieDetailsState();
}

class _MovieDetailsState extends State<MovieDetails> {
  Map<String, dynamic>? film;
  List<dynamic> episodes = [];
  List<dynamic> filteredEpisodes = [];
  List<int> seasons = [];
  List<dynamic> categories = [];
  int selectedSeason = 1;
  String selectedType = 'movie';
  bool isLoading = true;
  bool isFollowed = false;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  String? _videoError;
  bool _isProcessingFollow = false;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    fetchMovieDetail();
    fetchUserInfo();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> fetchUserInfo() async {
    final session = Provider.of<UserSession>(context, listen: false);

    if (session.userId == null) {
      if (mounted) {
        context.goNamed('login');
      }
      return;
    }

    final url = Uri.parse(
      "http://10.0.2.2:8000/api_handle/vnpay_api_handle/get_user_info.php?id=${session.userId}",
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true && data['user'] != null) {
        setState(() {
          userData = data['user'];
          isLoading = false;
        });
        return;
      }
    }
  }

  Future<void> fetchMovieDetail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 0;

      final response = await ApiService.fetchMovieById(
        widget.id,
        userId: userId,
      );
      if (response['status'] == 'success') {
        final data = response['data'];
        final filmData = data['film'];
        final contents = data['contents'] as List;
        final categoryData = data['categories'] as List?;

        if (filmData != null) {
          final trailerPath = contents.isNotEmpty
              ? contents.first['trailer'] ?? ''
              : '';
          final trailerUrl = trailerPath.isNotEmpty
              ? ApiService.resolveImageUrl(trailerPath)
              : '';
          print('Trailer URL: $trailerUrl');
          setState(() {
            film = filmData;
            episodes = contents;
            categories = categoryData ?? [];
            selectedType = 'movie';
            isFollowed = filmData['is_followed'] ?? false; // <-- cần user_id
          });

          _updateSeasonsAndEpisodes(updateSeason: true);

          if (trailerUrl.isNotEmpty) {
            await _initializeVideo(trailerUrl);
          } else {
            setState(() => _videoError = 'Không tìm thấy URL trailer');
          }
        }
      } else {
        setState(() => _videoError = 'Không thể tải thông tin phim');
      }
    } catch (e) {
      setState(() => _videoError = 'Lỗi khi tải dữ liệu: ${e.toString()}');
    }
    setState(() => isLoading = false);
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

  Future<void> _initializeVideo(String videoUrl) async {
    try {
      final uri = Uri.tryParse(videoUrl);
      print("🎥 Initializing video with URL: $videoUrl");
      if (uri == null || !uri.hasAbsolutePath) {
        setState(() => _videoError = 'Invalid video URL');
        return;
      }

      await _videoController?.dispose();
      _videoController = VideoPlayerController.networkUrl(uri);

      await _videoController!.initialize();

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
          _videoError = null;
        });

        _videoController!
          ..setLooping(true)
          ..setVolume(0.5)
          ..play();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _videoError = 'Error loading video: ${e.toString()}';
          _isVideoInitialized = false;
        });
      }
    }
  }

  Future<void> _handleFollow() async {
    if (_isProcessingFollow) return;

    setState(() => _isProcessingFollow = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 0;

      if (userId <= 0) {
        _showSnackBar(
          'Vui lòng đăng nhập để sử dụng chức năng này',
          Colors.red,
        );
        setState(() => _isProcessingFollow = false); // đảm bảo reset state
        return;
      }

      print('Attempting to follow/unfollow film with ID: ${widget.id}');
      print('Current follow status: $isFollowed');

      final result = await ApiService.toggleFollow(
        filmId: widget.id,
        isCurrentlyFollowed: isFollowed,
      );

      print('API Response: $result');

      if (result['status'] == 'success') {
        setState(() => isFollowed = !isFollowed);

        _showSnackBar(
          result['message'] ??
              (isFollowed ? 'Đã thêm vào danh sách' : 'Đã xóa khỏi danh sách'),
          Colors.green,
        );
      } else {
        print('API Error: ${result['message']}');
        _showSnackBar(
          result['message'] ?? 'Lỗi khi cập nhật danh sách',
          Colors.red,
        );
      }
    } catch (e) {
      print('Exception during follow operation: $e');
      _showSnackBar('Lỗi kết nối: ${e.toString()}', Colors.red);
    } finally {
      setState(() => _isProcessingFollow = false);
    }
  }

  void _showSnackBar(String message, [Color? backgroundColor]) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildVideoPlayer() {
    if (_videoError != null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white54, size: 48),
              const SizedBox(height: 8),
              Text(
                _videoError!,
                style: const TextStyle(color: Colors.white54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_isVideoInitialized && _videoController != null) {
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: VideoPlayer(_videoController!),
        ),
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(child: CircularProgressIndicator()),
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

  Widget _buildActionButton() {
    return Row(
      children: [
        // Nút "Thêm vào danh sách"
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isProcessingFollow ? null : _handleFollow,
            icon: _isProcessingFollow
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    isFollowed ? Icons.check_circle : Icons.add_circle_outline,
                    size: 24,
                    color: Colors.white,
                  ),
            label: Text(
              isFollowed ? 'Đã trong danh sách' : 'Thêm vào danh sách',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isFollowed ? Colors.green : Colors.blue,
              disabledBackgroundColor: Colors.grey[600],
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        // Views
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

        // Total Likes
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          film?['title'] ?? 'Chi tiết phim',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : film == null
          ? const Center(
              child: Text(
                'Không thể tải thông tin phim',
                style: TextStyle(color: Colors.white),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Video Player
                _buildVideoPlayer(),
                const SizedBox(height: 16),

                // Show VIP button if required
                if (film!['is_vip'] == 1 && userData!['vip'] == false) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      context.goNamed('payment');
                    },
                    icon: const Icon(
                      Icons.workspace_premium,
                      color: Colors.black,
                    ),
                    label: const Text(
                      'Bạn cần đăng ký VIP để xem phim',
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Movie Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            ApiService.resolveImageUrl(film!['img'] ?? ''),
                            width: 100,
                            height: 150,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
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

                // Categories
                _buildCategories(),
                const SizedBox(height: 16),

                // Action Button (Follow only)
                _buildActionButton(),
                const SizedBox(height: 24),

                // Type and Season Selection
                _buildDropdowns(),
                const SizedBox(height: 16),

                // Episodes Grid
                if (filteredEpisodes.isNotEmpty) ...[
                  const Text(
                    'Danh sách tập:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    itemCount: filteredEpisodes.length,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 2.0,
                        ),
                    itemBuilder: (context, index) {
                      final ep = filteredEpisodes[index];
                      final movieId = film?['id']?.toString();
                      final episodeId = ep['id']?.toString();
                      final episodeNumber = ep['episode_number'] ?? index + 1;

                      return GestureDetector(
                        onTap: () {
                          if (film!['is_vip'] == 1 &&
                              userData!['vip'] == false) {
                            _showSnackBar(
                              'Bạn cần đăng ký VIP để xem phim',
                              Colors.blue,
                            );
                            return;
                          }
                          if (movieId != null && episodeId != null) {
                            context.push('/movie/$movieId/episode/$episodeId');
                          }
                        },
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[600]!),
                          ),
                          child: Text(
                            'Tập $episodeNumber',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ] else ...[
                  const Center(
                    child: Text(
                      'Không có tập nào',
                      style: TextStyle(color: Colors.white60),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
    );
  }
}
