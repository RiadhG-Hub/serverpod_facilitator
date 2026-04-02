class ServerpodModel {
  final List<String>? customSql;
  const ServerpodModel({this.customSql});
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

class PgBigInt {
  const PgBigInt();
}

class PgJson {
  const PgJson();
}

class PgJsonb {
  const PgJsonb();
}

class PgUuid {
  const PgUuid();
}

class PgNumeric {
  final int precision;
  final int scale;
  const PgNumeric(this.precision, this.scale);
}

class PgTimestamp {
  const PgTimestamp();
}

class PgTimestamptz {
  const PgTimestamptz();
}

class PgCustomSql {
  final String sql;
  const PgCustomSql(this.sql);
}
