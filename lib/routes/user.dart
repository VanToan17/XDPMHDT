import '/app.dart';
import 'package:project_group_9/screens/register_screen.dart';
import 'package:project_group_9/screens/forgot_password_screen.dart';
import 'package:project_group_9/screens/login_screen.dart'; 
import 'package:project_group_9/screens/vnpay_screen.dart';
import 'package:project_group_9/screens/payment_success_screen.dart';


final user_routes =[
//  RouteItem(
//   name: "login", 
//   path: '/login',
//   builder: (Content, state)=> LoginScreen(), 
//   ),
 RouteItem(
  name: "register", 
  path: '/register', 
  builder:(content, state) => const RegisterScreen(),
  ),
 RouteItem(
  name: "forgot", 
  path: '/forgot',
  builder: (content, state) => const ForgotPasswordScreen(), 
  ),
 RouteItem(
  name: "login", 
  path: '/login',
  builder: (content,state) => const LoginScreen (),
  ),

  RouteItem(
  name: "payment", 
  path: '/payment',
  builder: (content,state) => const  PaymentPage(),
  ),

  RouteItem(
  name: "success", 
  path: '/success',
  builder: (content,state) => const  PaymentSuccessScreen(),
  ),
  

];

