abstract class ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final Map<String, dynamic> userData;
  final String vipRemainingTime;

  ProfileLoaded(this.userData, this.vipRemainingTime);
}

class ProfileError extends ProfileState {
  final String message;

  ProfileError(this.message);
}
class ProfileLoggedOut extends ProfileState {}
