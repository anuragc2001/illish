// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_cache.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetRecipeCacheCollection on Isar {
  IsarCollection<RecipeCache> get recipeCaches => this.collection();
}

const RecipeCacheSchema = CollectionSchema(
  name: r'RecipeCache',
  id: 284255633800301217,
  properties: {
    r'cachedJsonData': PropertySchema(
      id: 0,
      name: r'cachedJsonData',
      type: IsarType.string,
    ),
    r'lastUpdated': PropertySchema(
      id: 1,
      name: r'lastUpdated',
      type: IsarType.dateTime,
    ),
    r'speciesQuery': PropertySchema(
      id: 2,
      name: r'speciesQuery',
      type: IsarType.string,
    )
  },
  estimateSize: _recipeCacheEstimateSize,
  serialize: _recipeCacheSerialize,
  deserialize: _recipeCacheDeserialize,
  deserializeProp: _recipeCacheDeserializeProp,
  idName: r'id',
  indexes: {
    r'speciesQuery': IndexSchema(
      id: 5285319487363255991,
      name: r'speciesQuery',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'speciesQuery',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _recipeCacheGetId,
  getLinks: _recipeCacheGetLinks,
  attach: _recipeCacheAttach,
  version: '3.1.0+1',
);

int _recipeCacheEstimateSize(
  RecipeCache object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.cachedJsonData.length * 3;
  bytesCount += 3 + object.speciesQuery.length * 3;
  return bytesCount;
}

void _recipeCacheSerialize(
  RecipeCache object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.cachedJsonData);
  writer.writeDateTime(offsets[1], object.lastUpdated);
  writer.writeString(offsets[2], object.speciesQuery);
}

RecipeCache _recipeCacheDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = RecipeCache();
  object.cachedJsonData = reader.readString(offsets[0]);
  object.id = id;
  object.lastUpdated = reader.readDateTime(offsets[1]);
  object.speciesQuery = reader.readString(offsets[2]);
  return object;
}

P _recipeCacheDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _recipeCacheGetId(RecipeCache object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _recipeCacheGetLinks(RecipeCache object) {
  return [];
}

void _recipeCacheAttach(
    IsarCollection<dynamic> col, Id id, RecipeCache object) {
  object.id = id;
}

extension RecipeCacheByIndex on IsarCollection<RecipeCache> {
  Future<RecipeCache?> getBySpeciesQuery(String speciesQuery) {
    return getByIndex(r'speciesQuery', [speciesQuery]);
  }

  RecipeCache? getBySpeciesQuerySync(String speciesQuery) {
    return getByIndexSync(r'speciesQuery', [speciesQuery]);
  }

  Future<bool> deleteBySpeciesQuery(String speciesQuery) {
    return deleteByIndex(r'speciesQuery', [speciesQuery]);
  }

  bool deleteBySpeciesQuerySync(String speciesQuery) {
    return deleteByIndexSync(r'speciesQuery', [speciesQuery]);
  }

  Future<List<RecipeCache?>> getAllBySpeciesQuery(
      List<String> speciesQueryValues) {
    final values = speciesQueryValues.map((e) => [e]).toList();
    return getAllByIndex(r'speciesQuery', values);
  }

  List<RecipeCache?> getAllBySpeciesQuerySync(List<String> speciesQueryValues) {
    final values = speciesQueryValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'speciesQuery', values);
  }

  Future<int> deleteAllBySpeciesQuery(List<String> speciesQueryValues) {
    final values = speciesQueryValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'speciesQuery', values);
  }

  int deleteAllBySpeciesQuerySync(List<String> speciesQueryValues) {
    final values = speciesQueryValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'speciesQuery', values);
  }

  Future<Id> putBySpeciesQuery(RecipeCache object) {
    return putByIndex(r'speciesQuery', object);
  }

  Id putBySpeciesQuerySync(RecipeCache object, {bool saveLinks = true}) {
    return putByIndexSync(r'speciesQuery', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllBySpeciesQuery(List<RecipeCache> objects) {
    return putAllByIndex(r'speciesQuery', objects);
  }

  List<Id> putAllBySpeciesQuerySync(List<RecipeCache> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'speciesQuery', objects, saveLinks: saveLinks);
  }
}

extension RecipeCacheQueryWhereSort
    on QueryBuilder<RecipeCache, RecipeCache, QWhere> {
  QueryBuilder<RecipeCache, RecipeCache, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension RecipeCacheQueryWhere
    on QueryBuilder<RecipeCache, RecipeCache, QWhereClause> {
  QueryBuilder<RecipeCache, RecipeCache, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<RecipeCache, RecipeCache, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterWhereClause> idBetween(
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

  QueryBuilder<RecipeCache, RecipeCache, QAfterWhereClause> speciesQueryEqualTo(
      String speciesQuery) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'speciesQuery',
        value: [speciesQuery],
      ));
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterWhereClause>
      speciesQueryNotEqualTo(String speciesQuery) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'speciesQuery',
              lower: [],
              upper: [speciesQuery],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'speciesQuery',
              lower: [speciesQuery],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'speciesQuery',
              lower: [speciesQuery],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'speciesQuery',
              lower: [],
              upper: [speciesQuery],
              includeUpper: false,
            ));
      }
    });
  }
}

extension RecipeCacheQueryFilter
    on QueryBuilder<RecipeCache, RecipeCache, QFilterCondition> {
  QueryBuilder<RecipeCache, RecipeCache, QAfterFilterCondition>
      cachedJsonDataEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cachedJsonData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterFilterCondition>
      cachedJsonDataGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cachedJsonData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterFilterCondition>
      cachedJsonDataLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cachedJsonData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterFilterCondition>
      cachedJsonDataBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cachedJsonData',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterFilterCondition>
      cachedJsonDataStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cachedJsonData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterFilterCondition>
      cachedJsonDataEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cachedJsonData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterFilterCondition>
      cachedJsonDataContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cachedJsonData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterFilterCondition>
      cachedJsonDataMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cachedJsonData',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterFilterCondition>
      cachedJsonDataIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cachedJsonData',
        value: '',
      ));
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterFilterCondition>
      cachedJsonDataIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cachedJsonData',
        value: '',
      ));
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<RecipeCache, RecipeCache, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<RecipeCache, RecipeCache, QAfterFilterCondition> idBetween(
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

  QueryBuilder<RecipeCache, RecipeCache, QAfterFilterCondition>
      lastUpdatedEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastUpdated',
        value: value,
      ));
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterFilterCondition>
      lastUpdatedGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastUpdated',
        value: value,
      ));
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterFilterCondition>
      lastUpdatedLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastUpdated',
        value: value,
      ));
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterFilterCondition>
      lastUpdatedBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastUpdated',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterFilterCondition>
      speciesQueryEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'speciesQuery',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterFilterCondition>
      speciesQueryGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'speciesQuery',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterFilterCondition>
      speciesQueryLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'speciesQuery',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterFilterCondition>
      speciesQueryBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'speciesQuery',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterFilterCondition>
      speciesQueryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'speciesQuery',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterFilterCondition>
      speciesQueryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'speciesQuery',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterFilterCondition>
      speciesQueryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'speciesQuery',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterFilterCondition>
      speciesQueryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'speciesQuery',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterFilterCondition>
      speciesQueryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'speciesQuery',
        value: '',
      ));
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterFilterCondition>
      speciesQueryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'speciesQuery',
        value: '',
      ));
    });
  }
}

extension RecipeCacheQueryObject
    on QueryBuilder<RecipeCache, RecipeCache, QFilterCondition> {}

extension RecipeCacheQueryLinks
    on QueryBuilder<RecipeCache, RecipeCache, QFilterCondition> {}

extension RecipeCacheQuerySortBy
    on QueryBuilder<RecipeCache, RecipeCache, QSortBy> {
  QueryBuilder<RecipeCache, RecipeCache, QAfterSortBy> sortByCachedJsonData() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedJsonData', Sort.asc);
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterSortBy>
      sortByCachedJsonDataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedJsonData', Sort.desc);
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterSortBy> sortByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.asc);
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterSortBy> sortByLastUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.desc);
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterSortBy> sortBySpeciesQuery() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speciesQuery', Sort.asc);
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterSortBy>
      sortBySpeciesQueryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speciesQuery', Sort.desc);
    });
  }
}

extension RecipeCacheQuerySortThenBy
    on QueryBuilder<RecipeCache, RecipeCache, QSortThenBy> {
  QueryBuilder<RecipeCache, RecipeCache, QAfterSortBy> thenByCachedJsonData() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedJsonData', Sort.asc);
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterSortBy>
      thenByCachedJsonDataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedJsonData', Sort.desc);
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterSortBy> thenByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.asc);
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterSortBy> thenByLastUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.desc);
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterSortBy> thenBySpeciesQuery() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speciesQuery', Sort.asc);
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QAfterSortBy>
      thenBySpeciesQueryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speciesQuery', Sort.desc);
    });
  }
}

extension RecipeCacheQueryWhereDistinct
    on QueryBuilder<RecipeCache, RecipeCache, QDistinct> {
  QueryBuilder<RecipeCache, RecipeCache, QDistinct> distinctByCachedJsonData(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cachedJsonData',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QDistinct> distinctByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastUpdated');
    });
  }

  QueryBuilder<RecipeCache, RecipeCache, QDistinct> distinctBySpeciesQuery(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'speciesQuery', caseSensitive: caseSensitive);
    });
  }
}

extension RecipeCacheQueryProperty
    on QueryBuilder<RecipeCache, RecipeCache, QQueryProperty> {
  QueryBuilder<RecipeCache, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<RecipeCache, String, QQueryOperations> cachedJsonDataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cachedJsonData');
    });
  }

  QueryBuilder<RecipeCache, DateTime, QQueryOperations> lastUpdatedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUpdated');
    });
  }

  QueryBuilder<RecipeCache, String, QQueryOperations> speciesQueryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'speciesQuery');
    });
  }
}
