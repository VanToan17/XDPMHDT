import '/app.dart';
import '../screens/home.dart';
import '../screens/search_film.dart';
import '../screens/profile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/profile/profile_bloc.dart';
import '../blocs/profile/profile_event.dart';

var common_routes = [
  // RouteItem(
  //   name: "mysitethems",
  //   path: '/mysitethemse',
  //   builder: (context, state) => MyDocThemeScreen(),
  // ),
  RouteItem(
    name: "home",
    path: '/',
    builder: (content, state) => Scaffold(body: Home()),
  ),

  RouteItem(
    name: "search",
    path: '/search',
    builder: (content, state) => Scaffold(body: SearchScreen()),
  ),
  RouteItem(
    name: "profile",
    path: '/profile',
    builder: (context, state) => BlocProvider(
      create: (context) => ProfileBloc(context)..add(LoadProfile()),
      child: const ProfileScreen(),
    ),
  ),
];
