import 'package:firebase_auth/firebase_auth.dart';

final VehicleBloc vehicleBloc = VehicleBloc();

//✅  🎾 🔵  📍   ℹ️
class VehicleBloc {
  VehicleBloc() {
    print('+++ initializing Vehicle Bloc');
  }
  FirebaseAuth auth = FirebaseAuth.instance;
  void signInAnonymously() async {
    print('📍 checking current user ..... 📍 ');
    var user = await auth.currentUser();

    if (user == null) {
      print('ℹ️ signing in ..... .......');
      user = await auth.signInAnonymously();
    } else {
      print('User already signed in: 🔵 🔵 🔵 ');
    }
  }

  void publishMessage() {
    print('+++ publishMessage ');
  }

  void subscribeToMessage() {
    print('+++ subscribeToMessage ...');
  }
}
