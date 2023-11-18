abstract class AuthEvent {}

class SignInWithGoogleEvent extends AuthEvent {}

class CheckAuthenticationStatusEvent extends AuthEvent {}

class SignOutEvent extends AuthEvent {}