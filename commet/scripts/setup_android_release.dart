import 'dart:convert';
import 'dart:io';

String? getArg(List<String> args, String name) {
  int index = args.indexOf(name);
  // Not present, or present with no value after it (e.g. a CI secret expanded to
  // an empty string, so the flag ended up last). Return null instead of
  // indexing out of bounds.
  if (index == -1 || index + 1 >= args.length) return null;

  return args[index + 1];
}

void writeEncodedKeyfile(String file) {
  var keyFile = File(file).readAsBytesSync();
  var b64 = base64.encode(keyFile);
  File("$file.b64").writeAsString(b64);
}

void decodeAndWriteKeyFile(String keyB64) {
  var bytes = base64Decode(keyB64);
  var file = File("android/key.jks");
  if (!file.existsSync()) {
    file.createSync(recursive: true);
  }

  file.writeAsBytesSync(bytes);
}

void writeKeyProperties(String password) {
  var file = File("android/key.properties");
  if (!file.existsSync()) {
    file.createSync(recursive: true);
  }

  file.writeAsStringSync("""
storePassword=$password
keyPassword=$password
keyAlias=key
storeFile=../key.jks
""");
}

void main(List<String> args) {
  //Utility to encode a keyfile to base64, not needed for setup
  String? keyFile = getArg(args, "--key_file");

  if (keyFile != null) {
    writeEncodedKeyfile(keyFile);
    return;
  }

  String? keyData = getArg(args, "--key_b64");
  String? keyPassword = getArg(args, "--key_password");

  // No release keystore configured (e.g. a fork without ANDROID_KEY_STORE_B64 /
  // ANDROID_KEY_PASSWORD secrets). Skip writing key.properties so the build
  // falls back to debug signing (see android/app/build.gradle) and still
  // produces an installable, sideload-only APK. A leading "--" means the secret
  // expanded to empty and getArg picked up the next flag.
  if (keyData == null || keyData.isEmpty || keyData.startsWith("--")) {
    stdout.writeln(
        "No Android release keystore provided; skipping release signing "
        "(the APK will be debug-signed).");
    return;
  }

  decodeAndWriteKeyFile(keyData);
  writeKeyProperties(keyPassword ?? "");
}
