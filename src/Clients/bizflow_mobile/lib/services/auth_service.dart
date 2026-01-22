import 'package:chopper/chopper.dart';

part 'auth_service.chopper.dart';

// 👇 SỬA DÒNG NÀY: Đổi 'users' thành 'auth'
@ChopperApi(baseUrl: '/api/auth')
abstract class AuthService extends ChopperService {
  static AuthService create([ChopperClient? client]) => _$AuthService(client);

  @Post(path: '/login')
  Future<Response<dynamic>> login(@Body() Map<String, dynamic> body);

  @Post(path: '/register')
  Future<Response<dynamic>> register(@Body() Map<String, dynamic> body);
}
