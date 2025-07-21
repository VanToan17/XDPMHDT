import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '/models/film_model.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000/api_handle';

  // Định nghĩa getUserId một lần
  static Future<int> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id') ?? 0;
  }

  static String resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    return 'http://10.0.2.2:8000/storage/$path';
  }

  static Future<List<dynamic>> fetchMovies() async {
    try {
      final url = Uri.parse('$baseUrl/movie.php');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final data = jsonData['data'];

        if (jsonData['status'] == 'success' && data is List) {
          return data;
        }
      }
    } catch (e) {
      print('🔥 Lỗi fetchMovies: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> fetchMovieById(
    int id, {
    int userId = 0,
  }) async {
    final url = Uri.parse('$baseUrl/movie_detail.php?id=$id&user_id=$userId');
    final response = await http.get(url);
    return json.decode(response.body);
  }

  static String resolveVideoUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    return 'http://10.0.2.2:8000/storage/$path';
  }

  static Future<List<Map<String, dynamic>>>
  fetchCategoriesWithGroupedFilms() async {
    final url = Uri.parse(
      '$baseUrl/movie.php?action=get_all_films_with_categories',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);

        if (jsonBody['status'] == 'success') {
          final List<dynamic> films = jsonBody['data'];

          final Map<int, Map<String, dynamic>> categoryMap = {};

          for (var film in films) {
            final categories = film['categories'] ?? [];
            for (var category in categories) {
              final int categoryId = category['id'];
              final String categoryName = category['category_name'];

              if (!categoryMap.containsKey(categoryId)) {
                categoryMap[categoryId] = {
                  'category_id': categoryId,
                  'category_name': categoryName,
                  'films': [],
                };
              }

              categoryMap[categoryId]!['films'].add({
                'film_id': film['id'],
                'title': film['title'],
                'img': film['img'],
              });
            }
          }

          return categoryMap.values.toList();
        } else {
          throw Exception('API trả về lỗi');
        }
      } else {
        throw Exception('Lỗi mạng: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi fetchCategoriesWithGroupedFilms: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getPlayableItemById({
    required int filmId,
    required int contentId,
  }) async {
    final response = await fetchMovieById(filmId);

    if (response['status'] == 'success') {
      final contents = response['data']['contents'] as List;
      final found = contents.firstWhere(
        (item) =>
            item['id'].toString() == contentId.toString() &&
            item['film_id'].toString() == filmId.toString(),
        orElse: () => null,
      );

      if (found != null && found['source'] != null) {
        return found;
      }
    }

    return null;
  }

  static Future<Map<String, dynamic>> logView({
    required int filmId,
    int? contentId,
    int? userId, // Thêm tham số userId để linh hoạt hơn
  }) async {
    final effectiveUserId =
        userId ?? await getUserId(); // Sử dụng userId từ tham số hoặc getUserId
    print(
      '👉 Logging view - userId: $effectiveUserId, filmId: $filmId, contentId: $contentId',
    );
    if (effectiveUserId <= 0) {
      return {
        'status': 'error',
        'message': 'User ID không hợp lệ',
        'logged': false,
      };
    }

    final url = Uri.parse('$baseUrl/movie_detail.php?action=log_view');
    final body = {
      'user_id': effectiveUserId,
      'film_id': filmId,
      if (contentId != null) 'content_id': contentId,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print(
        '📥 Response from logView: ${response.body} (Status: ${response.statusCode})',
      );

      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        return {
          'status': resData['status'] ?? 'error',
          'logged': resData['logged'] ?? false,
          'message': resData['message'] ?? 'Không có thông tin',
        };
      } else {
        return {
          'status': 'error',
          'message': 'HTTP Error: ${response.statusCode}',
          'logged': false,
        };
      }
    } catch (e) {
      print('❌ Network error in logView: $e');
      return {
        'status': 'error',
        'message': 'Network error: $e',
        'logged': false,
      };
    }
  }

  static Future<Map<String, dynamic>> toggleLikeFilmOrEpisode({
    required int filmId,
    int? contentId,
    required bool isCurrentlyLiked,
  }) async {
    final userId = await getUserId();
    if (userId <= 0) {
      return {'status': 'error', 'message': 'User ID không hợp lệ'};
    }

    final url = Uri.parse('$baseUrl/movie_detail.php?action=toggle_like');
    final body = {
      'user_id': userId,
      'film_id': filmId,
      if (contentId != null) 'content_id': contentId,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final resData = json.decode(response.body);

        if (resData.containsKey('like')) {
          resData['like'] = int.tryParse(resData['like'].toString()) ?? 0;
        }

        return resData;
      } else {
        return {
          'status': 'error',
          'message': 'HTTP Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> toggleFollow({
    required int filmId,
    required bool isCurrentlyFollowed,
  }) async {
    final userId = await getUserId();
    if (userId <= 0) {
      return {'status': 'error', 'message': 'User ID không hợp lệ'};
    }

    final url = Uri.parse('$baseUrl/movie_detail.php?action=toggle_follow');
    final body = {'user_id': userId, 'film_id': filmId};

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'status': 'error',
          'message': 'HTTP Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

  static Future<List<dynamic>> fetchFollowedFilms() async {
    final userId = await getUserId();
    final allMovies = await fetchMovies();
    List<dynamic> followed = [];

    for (final movie in allMovies) {
      final detail = await fetchMovieByIdWithUser(movie['id'], userId: userId);

      if (detail['status'] == 'success') {
        final filmData = detail['data']['film'];
        if (filmData['is_followed'] == true || filmData['is_followed'] == 1) {
          followed.add(filmData);
        }
      }
    }
    return followed;
  }

  static Future<Map<String, dynamic>> fetchMovieByIdWithUser(
    int id, {
    int userId = 1,
  }) async {
    final url = Uri.parse('$baseUrl/movie_detail.php?id=$id&user_id=$userId');

    try {
      final response = await http.get(url);
      return json.decode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Failed to fetch movie: $e'};
    }
  }

  static Future<Map<String, dynamic>> registerUser({
    required String fullname,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/register.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullname': fullname,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
      }),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> resendOtp(String email) async {
    final res = await http.post(
      Uri.parse('$baseUrl/resend_otp.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> verifyOtp(
    String email,
    String otp,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/verify_otp.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối'};
    }
  }

  static Future<Map<String, dynamic>> sendForgotPasswordOtp(
    String email,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/forgot_password.php'),
      body: jsonEncode({'email': email}),
      headers: {'Content-Type': 'application/json'},
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> resendForgotOtp(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/resend_forgot_password_otp.php'),
      body: jsonEncode({'email': email}),
      headers: {'Content-Type': 'application/json'},
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> verifyForgotOtp(
    String email,
    String otp,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify_forgot_otp.php'),
      body: jsonEncode({'email': email, 'otp': otp}),
      headers: {'Content-Type': 'application/json'},
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateNewPassword({
    required String email,
    required String password,
    required String confirm,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/update_password.php'),
      body: jsonEncode({
        'email': email,
        'password': password,
        'confirm': confirm,
      }),
      headers: {'Content-Type': 'application/json'},
    );
    return jsonDecode(response.body);
  }

  static Future<List<Film>> searchFilms(String keyword) async {
    final response = await http.get(
      Uri.parse('$baseUrl/search_film.php?query=$keyword'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        return (data['films'] as List)
            .map((json) => Film.fromJson(json))
            .toList();
      }
    }

    return [];
  }
}
