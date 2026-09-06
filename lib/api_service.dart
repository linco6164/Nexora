import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'models/listing.dart';
import 'models/chat_models.dart';

import 'models/notification_model.dart';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'https://api.nx-store.com';
  static const _storage = FlutterSecureStorage();

  // ---- Token management ----

  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // ---- Auth endpoints ----

  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw ApiException(data['message'] ?? 'Eroare la înregistrare');
    }

    return data;
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw ApiException(data['message'] ?? 'Autentificare eșuată');
    }

    // Dacă are 2FA activat, backend-ul întoarce requiresTwoFactor: true
    // fără token — nu salvăm nimic încă, gestionăm asta separat în UI
    if (data['requiresTwoFactor'] == true) {
      return data;
    }

    await saveToken(data['token']);
    return data;
  }

  static Future<Map<String, dynamic>> verify2FA({
    required String userId,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/2fa/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'token': token}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw ApiException(data['message'] ?? 'Cod invalid');
    }

    await saveToken(data['token']);
    return data;
  }

  static Future<Map<String, dynamic>> googleLogin(String credential) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'credential': credential}),
    );

    debugPrint('GOOGLE API STATUS: ${response.statusCode}');
    debugPrint('GOOGLE API BODY: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw ApiException(data['message'] ?? 'Autentificarea cu Google a eșuat');
    }

    await saveToken(data['token']);

    return data;
  }

  static Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw ApiException(data['message'] ?? 'Eroare la trimiterea emailului');
    }
  }

  static Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token, 'password': newPassword}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw ApiException(data['message'] ?? 'Token invalid sau expirat');
    }
  }

  static Future<Map<String, dynamic>> getCurrentUser() async {
    final token = await getToken();
    if (token == null) throw ApiException('Nu ești autentificat');

    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw ApiException(data['message'] ?? 'Eroare la obținerea profilului');
    }

    return data;
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final token = await getToken();

    if (token == null) {
      throw ApiException('Nu ești autentificat');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw ApiException(data['message'] ?? 'Eroare la încărcarea profilului');
    }

    return Map<String, dynamic>.from(data['data']);
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? username,
    String? fullName,
    String? phone,
    String? bio,
    String? avatar,
    String? country,
    String? city,
    String? county,
    String? postalCode,
    String? instagram,
    String? facebook,
    String? website,
  }) async {
    final token = await getToken();

    if (token == null) {
      throw ApiException('Nu ești autentificat');
    }

    final body = <String, dynamic>{};

    if (username != null) body['username'] = username;
    if (fullName != null) body['fullName'] = fullName;
    if (phone != null) body['phone'] = phone;
    if (bio != null) body['bio'] = bio;
    if (avatar != null) body['avatar'] = avatar;
    if (country != null) body['country'] = country;
    if (city != null) body['city'] = city;
    if (county != null) body['county'] = county;
    if (postalCode != null) body['postalCode'] = postalCode;
    if (instagram != null) body['instagram'] = instagram;
    if (facebook != null) body['facebook'] = facebook;
    if (website != null) body['website'] = website;

    final response = await http.patch(
      Uri.parse('$baseUrl/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      if (response.statusCode == 409) {
        throw ApiException('Acest nume de utilizator este deja folosit');
      }

      throw ApiException(
        data['message'] ?? 'Eroare la actualizarea profilului',
      );
    }

    return Map<String, dynamic>.from(data['data']);
  }

  static Future<void> logout() async {
    await deleteToken();
  }

  static Future<List<Listing>> getListings() async {
    final response = await http.get(Uri.parse('$baseUrl/listings'));

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw ApiException(data['message'] ?? 'Eroare la încărcarea anunțurilor');
    }

    final List<dynamic> listingsJson = data['data'];
    return listingsJson.map((json) => Listing.fromJson(json)).toList();
  }

  static Future<Listing> getListingById(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/listings/$id'));

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw ApiException(data['message'] ?? 'Anunțul nu a fost găsit');
    }

    return Listing.fromJson(data['data']);
  }

  static Future<Map<String, dynamic>> getNotificationSettings() async {
    final token = await getToken();

    if (token == null) {
      throw ApiException('Nu ești autentificat');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/profile/notification-settings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw ApiException(
        data['message'] ?? 'Eroare la încărcarea setărilor notificărilor',
      );
    }

    return Map<String, dynamic>.from(data['data'] ?? {});
  }

  static Future<Map<String, dynamic>> updateNotificationSettings(
    Map<String, bool> settings,
  ) async {
    final token = await getToken();

    if (token == null) {
      throw ApiException('Nu ești autentificat');
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/profile/notification-settings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(settings),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw ApiException(
        data['message'] ?? 'Eroare la salvarea setărilor notificărilor',
      );
    }

    return Map<String, dynamic>.from(data['data'] ?? {});
  }

  static Future<List<Conversation>> getConversations() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/chat/conversations'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw ApiException(
        data['message'] ?? 'Eroare la încărcarea conversațiilor',
      );
    }

    final List<dynamic> list = data['conversations'];
    return list.map((json) => Conversation.fromJson(json)).toList();
  }

  static Future<List<ChatMessage>> getMessages(String conversationId) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/chat/$conversationId/messages'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw ApiException(data['message'] ?? 'Eroare la încărcarea mesajelor');
    }

    final List<dynamic> list = data['messages'];
    return list.map((json) => ChatMessage.fromJson(json)).toList();
  }

  static Future<Conversation> startConversation(String listingId) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/chat/start'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'listingId': listingId}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 201 || data['success'] != true) {
      throw ApiException(data['message'] ?? 'Eroare la pornirea conversației');
    }

    return Conversation.fromJson(data['conversation']);
  }

  static Future<List<Listing>> getFavorites() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/favorites'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw ApiException(data['message'] ?? 'Eroare la încărcarea favoritelor');
    }

    // fiecare item e { _id, user, listing: {...populat...}, createdAt }
    final List<dynamic> favoritesJson = data['data'];
    return favoritesJson
        .where((f) => f['listing'] != null)
        .map((f) => Listing.fromJson(f['listing']))
        .toList();
  }

  static Future<bool> checkFavorite(String listingId) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/favorites/check/$listingId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw ApiException(
        data['message'] ?? 'Eroare la verificarea favoritului',
      );
    }

    return data['data'] == true;
  }

  static Future<bool> toggleFavorite(String listingId) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/favorites/$listingId/toggle'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw ApiException(
        data['message'] ?? 'Eroare la actualizarea favoritului',
      );
    }

    return data['data']['favorite'] == true;
  }

  // ---- Push notifications ----

  static Future<void> registerPushToken({
    required String token,
    required String platform,
  }) async {
    final jwt = await getToken();

    if (jwt == null) {
      throw ApiException('Nu ești autentificat');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/notifications/push-token'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwt',
      },
      body: jsonEncode({'token': token, 'platform': platform}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(
        data['message'] ?? 'Eroare la înregistrarea tokenului FCM',
      );
    }
  }

  static Future<List<AppNotification>> getNotifications() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw ApiException(
        data['message'] ?? 'Eroare la încărcarea notificărilor',
      );
    }

    final List<dynamic> list = data['notifications'];
    return list.map((json) => AppNotification.fromJson(json)).toList();
  }

  static Future<int> getUnreadNotificationCount() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/notifications/unread-count'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      return 0;
    }

    return data['count'] ?? 0;
  }

  static Future<void> markNotificationAsRead(String id) async {
    final token = await getToken();
    await http.patch(
      Uri.parse('$baseUrl/notifications/$id/read'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<void> markAllNotificationsAsRead() async {
    final token = await getToken();
    await http.patch(
      Uri.parse('$baseUrl/notifications/read-all'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<void> deleteNotification(String id) async {
    final token = await getToken();
    await http.delete(
      Uri.parse('$baseUrl/notifications/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<List<String>> uploadImages(
    List<File> images, {
    String folder = 'listings',
  }) async {
    final token = await getToken();

    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));

    request.headers['Authorization'] = 'Bearer $token';
    request.fields['folder'] = folder;

    for (final image in images) {
      request.files.add(
        await http.MultipartFile.fromPath('images', image.path),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);

    if (response.statusCode != 201 || data['success'] != true) {
      throw ApiException(data['message'] ?? 'Eroare la încărcarea imaginilor');
    }

    return List<String>.from(data['urls']);
  }

  static Future<Listing> createListing({
    required String title,
    required String description,
    required String category,
    required String condition,
    required double price,
    required String city,
    required List<String> images,
    bool negotiable = false,
    bool shipping = true,
    String? brand,
    String? color,
    String? size,
  }) async {
    final token = await getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/listings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'description': description,
        'category': category,
        'condition': condition,
        'price': price,
        'city': city,
        'images': images,
        'negotiable': negotiable,
        'shipping': shipping,
        if (brand != null) 'brand': brand,
        if (color != null) 'color': color,
        if (size != null) 'size': size,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 201 || data['success'] != true) {
      throw ApiException(data['message'] ?? 'Eroare la crearea anunțului');
    }

    return Listing.fromJson(data['data']);
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
