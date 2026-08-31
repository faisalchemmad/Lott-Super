import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/game_model.dart';
import '../models/number_limit_model.dart';
import '../models/bet_model.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://13.233.196.135/api';
    }
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.windows) {
      return 'http://13.233.196.135/api';
    } else {
      return 'http://13.233.196.135/api';
    }
  }

  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final url = '$baseUrl/login/';
      print('Attempting login to: $url');
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      print('Login Response Status: ${response.statusCode}');
      print('Login Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('role', data['user']['role']);
        await prefs.setString('username', data['user']['username']);
        await prefs.setBool(
            'can_forward', data['user']['can_forward'] ?? false);
        return data;
      } else {
        String errorMsg = 'Login failed';
        try {
          final errorData = jsonDecode(response.body);
          errorMsg = errorData['error'] ?? errorMsg;
        } catch (_) {}
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('Login Error: $e');
      rethrow;
    }
  }

  Future<List<GameModel>> getGames() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.get(
      Uri.parse('$baseUrl/games/'),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => GameModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<bool> placeBet(
      int gameId, String number, double amount, String type, int count) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.post(
      Uri.parse('$baseUrl/bets/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'game': gameId,
        'number': number,
        'amount': amount,
        'type': type,
        'count': count,
      }),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      String errorMessage = 'Failed to place bet';
      try {
        final errorData = jsonDecode(response.body);
        if (errorData is Map && errorData.isNotEmpty) {
          errorMessage = errorData.values.first.toString();
          if (errorMessage.startsWith('[') && errorMessage.endsWith(']')) {
            errorMessage = errorMessage.substring(1, errorMessage.length - 1);
          }
        } else if (errorData is List && errorData.isNotEmpty) {
          errorMessage = errorData.first.toString();
        }
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }

  Future<Map<String, dynamic>> placeBulkBets(
      int gameId, List<Map<String, dynamic>> bets,
      {int? userId, String? customerName}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final formattedBets = bets
        .map((b) => {
              'game': gameId,
              'number': b['number'],
              'type': b['type'],
              'count': b['count'],
              'state': b['state'] ?? 'KL',
            })
        .toList();

    final Map<String, dynamic> requestBody = {'bets': formattedBets};
    if (userId != null) requestBody['user_id'] = userId;
    if (customerName != null && customerName.isNotEmpty) {
      requestBody['customer_name'] = customerName;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/bets/bulk-create/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      String errorMessage = 'Failed to process invoice';
      try {
        final errorData = jsonDecode(response.body);
        if (errorData is Map && errorData['error'] != null) {
          errorMessage = errorData['error'];
        } else if (errorData is Map && errorData.isNotEmpty) {
          errorMessage = errorData.values.first.toString();
        }
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }

  Future<List<BetModel>> getBets({int? gameId}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    String url = '$baseUrl/bets/';
    if (gameId != null) url = '$url?game=$gameId';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => BetModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> getReport(String date) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.get(
      Uri.parse('$baseUrl/report/?date=$date'),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {};
  }

  Future<Map<String, dynamic>> getSalesReport({
    required String fromDate,
    required String toDate,
    int? gameId,
    int? userId,
    String? number,
    String? state,
    bool fullView = false,
    bool adminRate = false,
    bool onlyDirect = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    String url = '$baseUrl/report/sales/?from=$fromDate&to=$toDate';
    if (gameId != null) url += '&game=$gameId';
    if (userId != null) url += '&user=$userId';
    if (number != null) url += '&number=$number';
    if (state != null && state.isNotEmpty) url += '&state=$state';
    if (fullView) url += '&full_view=true';
    if (adminRate) url += '&admin_rate=true';
    if (onlyDirect) url += '&only_direct=true';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {};
  }

  Future<UserModel?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.get(
      Uri.parse('$baseUrl/users/me/'),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      final user = UserModel.fromJson(jsonDecode(response.body));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('can_forward', user.canForward);
      return user;
    }
    return null;
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.post(
      Uri.parse('$baseUrl/users/change-password/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'old_password': oldPassword,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode == 200) return true;

    String errorMessage = 'Failed to change password';
    try {
      final errorData = jsonDecode(response.body);
      errorMessage = errorData['error'] ?? errorMessage;
    } catch (_) {}
    throw Exception(errorMessage);
  }

  Future<Map<String, dynamic>> getDashboard() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/'),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {};
  }

  Future<List<UserModel>> getUsers({bool createdByMe = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    String url = '$baseUrl/users/';
    if (createdByMe) {
      url += '?created_by_me=true';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => UserModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<bool> createUser(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.post(
      Uri.parse('$baseUrl/users/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(userData),
    );
    return response.statusCode == 201;
  }

  Future<bool> createGame(String name, String time,
      {String? startTime,
      String? endTime,
      String? color,
      bool? canEditDelete,
      String? deadlineTime}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final Map<String, dynamic> data = {'name': name, 'time': time};
    if (startTime != null) data['start_time'] = startTime;
    if (endTime != null) data['end_time'] = endTime;
    if (color != null) data['color'] = color;
    if (canEditDelete != null) data['can_edit_delete'] = canEditDelete;
    if (deadlineTime != null) data['edit_delete_limit_time'] = deadlineTime;

    final response = await http.post(
      Uri.parse('$baseUrl/games/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    return response.statusCode == 201;
  }

  Future<void> updateGame(int id, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.patch(
      Uri.parse('$baseUrl/games/$id/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      String errorMessage = 'Failed to update game';
      try {
        final errorData = jsonDecode(response.body);
        if (errorData is Map && errorData.isNotEmpty) {
          errorMessage = errorData.values.first.toString();
        }
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }

  Future<bool> deleteGame(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.delete(
      Uri.parse('$baseUrl/games/$id/'),
      headers: {'Authorization': 'Token $token'},
    );
    return response.statusCode == 204;
  }

  Future<List<NumberLimitModel>> getNumberLimits(int? gameId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    String url = '$baseUrl/number-limits/';
    if (gameId != null) url += '?game=$gameId';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => NumberLimitModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<bool> createNumberLimit(
      int gameId, int userId, String number, String type, int maxCount) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.post(
      Uri.parse('$baseUrl/number-limits/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'game': gameId,
        'user': userId,
        'number': number,
        'type': type,
        'max_count': maxCount
      }),
    );
    return response.statusCode == 201;
  }

  Future<bool> updateNumberLimit(int id, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.patch(
      Uri.parse('$baseUrl/number-limits/$id/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteNumberLimit(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.delete(
      Uri.parse('$baseUrl/number-limits/$id/'),
      headers: {'Authorization': 'Token $token'},
    );
    return response.statusCode == 204;
  }

  Future<bool> updateUser(int id, Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No token found');

    final response = await http.patch(
      Uri.parse('$baseUrl/users/$id/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(userData),
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Server Error: ${response.body}');
    }
  }

  Future<bool> deleteUser(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.delete(
      Uri.parse('$baseUrl/users/$id/'),
      headers: {'Authorization': 'Token $token'},
    );
    return response.statusCode == 204;
  }

  Future<List<BetModel>> getInvoiceDetails(String invoiceId,
      {bool adminRate = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.get(
      Uri.parse(
          '$baseUrl/bets/invoice-details/$invoiceId/?admin_rate=$adminRate'),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => BetModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<bool> deleteInvoice(String invoiceId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.delete(
      Uri.parse('$baseUrl/bets/delete-invoice/$invoiceId/'),
      headers: {'Authorization': 'Token $token'},
    );
    return response.statusCode == 200;
  }

  Future<bool> updateBet(int id, String number, int count) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.patch(
      Uri.parse('$baseUrl/bets/$id/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'number': number, 'count': count}),
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteBet(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.delete(
      Uri.parse('$baseUrl/bets/$id/'),
      headers: {'Authorization': 'Token $token'},
    );
    return response.statusCode == 204;
  }

  Future<Map<String, dynamic>> getCountReport({
    String state = 'ALL',
    required String fromDate,
    required String toDate,
    int? gameId,
    int? userId,
    String? number,
    bool adminRate = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    String url = '$baseUrl/report/count/?from=$fromDate&to=$toDate';
    if (state != 'ALL') url += '&state=$state';
    if (gameId != null) url += '&game=$gameId';
    if (userId != null) url += '&user=$userId';
    if (number != null) url += '&number=$number';
    if (adminRate) url += '&admin_rate=true';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {};
  }

  Future<dynamic> getDailyReport({
    String state = 'ALL',
    required String fromDate,
    required String toDate,
    int? userId,
    List<int>? gameIds,
    bool dayDetail = false,
    bool gameDetail = false,
    bool userDetail = false,
    bool agentRate = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    String url = '$baseUrl/report/daily/?from=$fromDate&to=$toDate';
    if (state != 'ALL') url += '&state=$state';
    if (userId != null) url += '&user=$userId';
    if (dayDetail) url += '&day_detail=true';
    if (gameDetail) url += '&game_detail=true';
    if (userDetail) url += '&user_detail=true';
    if (agentRate) url += '&agent_rate=true';
    if (gameIds != null && gameIds.isNotEmpty) {
      for (var id in gameIds) {
        url += '&games=$id';
      }
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<bool> publishResult(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.post(
      Uri.parse('$baseUrl/game-results/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201 || response.statusCode == 200) return true;

    String errorMessage = 'Failed to publish result';
    try {
      final errorData = jsonDecode(response.body);
      if (errorData is Map && errorData.isNotEmpty) {
        errorMessage = errorData.values.first.toString();
      }
    } catch (_) {}
    throw Exception(errorMessage);
  }

  Future<List<dynamic>> getGameResults({String? date, int? gameId}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    String url = '$baseUrl/game-results/';
    String query = '';
    if (date != null) query += 'date=$date';
    if (gameId != null) {
      if (query.isNotEmpty) query += '&';
      query += 'game=$gameId';
    }
    if (query.isNotEmpty) url += '?$query';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<bool> deleteGameResult(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.delete(
      Uri.parse('$baseUrl/game-results/$id/'),
      headers: {'Authorization': 'Token $token'},
    );
    return response.statusCode == 204;
  }

  Future<List<dynamic>> getNumberReport({
    String state = 'ALL',
    String? fromDate,
    String? toDate,
    int? gameId,
    int? userId,
    String? type,
    bool forwardedOnly = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final Map<String, String> queryParams = {};
    if (state != 'ALL') queryParams['state'] = state;
    if (fromDate != null) queryParams['from'] = fromDate;
    if (toDate != null) queryParams['to'] = toDate;
    if (gameId != null) queryParams['game'] = gameId.toString();
    if (userId != null) queryParams['user'] = userId.toString();
    if (type != null) queryParams['type'] = type;
    if (forwardedOnly) queryParams['forwarded_only'] = 'true';

    final uri = Uri.parse('$baseUrl/report/number/')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<List<dynamic>> getGlobalNumberLimits(int gameId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.get(
      Uri.parse('$baseUrl/global-number-limits/?game=$gameId'),
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<bool> createGlobalNumberLimit(
      int gameId, String number, String type, int maxCount) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.post(
      Uri.parse('$baseUrl/global-number-limits/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'game': gameId,
        'number': number,
        'type': type,
        'max_count': maxCount,
      }),
    );
    return response.statusCode == 201;
  }

  Future<bool> deleteGlobalNumberLimit(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.delete(
      Uri.parse('$baseUrl/global-number-limits/$id/'),
      headers: {'Authorization': 'Token $token'},
    );
    return response.statusCode == 204;
  }

  Future<bool> updateGlobalNumberLimit(
      int id, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.patch(
      Uri.parse('$baseUrl/global-number-limits/$id/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>> getWinningReport({
    String state = 'ALL',
    String? fromDate,
    String? toDate,
    int? gameId,
    int? userId,
    String? number,
    bool adminRate = false,
    bool forwardedOnly = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final Map<String, String> queryParams = {};
    if (state != 'ALL') queryParams['state'] = state;
    if (fromDate != null) queryParams['from'] = fromDate;
    if (toDate != null) queryParams['to'] = toDate;
    if (gameId != null) queryParams['game'] = gameId.toString();
    if (userId != null) queryParams['user'] = userId.toString();
    if (number != null) queryParams['number'] = number;
    if (adminRate) queryParams['admin_rate'] = 'true';
    if (forwardedOnly) queryParams['forwarded_only'] = 'true';

    final uri = Uri.parse('$baseUrl/report/winning/')
        .replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {
      'total_winning_amount': 0.0,
      'total_winning_count': 0,
      'winners': []
    };
  }

  Future<List<dynamic>> getMonitorData({
    String? date,
    int? gameId,
    String? number,
    String? digits,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    Map<String, String> queryParams = {};
    if (date != null) queryParams['date'] = date;
    if (gameId != null) queryParams['game'] = gameId.toString();
    if (number != null) queryParams['number'] = number;
    if (digits != null) queryParams['digits'] = digits;

    final uri =
        Uri.parse('$baseUrl/monitor/').replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<bool> clearMonitorEntry(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.post(
      Uri.parse('$baseUrl/monitor/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

  Future<List<dynamic>> getUserGameTimings(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.get(
      Uri.parse('$baseUrl/user-game-timings/?user=$userId'),
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<bool> createUserGameTiming(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.post(
      Uri.parse('$baseUrl/user-game-timings/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    return response.statusCode == 201;
  }

  Future<bool> deleteUserGameTiming(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.delete(
      Uri.parse('$baseUrl/user-game-timings/$id/'),
      headers: {'Authorization': 'Token $token'},
    );
    return response.statusCode == 204;
  }

  Future<bool> updateUserGameTiming(int id, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.patch(
      Uri.parse('$baseUrl/user-game-timings/$id/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

  Future<List<dynamic>> getForwardNetReport({
    String? fromDate,
    String? toDate,
    int? gameId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      String url = '$baseUrl/report/forward-net/?';
      if (fromDate != null) url += 'from=$fromDate&';
      if (toDate != null) url += 'to=$toDate&';
      if (gameId != null) url += 'game=$gameId&';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Token $token'},
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load forward net report');
      }
    } catch (e) {
      throw Exception('Error fetching forward net report: $e');
    }
  }

  Future<Map<String, dynamic>> getNetReport({
    required String fromDate,
    required String toDate,
    int? gameId,
    int? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    String url = '$baseUrl/report/net/?from=$fromDate&to=$toDate';
    if (gameId != null) url += '&game=$gameId';
    if (userId != null) url += '&user=$userId';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {'breadcrumb': {}, 'data': []};
  }

  Future<Map<String, dynamic>> getSystemSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.get(
      Uri.parse('$baseUrl/system-settings/'),
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {};
  }

  Future<bool> updateSystemSettings(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.post(
      Uri.parse('$baseUrl/system-settings/update-settings/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

  Future<List<dynamic>> getForwardLimits() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.get(
      Uri.parse('$baseUrl/forward-limits/'),
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<bool> createForwardLimit(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.post(
      Uri.parse('$baseUrl/forward-limits/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    return response.statusCode == 201;
  }

  Future<bool> deleteForwardLimit(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.delete(
      Uri.parse('$baseUrl/forward-limits/$id/'),
      headers: {'Authorization': 'Token $token'},
    );
    return response.statusCode == 204;
  }

  Future<Map<String, dynamic>> getForwardPurchaseReport({
    String? fromDate,
    String? toDate,
    int? gameId,
    int? userId,
    String? number,
    String state = 'ALL',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    String url = '$baseUrl/forwarded-bets/report/?';
    if (fromDate != null) url += 'from=$fromDate&';
    if (toDate != null) url += 'to=$toDate&';
    if (gameId != null) url += 'game=$gameId&';
    if (userId != null) url += 'user=$userId&';
    if (number != null && number.isNotEmpty) url += 'number=$number&';
    if (state != 'ALL') url += 'state=$state&';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load forward report');
    }
  }

  Future<bool> deleteForwardedBet(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.delete(
      Uri.parse('$baseUrl/forwarded-bets/$id/'),
      headers: {'Authorization': 'Token $token'},
    );
    return response.statusCode == 204;
  }

  Future<List<dynamic>> getPurchaseReport(
      {String? fromDate, String? toDate, int? gameId}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final Map<String, String> queryParams = {};
    if (fromDate != null) queryParams['from'] = fromDate;
    if (toDate != null) queryParams['to'] = toDate;
    if (gameId != null) queryParams['game'] = gameId.toString();

    final uri = Uri.parse('$baseUrl/forwarded-bets/purchase_report/')
        .replace(queryParameters: queryParams);
    final response =
        await http.get(uri, headers: {'Authorization': 'Token $token'});

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<List<dynamic>> getRetainedNumbers(
      {required int gameId, required String state, String? type}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    String url =
        '$baseUrl/forwarded-bets/get_retained_numbers/?game=$gameId&state=$state';
    if (type != null && type.isNotEmpty) {
      url += '&type=$type';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<bool> submitManualForward(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.post(
      Uri.parse('$baseUrl/forwarded-bets/manual_forward/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }
}
