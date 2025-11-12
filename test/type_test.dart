import 'package:test/test.dart';
import 'package:pubmind/models/type.dart';

void main() {
  group('Type Definitions', () {
    test('DynamicMap should accept any type', () {
      DynamicMap dynamicMap = {'key1': 'value1', 'key2': 2, 'key3': true};
      expect(dynamicMap['key1'], isA<String>());
      expect(dynamicMap['key2'], isA<int>());
      expect(dynamicMap['key3'], isA<bool>());
    });

    test('StringMap should only accept String values', () {
      StringMap stringMap = {'key1': 'value1', 'key2': 'value2'};
      expect(stringMap['key1'], isA<String>());
      expect(stringMap['key2'], isA<String>());
    });

    test('IntMap should only accept int values', () {
      IntMap intMap = {'key1': 1, 'key2': 2};
      expect(intMap['key1'], isA<int>());
      expect(intMap['key2'], isA<int>());
    });

    test('DoubleMap should only accept double values', () {
      DoubleMap doubleMap = {'key1': 1.0, 'key2': 2.5};
      expect(doubleMap['key1'], isA<double>());
      expect(doubleMap['key2'], isA<double>());
    });

    test('BoolMap should only accept bool values', () {
      BoolMap boolMap = {'key1': true, 'key2': false};
      expect(boolMap['key1'], isA<bool>());
      expect(boolMap['key2'], isA<bool>());
    });

    test('ListMap should accept List values', () {
      ListMap listMap = {'key1': [1, 2, 3], 'key2': ['a', 'b']};
      expect(listMap['key1'], isA<List<dynamic>>());
      expect(listMap['key2'], isA<List<dynamic>>());
    });
  });
}
