import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:project_group_9/frame_Screen.dart';
import 'package:project_group_9/blocs/profile/profile_bloc.dart';
import 'package:project_group_9/blocs/profile/profile_event.dart';
import 'package:project_group_9/blocs/profile/profile_state.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Timer? _countdownTimer;
  String vipRemainingTime = '';
  bool _isCountdownStarted = false;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _countdownTimer?.cancel();
      context.read<ProfileBloc>().add(LogoutProfile());
    }
  }

  void _startVipCountdown(String vipEndAt) {
    _countdownTimer?.cancel();

    DateTime vipEnd;
    try {
      vipEnd = DateTime.parse(vipEndAt).toLocal();

      if (kDebugMode) {
        print('vipEndAt raw: $vipEndAt');
        print('vipEnd (local check): $vipEnd');
        print('now: ${DateTime.now()}');
      }
    } catch (_) {
      setState(() => vipRemainingTime = 'Ngày hết hạn không hợp lệ.');
      return;
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();

      if (kDebugMode) {
        print('now (local): $now');
      }

      final diff = vipEnd.difference(now);

      if (diff.isNegative) {
        setState(() => vipRemainingTime = 'Đã hết hạn');
        _countdownTimer?.cancel();
        return;
      }

      final days = diff.inDays;
      final hours = diff.inHours % 24;
      final minutes = diff.inMinutes % 60;
      final seconds = diff.inSeconds % 60;

      final formatted = days > 0
          ? '$days ngày ${hours}h ${minutes}p ${seconds}s còn lại'
          : hours > 0
          ? '$hours giờ ${minutes}p ${seconds}s còn lại'
          : minutes > 0
          ? '$minutes phút ${seconds}s còn lại'
          : '$seconds giây còn lại';

      setState(() => vipRemainingTime = formatted);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileLoggedOut) {
          _countdownTimer?.cancel();
          context.goNamed('login');
        }
      },
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          Widget body;

          if (state is ProfileLoading) {
            body = const Center(child: CircularProgressIndicator());
          } else if (state is ProfileError) {
            body = Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.white),
              ),
            );
          } else if (state is ProfileLoaded) {
            final userData = state.userData;
            final vipEndAt = userData['vip_end_at'];

            bool isVip =
                userData['vip'] == true ||
                userData['vip'] == 1 ||
                userData['vip'] == '1';

            if (isVip && vipEndAt != null && !_isCountdownStarted) {
              _isCountdownStarted = true;
              _startVipCountdown(vipEndAt);
            }

            body = Container(
              color: Colors.black,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundImage: AssetImage('assets/images/ava.png'),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userData['fullname'] ?? 'Chưa đăng nhập',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Email: ${userData['email'] ?? '-'}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isVip
                            ? Colors.green.shade700
                            : Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: isVip ? Colors.yellow : Colors.white54,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isVip ? 'Tài khoản VIP' : 'Tài khoản thường',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                if (isVip)
                                  Text(
                                    'Hết hạn: ${vipEndAt ?? ''}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                if (isVip)
                                  Text(
                                    vipRemainingTime,
                                    style: const TextStyle(
                                      color: Colors.yellowAccent,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (!isVip)
                            TextButton(
                              onPressed: () => context.goNamed('payment'),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                              child: const Text(
                                'Đăng ký VIP',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // ListTile(
                    //   leading: const Icon(Icons.history, color: Colors.white),
                    //   title: const Text(
                    //     'Lịch sử thanh toán',
                    //     style: TextStyle(color: Colors.white),
                    //   ),
                    //   trailing: const Icon(
                    //     Icons.arrow_forward_ios,
                    //     size: 16,
                    //     color: Colors.white,
                    //   ),
                    //   onTap: () => context.goNamed('history'),
                    // ),
                    ListTile(
                      leading: const Icon(Icons.lock, color: Colors.white),
                      title: const Text(
                        'Đổi mật khẩu',
                        style: TextStyle(color: Colors.white),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.white,
                      ),
                      onTap: () => context.goNamed('change-password'),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.logout,
                        color: Colors.redAccent,
                      ),
                      title: const Text(
                        'Đăng xuất',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                      onTap: () => _confirmLogout(context),
                    ),
                  ],
                ),
              ),
            );
          } else {
            body = const Center(
              child: Text(
                "Không có dữ liệu",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return FrameScreen(
            title: "Thông tin người dùng",
            backgroundColor: Colors.black,
            showAppBar: true,
            showDefaultBottomBar: true,
            body: body,
          );
        },
      ),
    );
  }
}
