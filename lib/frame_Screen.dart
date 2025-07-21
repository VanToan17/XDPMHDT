import 'package:flutter/material.dart';
import 'package:project_group_9/app.dart';
import 'package:project_group_9/lang.dart';
import 'package:project_group_9/components/common/header.dart';
import 'package:project_group_9/components/common/Sidebar.dart';
import 'package:project_group_9/components/common/BottomBar.dart';
import 'package:provider/provider.dart';
import 'package:project_group_9/widgets/user_session.dart';
import 'package:go_router/go_router.dart';

class FrameScreen extends StatefulWidget {
  var body;
  var title;
  var showAppBar;
  var backgroundColor;
  var bottomNavigationBar;
  var showDefaultBottomBar;
  FrameScreen({
    super.key,
    required this.body,
    this.backgroundColor,
    this.title = '',
    this.showAppBar = true,
    this.showDefaultBottomBar = false,
    this.bottomNavigationBar,
  });

  @override
  State<FrameScreen> createState() => _FrameScreenState();
}

class _FrameScreenState extends State<FrameScreen> {
  bool isLoading = false;

  setLoading(bool bool) {
    setState(() {
      isLoading = bool;
    });
  }

  int _getCurrentIndex(BuildContext context) {
    final uri = GoRouter.of(context).routeInformationProvider.value.uri;
    final location = uri.toString();

    if (location == '/') return 0;
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    Lang.setContext(context);
    final session = Provider.of<UserSession>(context);

    return SafeArea(
      maintainBottomViewPadding: true,
      child: Scaffold(
        appBar: widget.showAppBar
            ? AppBar(
                backgroundColor: Colors.black,
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: GestureDetector(
                    onTap: () {
                      context.push('/');
                    },
                    child: Image.asset(
                      'assets/images/logo.jpg',
                      width: 48, // tăng kích thước ngang
                      height: 48, // tăng kích thước dọc
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                title: Text(
                  widget.title,
                  style: const TextStyle(color: Colors.white),
                ),
                actions: [
                  if (session.isLoggedIn)
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            session.fullName != null &&
                                    session.fullName!.isNotEmpty
                                ? 'Hi, ${session.fullName}'
                                : 'Hi',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (session.isVip)
                            const Text(
                              "💎 VIP",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.yellowAccent,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              )
            : null,

        resizeToAvoidBottomInset: true,
        backgroundColor: widget.backgroundColor ?? Colors.white,
        extendBody: true,
        body: Stack(
          children: [
            widget.body,
            Components.renderBgLoading(context, isLoading, setLoading),
          ],
        ),

        bottomNavigationBar:
            widget.bottomNavigationBar ??
            (widget.showDefaultBottomBar
                ? BottomBar(currentIndex: _getCurrentIndex(context))
                : null),
      ),
    );
  }
}
