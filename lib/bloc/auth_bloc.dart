import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:package_info/package_info.dart';
import 'package:talktostranger/event/auth_event.dart';
import 'package:talktostranger/state/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  AuthBloc() : super(AuthInitialState()) {
    on<SignInWithGoogleEvent>((event, emit) async {
      emit(AuthLoadingState());
      try {
        final GoogleSignInAccount? googleSignInAccount =
            await googleSignIn.signIn();

        if (googleSignInAccount == null) {
          // User canceled the sign-in process
          emit(AuthErrorState('Sign-in canceled.'));
          return;
        }

        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );

        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);
        final User user = userCredential.user!;

        emit(AuthSignedInState(user));
      } catch (error) {
        emit(AuthErrorState('Sign-in failed: $error'));
      }
    });

    on<CheckAuthenticationStatusEvent>((event, emit) async {
      emit(AuthLoadingState());
      try {
        final User? user = _auth.currentUser;
        final remoteConfig = FirebaseRemoteConfig.instance;
        await remoteConfig.setConfigSettings(RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(seconds: 1),
        ));
        await remoteConfig.fetch();
        await remoteConfig.activate();
        int version = await remoteConfig.getInt('versionCode');
        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        int versionCode = int.parse(packageInfo.buildNumber);
        print('Version code: $version');

        if (user != null) {
          if (versionCode == version) {
            emit(AuthSignedInState(user));
          } else {
            emit(NotUpdatedState());
          }
        } else {
          emit(AuthNotAuthenticatedState());
        }
      } catch (error) {
        emit(AuthErrorState('Error checking authentication status: $error'));
      }
    });

    on<SignOutEvent>((event, emit) async {
      try {
        await _auth.signOut();
        emit(AuthNotAuthenticatedState());
      } catch (error) {
        emit(AuthErrorState('Sign-out failed: $error'));
      }
    });
  }
}
