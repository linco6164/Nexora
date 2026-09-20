import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'models/listing.dart';
import 'models/chat_models.dart';
import 'models/notification_model.dart';
import 'app_navigator.dart';

class ApiService {
  static final http.Client _client = _ApiHttpClient();

  static const String baseUrl = 'https://api.nx-store.com';
  static const _storage = FlutterSecureStorage();

  // ============================================================
  // TOKEN MANAGEMENT
  // ============================================================

  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  static Future<void> handleSessionExpired() async {
    await handleGlobalSessionExpired();
  }

  static Future<void> handleUnauthorizedResponse(http.Response response) async {
    if (response.statusCode != 401) {
      return;
    }

    try {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        final code = data['code']?.toString();

        if (code == 'SESSION_EXPIRED' || code == 'SESSION_REQUIRED') {
          await handleSessionExpired();
        }
      }
    } catch (_) {}
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // ============================================================
  // AUTH
  // ============================================================

  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
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
    final deviceHeaders = await getDeviceHeaders();

    final response = await _client.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json', ...deviceHeaders},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw ApiException(data['message'] ?? 'Autentificare eșuată');
    }

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
    final deviceHeaders = await getDeviceHeaders();

    final response = await _client.post(
      Uri.parse('$baseUrl/auth/2fa/login'),
      headers: {'Content-Type': 'application/json', ...deviceHeaders},
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
    final deviceHeaders = await getDeviceHeaders();

    final response = await _client.post(
      Uri.parse('$baseUrl/auth/google'),
      headers: {'Content-Type': 'application/json', ...deviceHeaders},
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

  static Future<Map<String, dynamic>> facebookLogin(String accessToken) async {
    final deviceHeaders = await getDeviceHeaders();

    final response = await _client.post(
      Uri.parse('$baseUrl/auth/facebook'),
      headers: {'Content-Type': 'application/json', ...deviceHeaders},
      body: jsonEncode({'accessToken': accessToken}),
    );

    debugPrint('FACEBOOK API STATUS: ${response.statusCode}');
    debugPrint('FACEBOOK API BODY: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw ApiException(
        data['message'] ?? 'Autentificarea cu Facebook a eșuat',
      );
    }

    await saveToken(data['token']);

    return data;
  }

  static Future<void> forgotPassword(String email) async {
    final response = await _client.post(
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
    final response = await _client.post(
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

    if (token == null) {
      throw ApiException('Nu ești autentificat');
    }

    final response = await _client.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw ApiException(data['message'] ?? 'Eroare la obținerea profilului');
    }

    return data;
  }

  // ============================================================
  // PROFILE
  // ============================================================

  static Future<Map<String, dynamic>> getProfile() async {
    final token = await getToken();

    if (token == null) {
      throw ApiException('Nu ești autentificat');
    }

    final response = await _client.get(
      Uri.parse('$baseUrl/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw ApiException(data['message'] ?? 'Eroare la încărcarea profilului');
    }

    return Map<String, dynamic>.from(data['data']);
  }

  static Future<Map<String, dynamic>> getPublicProfile(String userId) async {
    final response = await _client.get(Uri.parse('$baseUrl/profile/$userId'));

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw ApiException(
        data['message'] ?? 'Eroare la încărcarea profilului public',
      );
    }

    return Map<String, dynamic>.from(data['data']);
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? username,
    String? fullName,
    String? email,
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
    if (email != null) body['email'] = email;
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

    final response = await _client.patch(
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

  // ============================================================
  // LOGOUT
  // ============================================================

  static Future<void> logout() async {
    final token = await getToken();

    if (token != null && token.isNotEmpty) {
      try {
        await _client.post(
          Uri.parse('$baseUrl/auth/sessions/logout'),
          headers: {'Authorization': 'Bearer $token'},
        );
      } catch (_) {}
    }

    await deleteToken();
  }

  // ============================================================
  // LISTINGS
  // ============================================================

  static Future<List<Listing>> getListings() async {
    final response = await _client.get(Uri.parse('$baseUrl/listings'));

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw ApiException(data['message'] ?? 'Eroare la încărcarea anunțurilor');
    }

    final List<dynamic> listingsJson = data['data'];

    return listingsJson.map((json) => Listing.fromJson(json)).toList();
  }

  static Future<List<Listing>> searchListings(String search) async {
    final query = search.trim();

    if (query.isEmpty) {
      return getListings();
    }

    final uri = Uri.parse('$baseUrl/listings/search')
        .replace(queryParameters: {'search': query});

    final response = await _client.get(uri);

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw ApiException(data['message'] ?? 'Eroare la căutarea anunțurilor');
    }

    final List<dynamic> listingsJson = data['data'] ?? [];

    return listingsJson.map((json) => Listing.fromJson(json)).toList();
  }

  static Future<Listing> getListingById(String id) async {
    final response = await _client.get(Uri.parse('$baseUrl/listings/$id'));

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw ApiException(data['message'] ?? 'Anunțul nu a fost găsit');
    }

    return Listing.fromJson(data['data']);
  }

  static Future<List<Listing>> getListingsByCategory(String category) async {
    final uri = Uri.parse('$baseUrl/listings/search')
        .replace(queryParameters: {'category': category});

    final response = await _client.get(uri);

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw ApiException(data['message'] ?? 'Eroare la încărcarea categoriei');
    }

    final List<dynamic> listingsJson = data['data'] ?? [];

    return listingsJson.map((json) => Listing.fromJson(json)).toList();
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

    final response = await _client.post(
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
        ...?brand != null ? {'brand': brand} : null,
        ...?color != null ? {'color': color} : null,
        ...?size != null ? {'size': size} : null,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 201 || data['success'] != true) {
      throw ApiException(data['message'] ?? 'Eroare la crearea anunțului');
    }

    return Listing.fromJson(data['data']);
  }

  // ============================================================
  // FAVORITES
  // ============================================================

  static Future<List<Listing>> getFavorites() async {
    final token = await getToken();

    final response = await _client.get(
      Uri.parse('$baseUrl/favorites'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw ApiException(data['message'] ?? 'Eroare la încărcarea favoritelor');
    }

    final List<dynamic> favoritesJson = data['data'];

    return favoritesJson
        .where((f) => f['listing'] != null)
        .map((f) => Listing.fromJson(f['listing']))
        .toList();
  }

  static Future<bool> checkFavorite(String listingId) async {
    final token = await getToken();

    final response = await _client.get(
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

    final response = await _client.post(
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

  // ============================================================
  // CHAT
  // ============================================================

  static Future<List<Conversation>> getConversations() async {
    final token = await getToken();

    final response = await _client.get(
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

    final response = await _client.get(
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

  static Future<void> markConversationAsSeen(String conversationId) async {
    final token = await getToken();

    if (token == null) {
      throw ApiException('Nu ești autentificat');
    }

    final response = await _client.patch(
      Uri.parse('$baseUrl/chat/$conversationId/seen'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw ApiException(
        data['message'] ?? 'Eroare la marcarea mesajelor ca citite',
      );
    }
  }

  static Future<Conversation> startConversation(String listingId) async {
    final token = await getToken();

    final response = await _client.post(
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

  static Future<ChatMessage> sendOffer({
    required String conversationId,
    required double amount,
  }) async {
    final token = await getToken();

    if (token == null) {
      throw ApiException('Nu ești autentificat');
    }

    final response = await _client.post(
      Uri.parse('$baseUrl/chat/offer'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'conversationId': conversationId, 'amount': amount}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 201 || data['success'] != true) {
      throw ApiException(data['message'] ?? 'Eroare la trimiterea ofertei');
    }

    return ChatMessage.fromJson(Map<String, dynamic>.from(data['message']));
  }

  static Future<Offer> acceptOffer(String offerId) async {
    final token = await getToken();

    if (token == null) {
      throw ApiException('Nu ești autentificat');
    }

    final response = await _client.patch(
      Uri.parse('$baseUrl/chat/offer/$offerId/accept'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw ApiException(data['message'] ?? 'Eroare la acceptarea ofertei');
    }

    return Offer.fromJson(Map<String, dynamic>.from(data['offer']));
  }

  static Future<Offer> rejectOffer(String offerId) async {
    final token = await getToken();

    if (token == null) {
      throw ApiException('Nu ești autentificat');
    }

    final response = await _client.patch(
      Uri.parse('$baseUrl/chat/offer/$offerId/reject'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw ApiException(data['message'] ?? 'Eroare la refuzarea ofertei');
    }

    return Offer.fromJson(Map<String, dynamic>.from(data['offer']));
  }

  static Future<void> deleteMessage({
    required String messageId,
    required String mode,
  }) async {
    final token = await getToken();

    if (token == null) {
      throw ApiException('Nu ești autentificat');
    }

    final response = await _client.delete(
      Uri.parse('$baseUrl/chat/messages/$messageId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'mode': mode}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw ApiException(data['message'] ?? 'Eroare la ștergerea mesajului');
    }
  }

  static Future<void> deleteConversation(String conversationId) async {
    final token = await getToken();

    if (token == null) {
      throw ApiException('Nu ești autentificat');
    }

    final response = await _client.delete(
      Uri.parse('$baseUrl/chat/conversations/$conversationId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw ApiException(data['message'] ?? 'Eroare la ștergerea conversației');
    }
  }

  // ============================================================
  // NOTIFICATION SETTINGS
  // ============================================================

  static Future<Map<String, dynamic>> getNotificationSettings() async {
    final token = await getToken();

    if (token == null) {
      throw ApiException('Nu ești autentificat');
    }

    final response = await _client.get(
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

    final response = await _client.patch(
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

  // ============================================================
  // PUSH NOTIFICATIONS
  // ============================================================

  static Future<void> registerPushToken({
    required String token,
    required String platform,
  }) async {
    final jwt = await getToken();

    if (jwt == null) {
      throw ApiException('Nu ești autentificat');
    }

    final response = await _client.post(
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

    final response = await _client.get(
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

    final response = await _client.get(
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

    await _client.patch(
      Uri.parse('$baseUrl/notifications/$id/read'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<void> markAllNotificationsAsRead() async {
    final token = await getToken();

    await _client.patch(
      Uri.parse('$baseUrl/notifications/read-all'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<void> deleteNotification(String id) async {
    final token = await getToken();

    await _client.delete(
      Uri.parse('$baseUrl/notifications/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  // ============================================================
  // UPLOAD
  // ============================================================

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

  // ============================================================
  // WALLET
  // ============================================================

  static Future<List<dynamic>> getWalletTransactions() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw ApiException('Nu ești autentificat.');
    }

    final response = await _client.get(
      Uri.parse('$baseUrl/wallet/transactions'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw ApiException('Răspuns invalid de la server.');
    }

    debugPrint('WALLET TRANSACTIONS RESPONSE: $decoded');

    if (response.statusCode != 200) {
      throw ApiException(
        decoded is Map<String, dynamic>
            ? (decoded['message'] ?? 'Nu s-au putut încărca tranzacțiile.')
            : 'Nu s-au putut încărca tranzacțiile.',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Format invalid pentru tranzacții.');
    }

    if (decoded['success'] != true) {
      throw ApiException(
        decoded['message'] ?? 'Nu s-au putut încărca tranzacțiile.',
      );
    }

    final data = decoded['data'];

    if (data is List) {
      return List<dynamic>.from(data);
    }

    if (data is Map<String, dynamic>) {
      final transactions = data['transactions'];

      if (transactions is List) {
        return List<dynamic>.from(transactions);
      }
    }

    return [];
  }

  static Future<Map<String, dynamic>> withdrawMoney({
    required double amount,
    required String iban,
    required String accountName,
  }) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw ApiException('Nu ești autentificat.');
    }

    final response = await _client.post(
      Uri.parse('$baseUrl/wallet/withdraw'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'amount': amount,
        'iban': iban.trim(),
        'accountName': accountName.trim(),
      }),
    );

    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw ApiException('Răspuns invalid de la server.');
    }

    if (response.statusCode != 201 || decoded['success'] != true) {
      throw ApiException(
        decoded is Map<String, dynamic>
            ? (decoded['message'] ?? 'Retragerea a eșuat.')
            : 'Retragerea a eșuat.',
      );
    }

    return Map<String, dynamic>.from(decoded['data'] ?? {});
  }

  static Future<Map<String, dynamic>> purchaseListing(String listingId) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw ApiException('Nu ești autentificat.');
    }

    final response = await _client.post(
      Uri.parse('$baseUrl/wallet/purchase'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'listingId': listingId}),
    );

    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw ApiException('Răspuns invalid de la server.');
    }

    if (response.statusCode != 201 || decoded['success'] != true) {
      throw ApiException(
        decoded is Map<String, dynamic>
            ? (decoded['message'] ?? 'Cumpărarea a eșuat.')
            : 'Cumpărarea a eșuat.',
      );
    }

    return Map<String, dynamic>.from(decoded['data'] ?? {});
  }

  // ============================================================
  // NETOPIA
  // ============================================================

  static Future<Map<String, dynamic>> createNetopiaPayment(
    String listingId,
  ) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw ApiException('Nu ești autentificat.');
    }

    final response = await _client.post(
      Uri.parse('$baseUrl/payments/netopia/create'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'listingId': listingId}),
    );

    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw ApiException('Răspuns invalid de la server.');
    }

    if (response.statusCode != 201 ||
        decoded is! Map<String, dynamic> ||
        decoded['success'] != true) {
      throw ApiException(
        decoded is Map<String, dynamic>
            ? (decoded['message'] ?? 'Nu am putut iniția plata.')
            : 'Nu am putut iniția plata.',
      );
    }

    return Map<String, dynamic>.from(decoded['data'] ?? {});
  }

  // ============================================================
  // SUPPORT
  // ============================================================

  static Future<Map<String, dynamic>> createSupportTicket({
    required String subject,
    required String category,
    required String message,
    String? banReason,
  }) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw ApiException('Nu ești autentificat.');
    }

    final response = await _client.post(
      Uri.parse('$baseUrl/support/tickets'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'subject': subject,
        'category': category,
        'message': message,
        if (banReason != null && banReason.isNotEmpty) 'banReason': banReason,
      }),
    );

    debugPrint('CREATE SUPPORT TICKET STATUS: ${response.statusCode}');
    debugPrint('CREATE SUPPORT TICKET BODY: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw ApiException(
        data['message'] ?? 'Nu s-a putut crea tichetul de suport.',
      );
    }

    return data;
  }

  static Future<List<dynamic>> getSupportTickets() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw ApiException('Nu ești autentificat.');
    }

    final response = await _client.get(
      Uri.parse('$baseUrl/support/tickets'),
      headers: {'Authorization': 'Bearer $token'},
    );

    debugPrint('GET SUPPORT TICKETS STATUS: ${response.statusCode}');
    debugPrint('GET SUPPORT TICKETS BODY: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw ApiException(data['message'] ?? 'Nu s-au putut încărca tichetele.');
    }

    return List<dynamic>.from(data['tickets'] ?? []);
  }

  static Future<Map<String, dynamic>> getSupportTicket(String ticketId) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw ApiException('Nu ești autentificat.');
    }

    final response = await _client.get(
      Uri.parse('$baseUrl/support/tickets/$ticketId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw ApiException(data['message'] ?? 'Nu s-a putut încărca tichetul.');
    }

    return data;
  }

  static Future<Map<String, dynamic>> sendSupportMessage({
    required String ticketId,
    required String message,
  }) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw ApiException('Nu ești autentificat.');
    }

    final response = await _client.post(
      Uri.parse('$baseUrl/support/tickets/$ticketId/messages'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'message': message}),
    );

    debugPrint('SUPPORT MESSAGE STATUS: ${response.statusCode}');
    debugPrint('SUPPORT MESSAGE BODY: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw ApiException(data['message'] ?? 'Nu s-a putut trimite mesajul.');
    }

    return data;
  }

  static Future<Map<String, dynamic>> closeSupportTicket(
    String ticketId,
  ) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw ApiException('Nu ești autentificat.');
    }

    final response = await _client.patch(
      Uri.parse('$baseUrl/support/tickets/$ticketId/close'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw ApiException(data['message'] ?? 'Nu s-a putut închide tichetul.');
    }

    return data;
  }

  // ============================================================
  // VISUAL SEARCH
  // ============================================================

  static Future<List<Listing>> visualSearchListings(File image) async {
    final uri = Uri.parse('$baseUrl/listings/visual-search');

    final request = http.MultipartRequest('POST', uri);

    request.files.add(await http.MultipartFile.fromPath('image', image.path));

    final streamedResponse = await request.send();

    final response = await http.Response.fromStream(streamedResponse);

    debugPrint('VISUAL SEARCH STATUS: ${response.statusCode}');
    debugPrint('VISUAL SEARCH BODY: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw ApiException(data['message'] ?? 'Eroare la căutarea vizuală');
    }

    final List<dynamic> listingsJson = data['data']['listings'] ?? [];

    return listingsJson.map((json) => Listing.fromJson(json)).toList();
  }

  // ============================================================
  // ADDRESSES
  // ============================================================

  static Future<List<Map<String, dynamic>>> getAddresses() async {
    final token = await getToken();

    if (token == null) {
      throw ApiException('Nu ești autentificat');
    }

    final response = await _client.get(
      Uri.parse('$baseUrl/profile/addresses'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw ApiException(data['message'] ?? 'Eroare la încărcarea adreselor');
    }

    return List<Map<String, dynamic>>.from(
      (data['data'] as List).map((item) => Map<String, dynamic>.from(item)),
    );
  }

  static Future<Map<String, dynamic>> createAddress({
    required String county,
    required String city,
    required String street,
    required String number,
    String? building,
    String? staircase,
    String? floor,
    String? apartment,
    String? postalCode,
    bool isDefault = false,
  }) async {
    final token = await getToken();

    if (token == null) {
      throw ApiException('Nu ești autentificat');
    }

    final response = await _client.post(
      Uri.parse('$baseUrl/profile/addresses'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'county': county,
        'city': city,
        'street': street,
        'number': number,
        if (building != null && building.isNotEmpty) 'building': building,
        if (staircase != null && staircase.isNotEmpty) 'staircase': staircase,
        if (floor != null && floor.isNotEmpty) 'floor': floor,
        if (apartment != null && apartment.isNotEmpty) 'apartment': apartment,
        if (postalCode != null && postalCode.isNotEmpty)
          'postalCode': postalCode,
        'isDefault': isDefault,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 201 || data['success'] != true) {
      throw ApiException(data['message'] ?? 'Eroare la crearea adresei');
    }

    return Map<String, dynamic>.from(data['data']);
  }

  static Future<Map<String, dynamic>> updateAddress({
    required String addressId,
    required String county,
    required String city,
    required String street,
    required String number,
    String? building,
    String? staircase,
    String? floor,
    String? apartment,
    String? postalCode,
    bool? isDefault,
  }) async {
    final token = await getToken();

    if (token == null) {
      throw ApiException('Nu ești autentificat');
    }

    final body = <String, dynamic>{
      'county': county,
      'city': city,
      'street': street,
      'number': number,
      if (building != null) 'building': building,
      if (staircase != null) 'staircase': staircase,
      if (floor != null) 'floor': floor,
      if (apartment != null) 'apartment': apartment,
      if (postalCode != null) 'postalCode': postalCode,
    };

    if (isDefault != null) {
      body['isDefault'] = isDefault;
    }

    final response = await _client.patch(
      Uri.parse('$baseUrl/profile/addresses/$addressId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw ApiException(data['message'] ?? 'Eroare la actualizarea adresei');
    }

    return Map<String, dynamic>.from(data['data']);
  }

  static Future<void> deleteAddress(String addressId) async {
    final token = await getToken();

    if (token == null) {
      throw ApiException('Nu ești autentificat');
    }

    final response = await _client.delete(
      Uri.parse('$baseUrl/profile/addresses/$addressId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw ApiException(data['message'] ?? 'Eroare la ștergerea adresei');
    }
  }

  static Future<Map<String, dynamic>> setDefaultAddress(
    String addressId,
  ) async {
    final token = await getToken();

    if (token == null) {
      throw ApiException('Nu ești autentificat');
    }

    final response = await _client.patch(
      Uri.parse('$baseUrl/profile/addresses/$addressId/default'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw ApiException(
        data['message'] ?? 'Eroare la setarea adresei implicite',
      );
    }

    return Map<String, dynamic>.from(data['data']);
  }

  // ============================================================
  // SECURITY / PASSWORD
  // ============================================================

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await getToken();

    if (token == null) {
      throw ApiException('Nu ești autentificat');
    }

    final response = await _client.patch(
      Uri.parse('$baseUrl/profile/change-password'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw ApiException(data['message'] ?? 'Nu s-a putut schimba parola.');
    }
  }

  // ============================================================
  // 2FA
  // ============================================================

  static Future<Map<String, dynamic>> setup2FA() async {
    final token = await getToken();

    if (token == null) {
      throw ApiException('Nu ești autentificat');
    }

    final response = await _client.post(
      Uri.parse('$baseUrl/profile/2fa/setup'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw ApiException(data['message'] ?? 'Nu s-a putut configura 2FA.');
    }

    return Map<String, dynamic>.from(data);
  }

  static Future<List<String>> verify2FASetup({
    required String tokenCode,
  }) async {
    final token = await getToken();

    if (token == null) {
      throw ApiException('Nu ești autentificat');
    }

    final response = await _client.post(
      Uri.parse('$baseUrl/profile/2fa/verify'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'token': tokenCode}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw ApiException(data['message'] ?? 'Codul 2FA este invalid.');
    }

    return List<String>.from(data['recoveryCodes'] ?? []);
  }

  static Future<bool> get2FAStatus() async {
    final token = await getToken();

    if (token == null) {
      throw ApiException('Nu ești autentificat.');
    }

    final response = await _client.get(
      Uri.parse('$baseUrl/profile/2fa/status'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    debugPrint('2FA status: ${response.statusCode}');
    debugPrint('2FA status response: ${response.body}');

    if (response.statusCode != 200) {
      throw ApiException('Nu s-a putut verifica starea 2FA.');
    }

    final data = jsonDecode(response.body);

    if (data['success'] != true) {
      throw ApiException(
        data['message']?.toString() ?? 'Nu s-a putut verifica starea 2FA.',
      );
    }

    return data['enabled'] == true;
  }

  static Future<void> disable2FA({required String tokenCode}) async {
    final token = await getToken();

    if (token == null) {
      throw ApiException('Nu ești autentificat.');
    }

    final response = await _client.post(
      Uri.parse('$baseUrl/profile/2fa/disable'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'token': tokenCode}),
    );

    debugPrint('2FA disable status: ${response.statusCode}');
    debugPrint('2FA disable response: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw ApiException(
        data['message']?.toString() ?? 'Nu s-a putut dezactiva 2FA.',
      );
    }
  }

  // ============================================================
  // SESSIONS
  // ============================================================

  static Future<List<Map<String, dynamic>>> getSessions() async {
    final token = await getToken();

    if (token == null) {
      throw ApiException('Nu ești autentificat');
    }

    final response = await _client.get(
      Uri.parse('$baseUrl/auth/sessions'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      final data = _decodeSafely(response.body);

      throw ApiException(
        data is Map<String, dynamic>
            ? (data['message'] ?? 'Nu s-au putut încărca sesiunile.')
            : 'Nu s-au putut încărca sesiunile.',
      );
    }

    final data = jsonDecode(response.body);

    return List<Map<String, dynamic>>.from(data['data'] ?? []);
  }

  static Future<void> deleteSession(String sessionId) async {
    final token = await getToken();

    if (token == null) {
      throw ApiException('Nu ești autentificat');
    }

    final response = await _client.delete(
      Uri.parse('$baseUrl/auth/sessions/$sessionId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      final data = _decodeSafely(response.body);

      throw ApiException(
        data is Map<String, dynamic>
            ? (data['message'] ?? 'Sesiunea nu a putut fi închisă.')
            : 'Sesiunea nu a putut fi închisă.',
      );
    }
  }

  static Future<void> deleteOtherSessions() async {
    final token = await getToken();

    if (token == null) {
      throw ApiException('Nu ești autentificat');
    }

    final response = await _client.delete(
      Uri.parse('$baseUrl/auth/sessions/others'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      final data = _decodeSafely(response.body);

      throw ApiException(
        data is Map<String, dynamic>
            ? (data['message'] ?? 'Celelalte sesiuni nu au putut fi închise.')
            : 'Celelalte sesiuni nu au putut fi închise.',
      );
    }
  }

  // ============================================================
  // DEVICE
  // ============================================================

  static Future<Map<String, String>> getDeviceHeaders() async {
    final deviceInfo = DeviceInfoPlugin();

    // ============================================================
    // WEB
    // ============================================================

    if (kIsWeb) {
      return {
        'x-device-name': 'Browser',
        'x-platform': 'web',
        'x-browser': 'Chrome',
      };
    }

    // ============================================================
    // ANDROID
    // ============================================================

    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;

      return {
        'x-device-name': '${info.manufacturer} ${info.model}',
        'x-platform': 'android',
        'x-browser': '',
      };
    }

    // ============================================================
    // IOS
    // ============================================================

    if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;

      return {'x-device-name': info.name, 'x-platform': 'ios', 'x-browser': ''};
    }

    // ============================================================
    // WINDOWS / MACOS / LINUX
    // ============================================================

    return {
      'x-device-name': 'Desktop',
      'x-platform': 'desktop',
      'x-browser': '',
    };
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static dynamic _decodeSafely(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> getEmailVerificationStatus() async {
    final token = await getToken();

    final response = await _client.get(
      Uri.parse('$baseUrl/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Nu s-a putut verifica statusul emailului.');
    }

    final data = jsonDecode(response.body);

    return data['data']?['user']?['emailVerified'] == true;
  }

  static Future<void> sendEmailVerification() async {
    final token = await getToken();

    final response = await _client.post(
      Uri.parse('$baseUrl/profile/email-verification/send'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(
        data['message'] ?? 'Nu s-a putut trimite codul de verificare.',
      );
    }
  }

  static Future<void> verifyEmail({required String code}) async {
    final token = await getToken();

    final response = await _client.post(
      Uri.parse('$baseUrl/profile/email-verification/verify'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'code': code}),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Codul de verificare este invalid.');
    }
  }

  static Future<void> requestEmailChange({
    required String newEmail,
    required String currentPassword,
  }) async {
    final token = await getToken();

    final response = await _client.post(
      Uri.parse('$baseUrl/profile/email-verification/change/request'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'newEmail': newEmail,
        'currentPassword': currentPassword,
      }),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);

      throw Exception(
        data['message'] ?? 'Nu s-a putut solicita schimbarea emailului.',
      );
    }
  }

  static Future<void> confirmEmailChange({required String code}) async {
    final token = await getToken();

    final response = await _client.post(
      Uri.parse('$baseUrl/profile/email-verification/change/confirm'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'code': code}),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);

      throw Exception(data['message'] ?? 'Codul de verificare este invalid.');
    }
  }

  static Future<void> sendPhoneVerification() async {
    final token = await getToken();

    if (token == null) {
      throw ApiException('Nu ești autentificat');
    }

    final response = await _client.post(
      Uri.parse('$baseUrl/profile/phone-verification/send'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = _decodeSafely(response.body);

      throw ApiException(
        data is Map<String, dynamic>
            ? (data['message'] ?? 'Nu s-a putut trimite codul SMS.')
            : 'Nu s-a putut trimite codul SMS.',
      );
    }
  }

  static Future<void> verifyPhone({required String code}) async {
    final token = await getToken();

    if (token == null) {
      throw ApiException('Nu ești autentificat');
    }

    final response = await _client.post(
      Uri.parse('$baseUrl/profile/phone-verification/verify'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'code': code}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = _decodeSafely(response.body);

      throw ApiException(
        data is Map<String, dynamic>
            ? (data['message'] ?? 'Codul de verificare este invalid.')
            : 'Codul de verificare este invalid.',
      );
    }
  }

  static Future<void> requestPhoneChange({
    required String newPhone,
    required String currentPassword,
  }) async {
    final token = await getToken();

    if (token == null) {
      throw ApiException('Nu ești autentificat');
    }

    final response = await _client.post(
      Uri.parse('$baseUrl/profile/phone-verification/change/request'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'newPhone': newPhone,
        'currentPassword': currentPassword,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = _decodeSafely(response.body);

      throw ApiException(
        data is Map<String, dynamic>
            ? (data['message'] ?? 'Nu s-a putut solicita schimbarea numărului.')
            : 'Nu s-a putut solicita schimbarea numărului.',
      );
    }
  }

  static Future<void> confirmPhoneChange({required String code}) async {
    final token = await getToken();

    if (token == null) {
      throw ApiException('Nu ești autentificat');
    }

    final response = await _client.post(
      Uri.parse('$baseUrl/profile/phone-verification/change/confirm'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'code': code}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = _decodeSafely(response.body);

      throw ApiException(
        data is Map<String, dynamic>
            ? (data['message'] ?? 'Nu s-a putut confirma schimbarea numărului.')
            : 'Nu s-a putut confirma schimbarea numărului.',
      );
    }
  }
}

// ================================================================
// CENTRAL HTTP CLIENT
// ================================================================

class _ApiHttpClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request);

    if (response.statusCode != 401) {
      return response;
    }

    final bytes = await response.stream.toBytes();
    final body = utf8.decode(bytes);

    try {
      final data = jsonDecode(body);

      if (data is Map<String, dynamic>) {
        final code = data['code']?.toString();

        if (code == 'SESSION_EXPIRED' || code == 'SESSION_REQUIRED') {
          final path = request.url.path;

          // ============================================================
          // PUBLIC ENDPOINTS
          // ============================================================

          final isPublicEndpoint =
              path.startsWith('/listings/') &&
              !path.contains('/favorite') &&
              !path.contains('/toggle');

          if (!isPublicEndpoint) {
            await ApiService.handleSessionExpired();
          }
        }
      }
    } catch (_) {}

    return http.StreamedResponse(
      Stream.fromIterable([bytes]),
      response.statusCode,
      contentLength: bytes.length,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() {
    _inner.close();
  }
}

// ================================================================
// API EXCEPTION
// ================================================================

class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}
