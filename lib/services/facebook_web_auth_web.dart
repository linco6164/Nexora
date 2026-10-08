import 'dart:js_interop';

@JS('nexoraFacebookLogin')
external JSPromise<JSString> _nexoraFacebookLogin();

Future<String> requestFacebookAccessToken() async {
  try {
    final token = (await _nexoraFacebookLogin().toDart).toDart.trim();

    if (token.isEmpty) {
      throw const FormatException(
        'Facebook nu a furnizat tokenul de autentificare.',
      );
    }

    return token;
  } catch (error) {
    final message = error.toString().replaceFirst('Error: ', '').trim();
    throw StateError(
      message.isEmpty
          ? 'Autentificarea cu Facebook nu a putut fi finalizată.'
          : message,
    );
  }
}
