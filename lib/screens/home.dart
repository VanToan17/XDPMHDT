import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:project_group_9/widgets/user_session.dart';
import '../api_service.dart';
import 'package:project_group_9/frame_Screen.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List movies = [];
  List followedMovies = [];
  List<Map<String, dynamic>> categoriesWithFilms = [];
  bool isLoading = true;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    loadMovies();
    loadFollowedMovies();
    loadCategoriesWithFilms();
  }

  void _checkLoginAndNavigate(String route) {
    final session = Provider.of<UserSession>(context, listen: false);
    if (!session.isLoggedIn) {
      context.go('/login');
    } else {
      context.push(route);
    }
  }

  Future<void> loadMovies() async {
    try {
      final data = await ApiService.fetchMovies();
      if (!mounted) return;
      setState(() {
        movies = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      print('Error loading movies: $e');
    }
  }

  Future<void> loadFollowedMovies() async {
    try {
      final session = Provider.of<UserSession>(context, listen: false);
      if (session.isLoggedIn) {
        final data = await ApiService.fetchFollowedFilms();
        setState(() {
          followedMovies = data;
        });
      }
    } catch (e) {
      print('Error loading followed movies: $e');
    }
  }

  Future<void> loadCategoriesWithFilms() async {
    try {
      final data = await ApiService.fetchCategoriesWithGroupedFilms();
      setState(() {
        categoriesWithFilms = data;
      });
    } catch (e) {
      print('Error loading categories with films: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FrameScreen(
      showAppBar: false,
      title: 'Trang chủ',
      showDefaultBottomBar: true,
      backgroundColor: Colors.black,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Banner Carousel ─────────────────────────────────────────────
                  if (movies.isNotEmpty)
                    Stack(
                      children: [
                        SizedBox(
                          height: 440,
                          width: double.infinity,
                          child: Image.network(
                            ApiService.resolveImageUrl(
                              movies[currentIndex]['img'],
                            ),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: Colors.grey[800],
                                  child: const Icon(
                                    Icons.movie,
                                    color: Colors.white,
                                    size: 50,
                                  ),
                                ),
                          ),
                        ),
                        Container(
                          height: 440,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.85),
                                Colors.black.withOpacity(0.4),
                                Colors.black.withOpacity(0.85),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 40,
                          left: 0,
                          right: 0,
                          child: SizedBox(
                            height: 400,
                            child: CarouselSlider.builder(
                              itemCount: movies.length,
                              itemBuilder: (context, index, realIndex) {
                                final movie = movies[index];
                                return GestureDetector(
                                  onTap: () => _checkLoginAndNavigate(
                                    '/movie/${movie['id']}',
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Expanded(
                                        flex: 5,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          child: Image.network(
                                            ApiService.resolveImageUrl(
                                              movie['img'],
                                            ),
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                                      color: Colors.grey[800],
                                                      child: const Icon(
                                                        Icons.movie,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          movie['title'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              options: CarouselOptions(
                                height: 400,
                                autoPlay: true,
                                enlargeCenterPage: true,
                                viewportFraction: 0.65,
                                onPageChanged: (index, reason) =>
                                    setState(() => currentIndex = index),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),

                  // ─── Danh Sách Của Tôi ──────────────────────────────────────────
                  Consumer<UserSession>(
                    builder: (context, session, child) {
                      if (session.isLoggedIn && followedMovies.isNotEmpty) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Danh sách của tôi',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 180,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: followedMovies.length,
                                itemBuilder: (context, index) {
                                  final movie = followedMovies[index];
                                  return GestureDetector(
                                    onTap: () => _checkLoginAndNavigate(
                                      '/movie/${movie['id']}',
                                    ),
                                    child: Container(
                                      width: 120,
                                      margin: const EdgeInsets.only(left: 12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                ApiService.resolveImageUrl(
                                                  movie['img'],
                                                ),
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => Container(
                                                      color: Colors.grey[800],
                                                      child: const Icon(
                                                        Icons.movie,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            movie['title'] ?? '',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  const SizedBox(height: 20),

                  // ─── Phim Hot ───────────────────────────────────────────────────
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Phim hot',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.6,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: movies.length,
                      itemBuilder: (context, index) {
                        final movie = movies[index];
                        return GestureDetector(
                          onTap: () =>
                              _checkLoginAndNavigate('/movie/${movie['id']}'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    ApiService.resolveImageUrl(movie['img']),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              color: Colors.grey[800],
                                              child: const Icon(
                                                Icons.movie,
                                                color: Colors.white,
                                              ),
                                            ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                movie['title'] ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  // ─── Danh Mục Theo Thể Loại ─────────────────────────────────────
                  ...categoriesWithFilms.map((category) {
                    final films = category['films'] as List;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            category['category_name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 180,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: films.length,
                            itemBuilder: (context, index) {
                              final film = films[index];
                              return GestureDetector(
                                onTap: () => _checkLoginAndNavigate(
                                  '/movie/${film['film_id']}',
                                ),
                                child: Container(
                                  width: 120,
                                  margin: const EdgeInsets.only(left: 12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            ApiService.resolveImageUrl(
                                              film['img'],
                                            ),
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                                      color: Colors.grey[800],
                                                      child: const Icon(
                                                        Icons.movie,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        film['title'] ?? '',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }).toList(),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}
