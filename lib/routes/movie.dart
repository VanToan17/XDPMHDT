
import 'package:flutter/material.dart';
import 'package:project_group_9/screens/movie_detail.dart';
import 'package:project_group_9/screens/movie_player_screen.dart';
import '../route.dart'; // nếu cần

var movie_routes = [
  RouteItem(
    name: 'movie_detail',
    path: '/movie/:id',
    builder: (context, state) {
      final id = int.tryParse(state.pathParameters['id'] ?? '');
      if (id == null) {
        return const Scaffold(body: Center(child: Text('ID không hợp lệ')));
      }
      return MovieDetails(id: id);
    },
    description: 'Trang chi tiết phim',
  ),
  RouteItem(
    name: 'movie_player',
    path: '/movie/:movieId/episode/:episodeId',
    builder: (context, state) {
      final movieId = state.pathParameters['movieId'];
      final episodeId = state.pathParameters['episodeId'];

      if (movieId == null || episodeId == null) {
        return const Scaffold(
          body: Center(
            child: Text(
              'Thông tin phim không hợp lệ',
              style: TextStyle(color: Colors.white),
            ),
          ),
          backgroundColor: Colors.black,
        );
      }

      return MoviePlayerScreen(movieId: movieId, episodeId: episodeId);
    },
    description: 'Trang phát phim theo tập',
  ),
];

