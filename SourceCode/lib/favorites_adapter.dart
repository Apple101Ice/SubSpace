import 'package:hive/hive.dart';

part 'favorites_adapter.g.dart';

@HiveType(typeId: 1)
class Favorites {
  @HiveField(0)
  final String id;

  Favorites(this.id);
}
