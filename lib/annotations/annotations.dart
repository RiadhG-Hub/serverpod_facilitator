

class ServerpodModel {
  const ServerpodModel();
}

class PgVarchar {
  final int length;
  const PgVarchar(this.length);
}

class PgText {
  const PgText();
}

class PgUnique {
  const PgUnique();
}

class PgIndex {
  final String? name;
  const PgIndex({this.name});
}

class PgDefault {
  final String value;
  const PgDefault(this.value);
}

class PgPrimaryKey {
  const PgPrimaryKey();
}

class PgForeignKey {
  final String table;
  final String column;
  const PgForeignKey(this.table, this.column);
}
