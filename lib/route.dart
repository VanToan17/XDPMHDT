/*import 'package:flutter/material.dart'; 
import 'package:go_router/go_router.dart'; 
import 'routes/common.dart';
import 'routes/movie.dart';
import 'routes/user.dart';

List<dynamic> newList= [
  ...common_routes, 
  ...user_routes, 
];
class RouteItem{
  var name; 
  var path;
  var builder;
  String description; 
  bool requiredAuth;
RouteItem({
  this.name,
  this.path,
  this.builder,
  this.requiredAuth = false,
  this.description = '',
});


}

class route{
  static GoRouter getGoRouter(){
    List<RouteBase> initRoutes =[]; 
    for (var a in newList ) {
      initRoutes.add(GoRoute(
        name: a.name, 
        path: a.path, 
        builder: a.builder, 
      ));
      
    }
    var routes = GoRouter(
    routes: initRoutes, 
  ); 
  return routes; 
  }
  static dynamic getRoute(name){
    RouteItem route = RouteItem(name: '');
    for (var a in newList) {
      if(a.name == name){
        route = a; 

      }
    }
    return route; 

  }
  static getcurrentRoute(context){
    return ModalRoute.of(context)?.settings.name; 
  }
  static getParentRoute(name){
    RouteItem route = RouteItem(name: ''); 
    for(var a in newList) {
      if(name.contains('${a.name}.')){
        route = a; 

      }
    }
    return route; 

  }
  static getParentRoutes(name) {
    List<RouteItem> routes = []; 
    for (var a in newList) {
      if(name.contains ('${a.name}.')){
        routes.add(a); 

      }
    }
    return routes; 
  }
  
}*/


import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'routes/common.dart';
import 'routes/movie.dart';
import 'routes/user.dart';
import 'routes/starter.dart';

List<dynamic> newList = [
  ...common_routes,
  ...user_routes,
  ...starter_routes,
  ...movie_routes,
];

class RouteItem {
  var name;
  var path;
  var builder;
  String description;
  bool requiredAuth;
  RouteItem({
    this.name,
    this.path,
    this.builder,
    this.requiredAuth = false,
    this.description = '',
  });
}

class route {
  static GoRouter getGoRouter() {
    List<RouteBase> initRoutes = [];
    for (var a in newList) {
      print('📌 Route registered: ${a.path}'); // 👈 THÊM DÒNG NÀY
      initRoutes.add(GoRoute(name: a.name, path: a.path, builder: a.builder));
    }
    var routes = GoRouter(routes: initRoutes);
    return routes;
  }

  static dynamic getRoute(name) {
    RouteItem route = RouteItem(name: '');
    for (var a in newList) {
      if (a.name == name) {
        route = a;
      }
    }
    return route;
  }

  static getcurrentRoute(context) {
    return ModalRoute.of(context)?.settings.name;
  }

  static getParentRoute(name) {
    RouteItem route = RouteItem(name: '');
    for (var a in newList) {
      if (name.contains('${a.name}.')) {
        route = a;
      }
    }
    return route;
  }

  static getParentRoutes(name) {
    List<RouteItem> routes = [];
    for (var a in newList) {
      if (name.contains('${a.name}.')) {
        routes.add(a);
      }
    }
    return routes;
  }
}
