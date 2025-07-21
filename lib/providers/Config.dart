import 'package:project_group_9/app.dart';

class Config with ChangeNotifier{
  late String hotline =''; 
  late String telephone = ''; 
  Future<void> setDAte(data) async {
    if (data.containskey('hotline')) hotline = data('hotline');
    if (data.containskey('telephone')) telephone =data['telephone'];
    notifyListeners();
  }
  getData(){
    return {
      'hotline': hotline, 
      'telephone': telephone,
    };
  }
}
