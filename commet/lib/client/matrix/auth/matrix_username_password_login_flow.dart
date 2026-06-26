import 'package:commet/client/auth.dart';
import 'package:commet/client/client.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/main.dart';
import 'package:intl/intl.dart';

import 'package:matrix/matrix.dart' as matrix;

bool _isAlreadyLoggedIn(String? userId) {
  if (userId == null) return false;
  return clientManager?.clients.any(
          (c) => c is MatrixClient && c.getMatrixClient().userID == userId) ??
      false;
}

String get messageUserDeactivated => Intl.message(
    "Your account has been deactivated",
    name: "messageUserDeactivated",
    desc:
        "An error message displayed when the user attempts to log into an account that has been disabled");

class MatrixPasswordLoginFlow implements PasswordLoginFlow {
  @override
  String? password;

  @override
  String? username;

  @override
  Future<LoginResult> submit(Client client) async {
    if (username == null) {
      return LoginResultError("Enter a username");
    }

    if (password == null) {
      return LoginResultError("Enter a password");
    }

    if (client is! MatrixClient) {
      return LoginResultFailed();
    }

    var mx = client.getMatrixClient();
    LoginResult result = LoginResultError("An unknown error occurred");

    try {
      var response = await mx.login(matrix.LoginType.mLoginPassword,
          initialDeviceDisplayName: BuildConfig.appName,
          password: password,
          identifier: matrix.AuthenticationUserIdentifier(user: username!));

      if (response.accessToken.isNotEmpty) {
        if (_isAlreadyLoggedIn(mx.userID)) {
          // This account is already logged in on this device. Discard the
          // session we just created and report it, rather than adding a
          // duplicate client.
          try {
            await mx.logout();
          } catch (_) {}
          result = LoginResultAlreadyLoggedIn();
        } else {
          result = LoginResultSuccess();
        }
      } else {
        result = LoginResultFailed();
      }
    } on matrix.MatrixException catch (exception) {
      if (exception.errcode == "M_USER_DEACTIVATED") {
        result = LoginResultError(messageUserDeactivated);
      } else {
        result = LoginResultError(exception.errorMessage);
      }
    } catch (e) {
      result = LoginResultError(e.toString());
    }

    return result;
  }
}
