import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:project_group_9/blocs/profile/profile_event.dart';
import 'package:project_group_9/blocs/profile/profile_state.dart';
import 'package:project_group_9/widgets/user_session.dart';
import 'package:flutter/material.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final BuildContext context;
  Timer? _vipTimer;

  ProfileBloc(this.context) : super(ProfileLoading()) {
    on<LoadProfile>(_onLoadProfile);
    on<LogoutProfile>(_onLogoutProfile);
  }

  Future<void> _onLoadProfile(LoadProfile event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    final session = UserSession.of(context);

    if (session.userId == null) {
      emit(ProfileError('Bạn chưa đăng nhập.'));
      return;
    }

    try {
      final url = Uri.parse("http://10.0.2.2:8000/api_handle/vnpay_api_handle/get_user_info.php?id=${session.userId}");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['user'] != null) {
          final userData = data['user'];
          // ✅ Không cần _startVipCountdown
          emit(ProfileLoaded(userData, ''));
          return;
        }
      }
      emit(ProfileError('Không thể tải thông tin người dùng.'));
    } catch (e) {
      emit(ProfileError('Lỗi: ${e.toString()}'));
    }
  }


  

  Future<void> _onLogoutProfile(LogoutProfile event, Emitter<ProfileState> emit) async {
    await UserSession.of(context).logout();
    emit(ProfileLoggedOut());
  }

  @override
  Future<void> close() {
    _vipTimer?.cancel();
    return super.close();
  }
}
