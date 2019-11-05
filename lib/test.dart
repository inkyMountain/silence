class Person {
  final name;
  final age;
  Person(this.name, this.age);
}

main(List<String> args) {
  var p = Person('cyt', 20);
  print(p.name);
  print(p.age);
}

void fn1({String name = 'cyt'}) {
  print('$name');
}

void fn2([String name = 'cyt222']) {
  print(name);
}

class Test {
  final name;
  static const MaxLife = 200;
  Test({this.name});
}
