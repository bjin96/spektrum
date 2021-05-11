import 'package:flutter_test/flutter_test.dart';
import 'package:spektrum/excerpt.dart';

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  List<Excerpt> excerptList = await Excerpt.getRandomExcerptList();
  print(excerptList[0]);
}
