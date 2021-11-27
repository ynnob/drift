part of 'dsl.dart';

/// Base class for dsl [Table]s and [View]s.
abstract class HasResultSet {
  /// Default constant constructor.
  const HasResultSet();
}

/// Base class for dsl [Table]s and [View]s.
abstract class ColumnDefinition extends HasResultSet {
  /// Default constant constructor.
  const ColumnDefinition();

  /// Use this as the body of a getter to declare a column that holds integers.
  /// Example (inside the body of a table class):
  /// ```
  /// IntColumn get id => integer().autoIncrement()();
  /// ```
  @protected
  ColumnBuilder<int> integer() => _isGenerated();

  /// Creates a column to store an `enum` class [T].
  ///
  /// In the database, the column will be represented as an integer
  /// corresponding to the enum's index. Note that this can invalidate your data
  /// if you add another value to the enum class.
  @protected
  ColumnBuilder<int> intEnum<T>() => _isGenerated();

  /// Use this as the body of a getter to declare a column that holds strings.
  /// Example (inside the body of a table class):
  /// ```
  /// TextColumn get name => text()();
  /// ```
  @protected
  ColumnBuilder<String> text() => _isGenerated();

  /// Use this as the body of a getter to declare a column that holds bools.
  /// Example (inside the body of a table class):
  /// ```
  /// BoolColumn get isAwesome => boolean()();
  /// ```
  @protected
  ColumnBuilder<bool> boolean() => _isGenerated();

  /// Use this as the body of a getter to declare a column that holds date and
  /// time. Note that [DateTime] values are stored on a second-accuracy.
  /// Example (inside the body of a table class):
  /// ```
  /// DateTimeColumn get accountCreatedAt => dateTime()();
  /// ```
  @protected
  ColumnBuilder<DateTime> dateTime() => _isGenerated();

  /// Use this as the body of a getter to declare a column that holds arbitrary
  /// data blobs, stored as an [Uint8List]. Example:
  /// ```
  /// BlobColumn get payload => blob()();
  /// ```
  @protected
  ColumnBuilder<Uint8List> blob() => _isGenerated();

  /// Use this as the body of a getter to declare a column that holds floating
  /// point numbers. Example
  /// ```
  /// RealColumn get averageSpeed => real()();
  /// ```
  @protected
  ColumnBuilder<double> real() => _isGenerated();
}

/// Subclasses represent a table in a database generated by drift.
abstract class Table extends ColumnDefinition {
  /// Defines a table to be used with drift.
  const Table();

  /// The sql table name to be used. By default, drift will use the snake_case
  /// representation of your class name as the sql table name. For instance, a
  /// [Table] class named `LocalSettings` will be called `local_settings` by
  /// default.
  /// You can change that behavior by overriding this method to use a custom
  /// name. Please note that you must directly return a string literal by using
  /// a getter. For instance `@override String get tableName => 'my_table';` is
  /// valid, whereas `@override final String tableName = 'my_table';` or
  /// `@override String get tableName => createMyTableName();` is not.
  @visibleForOverriding
  String? get tableName => null;

  /// Whether to append a `WITHOUT ROWID` clause in the `CREATE TABLE`
  /// statement. This is intended to be used by generated code only.
  bool get withoutRowId => false;

  /// Drift will write some table constraints automatically, for instance when
  /// you override [primaryKey]. You can turn this behavior off if you want to.
  /// This is intended to be used by generated code only.
  bool get dontWriteConstraints => false;

  /// Override this to specify custom primary keys:
  /// ```dart
  /// class IngredientInRecipes extends Table {
  ///  @override
  ///  Set<Column> get primaryKey => {recipe, ingredient};
  ///
  ///  IntColumn get recipe => integer()();
  ///  IntColumn get ingredient => integer()();
  ///
  ///  IntColumn get amountInGrams => integer().named('amount')();
  ///}
  /// ```
  /// The getter must return a set literal using the `=>` syntax so that the
  /// drift generator can understand the code.
  /// Also, please note that it's an error to have an
  /// [BuildIntColumn.autoIncrement] column and a custom primary key.
  /// As an auto-incremented `IntColumn` is recognized by drift to be the
  /// primary key, doing so will result in an exception thrown at runtime.
  @visibleForOverriding
  Set<Column>? get primaryKey => null;

  /// Custom table constraints that should be added to the table.
  ///
  /// See also:
  ///  - https://www.sqlite.org/syntax/table-constraint.html, which defines what
  ///    table constraints are supported.
  List<String> get customConstraints => [];
}

/// Subclasses represent a view in a database generated by drift.
abstract class View extends ColumnDefinition {
  /// Defines a view to be used with drift.
  const View();

  ///
  @protected
  View select(List<Expression> columns) => _isGenerated();

  ///
  @protected
  SimpleSelectStatement from(Table table) => _isGenerated();

  ///
  @visibleForOverriding
  Query as();
}

/// A class to be used as an annotation on [Table] classes to customize the
/// name for the data class that will be generated for the table class. The data
/// class is a dart object that will be used to represent a row in the table.
/// {@template drift_custom_data_class}
/// By default, drift will attempt to use the singular form of the table name
/// when naming data classes (e.g. a table named "Users" will generate a data
/// class called "User"). However, this doesn't work for irregular plurals and
/// you might want to choose a different name, for which this annotation can be
/// used.
/// {@template}
@Target({TargetKind.classType})
class DataClassName {
  /// The overridden name to use when generating the data class for a table.
  /// {@macro drift_custom_data_class}
  final String name;

  /// Customize the data class name for a given table.
  /// {@macro drift_custom_data_class}
  const DataClassName(this.name);
}

/// An annotation specifying an existing class to be used as a data class.
@Target({TargetKind.classType})
@experimental
class UseRowClass {
  /// The existing class
  ///
  /// This type must refer to an existing class. All other types, like functions
  /// or types with arguments, are not allowed.
  final Type type;

  /// The name of the constructor to use.
  ///
  /// When this option is not set, the default (unnamed) constructor will be
  /// used to map database rows to the desired row class.
  final String constructor;

  /// Generate a `toInsertable()` extension function for [type] mapping all
  /// fields to an insertable object.
  ///
  /// This can be useful when a custom data class should be used for inserts or
  /// updates.
  final bool generateInsertable;

  /// Customize the class used by drift to hold an instance of an annotated
  /// table.
  ///
  /// For details, see the overall documentation on [UseRowClass].
  const UseRowClass(this.type,
      {this.constructor = '', this.generateInsertable = false});
}

/// An annotation specifying view properties
@Target({TargetKind.classType})
class DriftView {
  /// The sql view name to be used. By default, drift will use the snake_case
  /// representation of your class name as the sql view name. For instance, a
  /// [View] class named `UserView` will be called `user_view` by
  /// default.
  final String? name;

  /// The name for the data class that will be generated for the view class.
  /// The data class is a dart object that will be used to represent a result of
  /// the view.
  /// {@template drift_custom_data_class}
  /// By default, drift will attempt to use the view name followed by "Data"
  /// when naming data classes (e.g. a view named "UserView" will generate a
  /// data class called "UserViewData").
  /// {@macro drift_custom_data_class}
  final String? dataClassName;

  /// Customize view name and data class name
  const DriftView({this.name, this.dataClassName});
}

///
@Target({TargetKind.getter})
class Reference {
  ///
  final Type type;

  ///
  const Reference(this.type);
}
