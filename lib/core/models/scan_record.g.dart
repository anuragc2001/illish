// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_record.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetScanRecordCollection on Isar {
  IsarCollection<ScanRecord> get scanRecords => this.collection();
}

const ScanRecordSchema = CollectionSchema(
  name: r'ScanRecord',
  id: -2239514724671306450,
  properties: {
    r'bestCuts': PropertySchema(
      id: 0,
      name: r'bestCuts',
      type: IsarType.stringList,
    ),
    r'englishName': PropertySchema(
      id: 1,
      name: r'englishName',
      type: IsarType.string,
    ),
    r'freshnessEvidence': PropertySchema(
      id: 2,
      name: r'freshnessEvidence',
      type: IsarType.string,
    ),
    r'freshnessScore': PropertySchema(
      id: 3,
      name: r'freshnessScore',
      type: IsarType.double,
    ),
    r'freshnessStatus': PropertySchema(
      id: 4,
      name: r'freshnessStatus',
      type: IsarType.string,
    ),
    r'idealFor': PropertySchema(
      id: 5,
      name: r'idealFor',
      type: IsarType.stringList,
    ),
    r'imagePath': PropertySchema(
      id: 6,
      name: r'imagePath',
      type: IsarType.string,
    ),
    r'isBookmark': PropertySchema(
      id: 7,
      name: r'isBookmark',
      type: IsarType.bool,
    ),
    r'isSynced': PropertySchema(
      id: 8,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'isUnlocked': PropertySchema(
      id: 9,
      name: r'isUnlocked',
      type: IsarType.bool,
    ),
    r'localName': PropertySchema(
      id: 10,
      name: r'localName',
      type: IsarType.string,
    ),
    r'marketAvgPrice': PropertySchema(
      id: 11,
      name: r'marketAvgPrice',
      type: IsarType.string,
    ),
    r'region': PropertySchema(
      id: 12,
      name: r'region',
      type: IsarType.string,
    ),
    r'suggestedPrice': PropertySchema(
      id: 13,
      name: r'suggestedPrice',
      type: IsarType.string,
    ),
    r'timestamp': PropertySchema(
      id: 14,
      name: r'timestamp',
      type: IsarType.dateTime,
    ),
    r'trickeryTips': PropertySchema(
      id: 15,
      name: r'trickeryTips',
      type: IsarType.stringList,
    )
  },
  estimateSize: _scanRecordEstimateSize,
  serialize: _scanRecordSerialize,
  deserialize: _scanRecordDeserialize,
  deserializeProp: _scanRecordDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _scanRecordGetId,
  getLinks: _scanRecordGetLinks,
  attach: _scanRecordAttach,
  version: '3.1.0+1',
);

int _scanRecordEstimateSize(
  ScanRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.bestCuts.length * 3;
  {
    for (var i = 0; i < object.bestCuts.length; i++) {
      final value = object.bestCuts[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.englishName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.freshnessEvidence;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.freshnessStatus;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.idealFor.length * 3;
  {
    for (var i = 0; i < object.idealFor.length; i++) {
      final value = object.idealFor[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.imagePath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.localName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.marketAvgPrice;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.region;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.suggestedPrice;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.trickeryTips.length * 3;
  {
    for (var i = 0; i < object.trickeryTips.length; i++) {
      final value = object.trickeryTips[i];
      bytesCount += value.length * 3;
    }
  }
  return bytesCount;
}

void _scanRecordSerialize(
  ScanRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeStringList(offsets[0], object.bestCuts);
  writer.writeString(offsets[1], object.englishName);
  writer.writeString(offsets[2], object.freshnessEvidence);
  writer.writeDouble(offsets[3], object.freshnessScore);
  writer.writeString(offsets[4], object.freshnessStatus);
  writer.writeStringList(offsets[5], object.idealFor);
  writer.writeString(offsets[6], object.imagePath);
  writer.writeBool(offsets[7], object.isBookmark);
  writer.writeBool(offsets[8], object.isSynced);
  writer.writeBool(offsets[9], object.isUnlocked);
  writer.writeString(offsets[10], object.localName);
  writer.writeString(offsets[11], object.marketAvgPrice);
  writer.writeString(offsets[12], object.region);
  writer.writeString(offsets[13], object.suggestedPrice);
  writer.writeDateTime(offsets[14], object.timestamp);
  writer.writeStringList(offsets[15], object.trickeryTips);
}

ScanRecord _scanRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ScanRecord();
  object.bestCuts = reader.readStringList(offsets[0]) ?? [];
  object.englishName = reader.readStringOrNull(offsets[1]);
  object.freshnessEvidence = reader.readStringOrNull(offsets[2]);
  object.freshnessScore = reader.readDoubleOrNull(offsets[3]);
  object.freshnessStatus = reader.readStringOrNull(offsets[4]);
  object.id = id;
  object.idealFor = reader.readStringList(offsets[5]) ?? [];
  object.imagePath = reader.readStringOrNull(offsets[6]);
  object.isBookmark = reader.readBool(offsets[7]);
  object.isSynced = reader.readBool(offsets[8]);
  object.isUnlocked = reader.readBool(offsets[9]);
  object.localName = reader.readStringOrNull(offsets[10]);
  object.marketAvgPrice = reader.readStringOrNull(offsets[11]);
  object.region = reader.readStringOrNull(offsets[12]);
  object.suggestedPrice = reader.readStringOrNull(offsets[13]);
  object.timestamp = reader.readDateTime(offsets[14]);
  object.trickeryTips = reader.readStringList(offsets[15]) ?? [];
  return object;
}

P _scanRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringList(offset) ?? []) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readDoubleOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringList(offset) ?? []) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readDateTime(offset)) as P;
    case 15:
      return (reader.readStringList(offset) ?? []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _scanRecordGetId(ScanRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _scanRecordGetLinks(ScanRecord object) {
  return [];
}

void _scanRecordAttach(IsarCollection<dynamic> col, Id id, ScanRecord object) {
  object.id = id;
}

extension ScanRecordQueryWhereSort
    on QueryBuilder<ScanRecord, ScanRecord, QWhere> {
  QueryBuilder<ScanRecord, ScanRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ScanRecordQueryWhere
    on QueryBuilder<ScanRecord, ScanRecord, QWhereClause> {
  QueryBuilder<ScanRecord, ScanRecord, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<ScanRecord, ScanRecord, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterWhereClause> idBetween(
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
}

extension ScanRecordQueryFilter
    on QueryBuilder<ScanRecord, ScanRecord, QFilterCondition> {
  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      bestCutsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bestCuts',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      bestCutsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bestCuts',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      bestCutsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bestCuts',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      bestCutsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bestCuts',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      bestCutsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'bestCuts',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      bestCutsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'bestCuts',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      bestCutsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'bestCuts',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      bestCutsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'bestCuts',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      bestCutsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bestCuts',
        value: '',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      bestCutsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'bestCuts',
        value: '',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      bestCutsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'bestCuts',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      bestCutsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'bestCuts',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      bestCutsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'bestCuts',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      bestCutsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'bestCuts',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      bestCutsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'bestCuts',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      bestCutsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'bestCuts',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      englishNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'englishName',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      englishNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'englishName',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      englishNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'englishName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      englishNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'englishName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      englishNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'englishName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      englishNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'englishName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      englishNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'englishName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      englishNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'englishName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      englishNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'englishName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      englishNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'englishName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      englishNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'englishName',
        value: '',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      englishNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'englishName',
        value: '',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      freshnessEvidenceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'freshnessEvidence',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      freshnessEvidenceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'freshnessEvidence',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      freshnessEvidenceEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'freshnessEvidence',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      freshnessEvidenceGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'freshnessEvidence',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      freshnessEvidenceLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'freshnessEvidence',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      freshnessEvidenceBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'freshnessEvidence',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      freshnessEvidenceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'freshnessEvidence',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      freshnessEvidenceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'freshnessEvidence',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      freshnessEvidenceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'freshnessEvidence',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      freshnessEvidenceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'freshnessEvidence',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      freshnessEvidenceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'freshnessEvidence',
        value: '',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      freshnessEvidenceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'freshnessEvidence',
        value: '',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      freshnessScoreIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'freshnessScore',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      freshnessScoreIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'freshnessScore',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      freshnessScoreEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'freshnessScore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      freshnessScoreGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'freshnessScore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      freshnessScoreLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'freshnessScore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      freshnessScoreBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'freshnessScore',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      freshnessStatusIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'freshnessStatus',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      freshnessStatusIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'freshnessStatus',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      freshnessStatusEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'freshnessStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      freshnessStatusGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'freshnessStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      freshnessStatusLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'freshnessStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      freshnessStatusBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'freshnessStatus',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      freshnessStatusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'freshnessStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      freshnessStatusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'freshnessStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      freshnessStatusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'freshnessStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      freshnessStatusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'freshnessStatus',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      freshnessStatusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'freshnessStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      freshnessStatusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'freshnessStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition> idBetween(
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

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      idealForElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idealFor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      idealForElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'idealFor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      idealForElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'idealFor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      idealForElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'idealFor',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      idealForElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'idealFor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      idealForElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'idealFor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      idealForElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'idealFor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      idealForElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'idealFor',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      idealForElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idealFor',
        value: '',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      idealForElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'idealFor',
        value: '',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      idealForLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'idealFor',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      idealForIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'idealFor',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      idealForIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'idealFor',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      idealForLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'idealFor',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      idealForLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'idealFor',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      idealForLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'idealFor',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      imagePathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'imagePath',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      imagePathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'imagePath',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition> imagePathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      imagePathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition> imagePathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition> imagePathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'imagePath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      imagePathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition> imagePathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition> imagePathContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition> imagePathMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'imagePath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      imagePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imagePath',
        value: '',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      imagePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'imagePath',
        value: '',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition> isBookmarkEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isBookmark',
        value: value,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition> isSyncedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition> isUnlockedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isUnlocked',
        value: value,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      localNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'localName',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      localNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'localName',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition> localNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      localNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'localName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition> localNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'localName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition> localNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'localName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      localNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'localName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition> localNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'localName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition> localNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'localName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition> localNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'localName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      localNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localName',
        value: '',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      localNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'localName',
        value: '',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      marketAvgPriceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'marketAvgPrice',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      marketAvgPriceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'marketAvgPrice',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      marketAvgPriceEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'marketAvgPrice',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      marketAvgPriceGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'marketAvgPrice',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      marketAvgPriceLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'marketAvgPrice',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      marketAvgPriceBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'marketAvgPrice',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      marketAvgPriceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'marketAvgPrice',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      marketAvgPriceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'marketAvgPrice',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      marketAvgPriceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'marketAvgPrice',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      marketAvgPriceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'marketAvgPrice',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      marketAvgPriceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'marketAvgPrice',
        value: '',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      marketAvgPriceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'marketAvgPrice',
        value: '',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition> regionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'region',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      regionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'region',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition> regionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'region',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition> regionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'region',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition> regionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'region',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition> regionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'region',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition> regionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'region',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition> regionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'region',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition> regionContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'region',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition> regionMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'region',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition> regionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'region',
        value: '',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      regionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'region',
        value: '',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      suggestedPriceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'suggestedPrice',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      suggestedPriceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'suggestedPrice',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      suggestedPriceEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'suggestedPrice',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      suggestedPriceGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'suggestedPrice',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      suggestedPriceLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'suggestedPrice',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      suggestedPriceBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'suggestedPrice',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      suggestedPriceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'suggestedPrice',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      suggestedPriceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'suggestedPrice',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      suggestedPriceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'suggestedPrice',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      suggestedPriceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'suggestedPrice',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      suggestedPriceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'suggestedPrice',
        value: '',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      suggestedPriceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'suggestedPrice',
        value: '',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition> timestampEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      timestampGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition> timestampLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition> timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      trickeryTipsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'trickeryTips',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      trickeryTipsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'trickeryTips',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      trickeryTipsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'trickeryTips',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      trickeryTipsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'trickeryTips',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      trickeryTipsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'trickeryTips',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      trickeryTipsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'trickeryTips',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      trickeryTipsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'trickeryTips',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      trickeryTipsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'trickeryTips',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      trickeryTipsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'trickeryTips',
        value: '',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      trickeryTipsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'trickeryTips',
        value: '',
      ));
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      trickeryTipsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'trickeryTips',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      trickeryTipsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'trickeryTips',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      trickeryTipsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'trickeryTips',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      trickeryTipsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'trickeryTips',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      trickeryTipsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'trickeryTips',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterFilterCondition>
      trickeryTipsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'trickeryTips',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension ScanRecordQueryObject
    on QueryBuilder<ScanRecord, ScanRecord, QFilterCondition> {}

extension ScanRecordQueryLinks
    on QueryBuilder<ScanRecord, ScanRecord, QFilterCondition> {}

extension ScanRecordQuerySortBy
    on QueryBuilder<ScanRecord, ScanRecord, QSortBy> {
  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> sortByEnglishName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'englishName', Sort.asc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> sortByEnglishNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'englishName', Sort.desc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> sortByFreshnessEvidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'freshnessEvidence', Sort.asc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy>
      sortByFreshnessEvidenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'freshnessEvidence', Sort.desc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> sortByFreshnessScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'freshnessScore', Sort.asc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy>
      sortByFreshnessScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'freshnessScore', Sort.desc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> sortByFreshnessStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'freshnessStatus', Sort.asc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy>
      sortByFreshnessStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'freshnessStatus', Sort.desc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> sortByImagePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.asc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> sortByImagePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.desc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> sortByIsBookmark() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isBookmark', Sort.asc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> sortByIsBookmarkDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isBookmark', Sort.desc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> sortByIsUnlocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUnlocked', Sort.asc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> sortByIsUnlockedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUnlocked', Sort.desc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> sortByLocalName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localName', Sort.asc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> sortByLocalNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localName', Sort.desc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> sortByMarketAvgPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'marketAvgPrice', Sort.asc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy>
      sortByMarketAvgPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'marketAvgPrice', Sort.desc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> sortByRegion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'region', Sort.asc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> sortByRegionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'region', Sort.desc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> sortBySuggestedPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'suggestedPrice', Sort.asc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy>
      sortBySuggestedPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'suggestedPrice', Sort.desc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension ScanRecordQuerySortThenBy
    on QueryBuilder<ScanRecord, ScanRecord, QSortThenBy> {
  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> thenByEnglishName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'englishName', Sort.asc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> thenByEnglishNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'englishName', Sort.desc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> thenByFreshnessEvidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'freshnessEvidence', Sort.asc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy>
      thenByFreshnessEvidenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'freshnessEvidence', Sort.desc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> thenByFreshnessScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'freshnessScore', Sort.asc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy>
      thenByFreshnessScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'freshnessScore', Sort.desc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> thenByFreshnessStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'freshnessStatus', Sort.asc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy>
      thenByFreshnessStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'freshnessStatus', Sort.desc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> thenByImagePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.asc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> thenByImagePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.desc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> thenByIsBookmark() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isBookmark', Sort.asc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> thenByIsBookmarkDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isBookmark', Sort.desc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> thenByIsUnlocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUnlocked', Sort.asc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> thenByIsUnlockedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUnlocked', Sort.desc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> thenByLocalName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localName', Sort.asc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> thenByLocalNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localName', Sort.desc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> thenByMarketAvgPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'marketAvgPrice', Sort.asc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy>
      thenByMarketAvgPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'marketAvgPrice', Sort.desc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> thenByRegion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'region', Sort.asc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> thenByRegionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'region', Sort.desc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> thenBySuggestedPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'suggestedPrice', Sort.asc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy>
      thenBySuggestedPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'suggestedPrice', Sort.desc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QAfterSortBy> thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension ScanRecordQueryWhereDistinct
    on QueryBuilder<ScanRecord, ScanRecord, QDistinct> {
  QueryBuilder<ScanRecord, ScanRecord, QDistinct> distinctByBestCuts() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bestCuts');
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QDistinct> distinctByEnglishName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'englishName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QDistinct> distinctByFreshnessEvidence(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'freshnessEvidence',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QDistinct> distinctByFreshnessScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'freshnessScore');
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QDistinct> distinctByFreshnessStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'freshnessStatus',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QDistinct> distinctByIdealFor() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'idealFor');
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QDistinct> distinctByImagePath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'imagePath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QDistinct> distinctByIsBookmark() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isBookmark');
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QDistinct> distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QDistinct> distinctByIsUnlocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isUnlocked');
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QDistinct> distinctByLocalName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QDistinct> distinctByMarketAvgPrice(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'marketAvgPrice',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QDistinct> distinctByRegion(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'region', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QDistinct> distinctBySuggestedPrice(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'suggestedPrice',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QDistinct> distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }

  QueryBuilder<ScanRecord, ScanRecord, QDistinct> distinctByTrickeryTips() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'trickeryTips');
    });
  }
}

extension ScanRecordQueryProperty
    on QueryBuilder<ScanRecord, ScanRecord, QQueryProperty> {
  QueryBuilder<ScanRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ScanRecord, List<String>, QQueryOperations> bestCutsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bestCuts');
    });
  }

  QueryBuilder<ScanRecord, String?, QQueryOperations> englishNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'englishName');
    });
  }

  QueryBuilder<ScanRecord, String?, QQueryOperations>
      freshnessEvidenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'freshnessEvidence');
    });
  }

  QueryBuilder<ScanRecord, double?, QQueryOperations> freshnessScoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'freshnessScore');
    });
  }

  QueryBuilder<ScanRecord, String?, QQueryOperations>
      freshnessStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'freshnessStatus');
    });
  }

  QueryBuilder<ScanRecord, List<String>, QQueryOperations> idealForProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'idealFor');
    });
  }

  QueryBuilder<ScanRecord, String?, QQueryOperations> imagePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'imagePath');
    });
  }

  QueryBuilder<ScanRecord, bool, QQueryOperations> isBookmarkProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isBookmark');
    });
  }

  QueryBuilder<ScanRecord, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<ScanRecord, bool, QQueryOperations> isUnlockedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isUnlocked');
    });
  }

  QueryBuilder<ScanRecord, String?, QQueryOperations> localNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localName');
    });
  }

  QueryBuilder<ScanRecord, String?, QQueryOperations> marketAvgPriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'marketAvgPrice');
    });
  }

  QueryBuilder<ScanRecord, String?, QQueryOperations> regionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'region');
    });
  }

  QueryBuilder<ScanRecord, String?, QQueryOperations> suggestedPriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'suggestedPrice');
    });
  }

  QueryBuilder<ScanRecord, DateTime, QQueryOperations> timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }

  QueryBuilder<ScanRecord, List<String>, QQueryOperations>
      trickeryTipsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'trickeryTips');
    });
  }
}
