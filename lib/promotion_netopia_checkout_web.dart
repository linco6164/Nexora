import 'dart:js_interop';

@JS('document')
external JSObject get document;

@JS('document.createElement')
external JSObject createElement(String tagName);

@JS('document.body')
external JSObject get documentBody;

@JS('HTMLFormElement.prototype.appendChild')
external JSObject appendChild(
  JSObject element,
  JSObject child,
);

@JS('HTMLFormElement.prototype.submit')
external void submitForm(JSObject form);

@JS('HTMLElement.prototype.setAttribute')
external void setAttribute(
  JSObject element,
  String name,
  String value,
);

@JS('HTMLElement.prototype.remove')
external void removeElement(JSObject element);

class PromotionNetopiaCheckout {
  static Future<void> open({
    required String gatewayUrl,
    required String envKey,
    required String data,
    required String cipher,
    required String iv,
  }) async {
    final form = createElement('form');

    setAttribute(form, 'method', 'POST');
    setAttribute(form, 'action', gatewayUrl);
    setAttribute(form, 'target', '_self');
    setAttribute(form, 'style', 'display:none');

    _addHiddenInput(form, 'env_key', envKey);
    _addHiddenInput(form, 'data', data);
    _addHiddenInput(form, 'cipher', cipher);
    _addHiddenInput(form, 'iv', iv);

    appendChild(documentBody, form);

    submitForm(form);

    removeElement(form);
  }

  static void _addHiddenInput(
    JSObject form,
    String name,
    String value,
  ) {
    final input = createElement('input');

    setAttribute(input, 'type', 'hidden');
    setAttribute(input, 'name', name);
    setAttribute(input, 'value', value);

    appendChild(form, input);
  }
}