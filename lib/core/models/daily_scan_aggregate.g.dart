// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_scan_aggregate.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDailyScanAggregateCollection on Isar {
  IsarCollection<DailyScanAggregate> get dailyScanAggregates =>
      this.collection();
}

const DailyScanAggregateSchema = CollectionSchema(
  name: r'DailyScanAggregate',
  id: -3362023864313002851,
  properties: {
    r'date': PropertySchema(
      id: 0,
      name: r'date',
      type: IsarType.dateTime,
    ),
    r'fishCounts': PropertySchema(
      id: 1,
      name: r'fishCounts',
      type: IsarType.stringList,
    ),
    r'topFishName': PropertySchema(
      id: 2,
      name: r'topFishName',
      type: IsarType.string,
    ),
    r'totalScans': PropertySchema(
      id: 3,
      name: r'totalScans',
      type: IsarType.long,
    )
  },
  estimateSize: _dailyScanAggregateEstimateSize,
  serialize: _dailyScanAggregateSerialize,
  deserialize: _dailyScanAggregateDeserialize,
  deserializeProp: _dailyScanAggregateDeserializeProp,
  idName: r'id',
  indexes: {
    r'date': IndexSchema(
      id: -7552997827385218417,
      name: r'date',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'date',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _dailyScanAggregateGetId,
  getLinks: _dailyScanAggregateGetLinks,
  attach: _dailyScanAggregateAttach,
  version: '3.1.0+1',
);

int _dailyScanAggregateEstimateSize(
  DailyScanAggregate object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.fishCounts.length * 3;
  {
    for (var i = 0; i < object.fishCounts.length; i++) {
      final value = object.fishCounts[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.topFishName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _dailyScanAggregateSerialize(
  DailyScanAggregate object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.date);
  writer.writeStringList(offsets[1], object.fishCounts);
  writer.writeString(offsets[2], object.topFishName);
  writer.writeLong(offsets[3], object.totalScans);
}

DailyScanAggregate _dailyScanAggregateDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DailyScanAggregate();
  object.date = reader.readDateTime(offsets[0]);
  object.fishCounts = reader.readStringList(offsets[1]) ?? [];
  object.id = id;
  object.topFishName = reader.readStringOrNull(offsets[2]);
  object.totalScans = reader.readLong(offsets[3]);
  return object;
}

P _dailyScanAggregateDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readStringList(offset) ?? []) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _dailyScanAggregateGetId(DailyScanAggregate object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _dailyScanAggregateGetLinks(
    DailyScanAggregate object) {
  return [];
}

void _dailyScanAggregateAttach(
    IsarCollection<dynamic> col, Id id, DailyScanAggregate object) {
  object.id = id;
}

extension DailyScanAggregateByIndex on IsarCollection<DailyScanAggregate> {
  Future<DailyScanAggregate?> getByDate(DateTime date) {
    return getByIndex(r'date', [date]);
  }

  DailyScanAggregate? getByDateSync(DateTime date) {
    return getByIndexSync(r'date', [date]);
  }

  Future<bool> deleteByDate(DateTime date) {
    return deleteByIndex(r'date', [date]);
  }

  bool deleteByDateSync(DateTime date) {
    return deleteByIndexSync(r'date', [date]);
  }

  Future<List<DailyScanAggregate?>> getAllByDate(List<DateTime> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return getAllByIndex(r'date', values);
  }

  List<DailyScanAggregate?> getAllByDateSync(List<DateTime> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'date', values);
  }

  Future<int> deleteAllByDate(List<DateTime> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'date', values);
  }

  int deleteAllByDateSync(List<DateTime> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'date', values);
  }

  Future<Id> putByDate(DailyScanAggregate object) {
    return putByIndex(r'date', object);
  }

  Id putByDateSync(DailyScanAggregate object, {bool saveLinks = true}) {
    return putByIndexSync(r'date', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByDate(List<DailyScanAggregate> objects) {
    return putAllByIndex(r'date', objects);
  }

  List<Id> putAllByDateSync(List<DailyScanAggregate> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'date', objects, saveLinks: saveLinks);
  }
}

extension DailyScanAggregateQueryWhereSort
    on QueryBuilder<DailyScanAggregate, DailyScanAggregate, QWhere> {
  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterWhere> anyDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'date'),
      );
    });
  }
}

extension DailyScanAggregateQueryWhere
    on QueryBuilder<DailyScanAggregate, DailyScanAggregate, QWhereClause> {
  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterWhereClause>
      dateEqualTo(DateTime date) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'date',
        value: [date],
      ));
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterWhereClause>
      dateNotEqualTo(DateTime date) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterWhereClause>
      dateGreaterThan(
    DateTime date, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [date],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterWhereClause>
      dateLessThan(
    DateTime date, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [],
        upper: [date],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterWhereClause>
      dateBetween(
    DateTime lowerDate,
    DateTime upperDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [lowerDate],
        includeLower: includeLower,
        upper: [upperDate],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DailyScanAggregateQueryFilter
    on QueryBuilder<DailyScanAggregate, DailyScanAggregate, QFilterCondition> {
  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      dateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      dateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      dateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      dateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'date',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      fishCountsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fishCounts',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      fishCountsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fishCounts',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      fishCountsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fishCounts',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      fishCountsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fishCounts',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      fishCountsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'fishCounts',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      fishCountsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'fishCounts',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      fishCountsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'fishCounts',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      fishCountsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'fishCounts',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      fishCountsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fishCounts',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      fishCountsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'fishCounts',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      fishCountsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'fishCounts',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      fishCountsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'fishCounts',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      fishCountsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'fishCounts',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      fishCountsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'fishCounts',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      fishCountsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'fishCounts',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      fishCountsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'fishCounts',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      topFishNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'topFishName',
      ));
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      topFishNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'topFishName',
      ));
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      topFishNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'topFishName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      topFishNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'topFishName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      topFishNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'topFishName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      topFishNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'topFishName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      topFishNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'topFishName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      topFishNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'topFishName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      topFishNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'topFishName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      topFishNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'topFishName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      topFishNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'topFishName',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      topFishNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'topFishName',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      totalScansEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalScans',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      totalScansGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalScans',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      totalScansLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalScans',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterFilterCondition>
      totalScansBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalScans',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DailyScanAggregateQueryObject
    on QueryBuilder<DailyScanAggregate, DailyScanAggregate, QFilterCondition> {}

extension DailyScanAggregateQueryLinks
    on QueryBuilder<DailyScanAggregate, DailyScanAggregate, QFilterCondition> {}

extension DailyScanAggregateQuerySortBy
    on QueryBuilder<DailyScanAggregate, DailyScanAggregate, QSortBy> {
  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterSortBy>
      sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterSortBy>
      sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterSortBy>
      sortByTopFishName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topFishName', Sort.asc);
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterSortBy>
      sortByTopFishNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topFishName', Sort.desc);
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterSortBy>
      sortByTotalScans() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalScans', Sort.asc);
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterSortBy>
      sortByTotalScansDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalScans', Sort.desc);
    });
  }
}

extension DailyScanAggregateQuerySortThenBy
    on QueryBuilder<DailyScanAggregate, DailyScanAggregate, QSortThenBy> {
  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterSortBy>
      thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterSortBy>
      thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterSortBy>
      thenByTopFishName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topFishName', Sort.asc);
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterSortBy>
      thenByTopFishNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topFishName', Sort.desc);
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterSortBy>
      thenByTotalScans() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalScans', Sort.asc);
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QAfterSortBy>
      thenByTotalScansDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalScans', Sort.desc);
    });
  }
}

extension DailyScanAggregateQueryWhereDistinct
    on QueryBuilder<DailyScanAggregate, DailyScanAggregate, QDistinct> {
  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QDistinct>
      distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QDistinct>
      distinctByFishCounts() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fishCounts');
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QDistinct>
      distinctByTopFishName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'topFishName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DailyScanAggregate, DailyScanAggregate, QDistinct>
      distinctByTotalScans() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalScans');
    });
  }
}

extension DailyScanAggregateQueryProperty
    on QueryBuilder<DailyScanAggregate, DailyScanAggregate, QQueryProperty> {
  QueryBuilder<DailyScanAggregate, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DailyScanAggregate, DateTime, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<DailyScanAggregate, List<String>, QQueryOperations>
      fishCountsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fishCounts');
    });
  }

  QueryBuilder<DailyScanAggregate, String?, QQueryOperations>
      topFishNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'topFishName');
    });
  }

  QueryBuilder<DailyScanAggregate, int, QQueryOperations> totalScansProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalScans');
    });
  }
}
