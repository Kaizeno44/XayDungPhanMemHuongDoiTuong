import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:bizflow_mobile/core/service_locator.dart';
import 'package:bizflow_mobile/repositories/product_repository.dart';

// Dòng này cực quan trọng để sinh code
part 'app_providers.g.dart';

// Tạo provider cho ProductRepository
// keepAlive: true giúp Repo không bị hủy, giống như Singleton
@Riverpod(keepAlive: true)
ProductRepository productRepository(ProductRepositoryRef ref) {
  // Lấy repo từ ServiceLocator đã setup sẵn
  return ServiceLocator.productRepo;
}
