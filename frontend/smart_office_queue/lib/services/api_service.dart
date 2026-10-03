import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:8080';

  static String? token;

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      token = data['token'];
      return data;
    }

    throw Exception(
      'HTTP ${response.statusCode}: ${response.body}',
    );
  }

  static Future<Map<String, dynamic>> getDashboard(
    int departmentId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/dashboard?department_id=$departmentId',
      ),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'HTTP ${response.statusCode}: ${response.body}',
    );
  }

 static Future<List<dynamic>> getQueue(
  int departmentId,
) async {
  final response = await http.get(
    Uri.parse(
      '$baseUrl/api/queue?department_id=$departmentId',
    ),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    if (data is List) {
      return data;
    }

    throw Exception(
      'Queue API returned invalid data',
    );
  }

  throw Exception(
    'HTTP ${response.statusCode}: ${response.body}',
  );
}

  static Future<Map<String, dynamic>> callNext(
    int departmentId,
  ) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/api/queue/next?department_id=$departmentId',
      ),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'HTTP ${response.statusCode}: ${response.body}',
    );
  }

  static Future<Map<String, dynamic>> completeToken(
    int tokenId,
  ) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/api/queue/complete?token_id=$tokenId',
      ),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'HTTP ${response.statusCode}: ${response.body}',
    );
  }

  static Future<Map<String, dynamic>> noShowToken(
    int tokenId,
  ) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/api/queue/no-show?token_id=$tokenId',
      ),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'HTTP ${response.statusCode}: ${response.body}',
    );
  }


  static Future<Map<String, dynamic>> transferToken({
  required int tokenId,
  required int toDepartmentId,
}) async {
  final response = await http.post(
    Uri.parse(
      '$baseUrl/api/queue/transfer'
      '?token_id=$tokenId'
      '&to_department_id=$toDepartmentId',
    ),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  }

  throw Exception(
    'HTTP ${response.statusCode}: ${response.body}',
  );
}

  static Future<Map<String, dynamic>> createToken({
  required int departmentId,
  required String visitorName,
  required bool priority,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/tokens'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'department_id': departmentId,
      'visitor_name': visitorName,
      'priority': priority,
    }),
  );

  if (response.statusCode == 200 ||
      response.statusCode == 201) {
    return jsonDecode(response.body);
  }

  throw Exception(
    'HTTP ${response.statusCode}: ${response.body}',
  );
}


static Future<Map<String, dynamic>> cancelToken(
  int tokenId,
) async {
  final response = await http.post(
    Uri.parse(
      '$baseUrl/api/queue/cancel?token_id=$tokenId',
    ),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  }

  throw Exception(
    'HTTP ${response.statusCode}: ${response.body}',
  );
}


static Future<List<dynamic>> getDepartments() async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/departments'),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  }

  throw Exception(
    'HTTP ${response.statusCode}: ${response.body}',
  );
}

static Future<void> setDepartmentPause({
  required int departmentId,
  required bool paused,
}) async {
  final response = await http.post(
    Uri.parse(
      '$baseUrl/api/departments/pause'
      '?department_id=$departmentId'
      '&paused=$paused',
    ),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    return;
  }

  throw Exception(
    'HTTP ${response.statusCode}: ${response.body}',
  );
}

static Future<List<dynamic>> getVisitorQueue(
  int departmentId,
) async {
  final response = await http.get(
    Uri.parse(
      '$baseUrl/api/queue?department_id=$departmentId',
    ),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  }

  throw Exception(
    'HTTP ${response.statusCode}: ${response.body}',
  );
}


static Future<Map<String, dynamic>> getTokenStatus(
  int tokenId,
) async {
  final response = await http.get(
    Uri.parse(
      '$baseUrl/api/tokens/status?token_id=$tokenId',
    ),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  }

  throw Exception(
    'HTTP ${response.statusCode}: ${response.body}',
  );
}

static void logout() {
  token = null;
}
}

