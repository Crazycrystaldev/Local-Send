// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element

part of 'apk_provider_param.dart';

class ApkProviderParamMapper extends ClassMapperBase<ApkProviderParam> {
  ApkProviderParamMapper._();

  static ApkProviderParamMapper? _instance;
  static ApkProviderParamMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ApkProviderParamMapper._());
    }
    return _instance!;
  }

  static T _guard<T>(T Function(MapperContainer) fn) {
    ensureInitialized();
    return fn(MapperContainer.globals);
  }

  @override
  final String id = 'ApkProviderParam';

  static String _$query(ApkProviderParam v) => v.query;
  static const Field<ApkProviderParam, String> _f$query =
      Field('query', _$query);
  static bool _$includeSystemApps(ApkProviderParam v) => v.includeSystemApps;
  static const Field<ApkProviderParam, bool> _f$includeSystemApps =
      Field('includeSystemApps', _$includeSystemApps);
  static bool _$onlyAppsWithLaunchIntent(ApkProviderParam v) =>
      v.onlyAppsWithLaunchIntent;
  static const Field<ApkProviderParam, bool> _f$onlyAppsWithLaunchIntent =
      Field('onlyAppsWithLaunchIntent', _$onlyAppsWithLaunchIntent);

  @override
  final Map<Symbol, Field<ApkProviderParam, dynamic>> fields = const {
    #query: _f$query,
    #includeSystemApps: _f$includeSystemApps,
    #onlyAppsWithLaunchIntent: _f$onlyAppsWithLaunchIntent,
  };

  static ApkProviderParam _instantiate(DecodingData data) {
    return ApkProviderParam(
        query: data.dec(_f$query),
        includeSystemApps: data.dec(_f$includeSystemApps),
        onlyAppsWithLaunchIntent: data.dec(_f$onlyAppsWithLaunchIntent));
  }

  @override
  final Function instantiate = _instantiate;

  static ApkProviderParam fromJson(Map<String, dynamic> map) {
    return _guard((c) => c.fromMap<ApkProviderParam>(map));
  }

  static ApkProviderParam deserialize(String json) {
    return _guard((c) => c.fromJson<ApkProviderParam>(json));
  }
}

mixin ApkProviderParamMappable {
  String serialize() {
    return ApkProviderParamMapper._guard(
        (c) => c.toJson(this as ApkProviderParam));
  }

  Map<String, dynamic> toJson() {
    return ApkProviderParamMapper._guard(
        (c) => c.toMap(this as ApkProviderParam));
  }

  ApkProviderParamCopyWith<ApkProviderParam, ApkProviderParam, ApkProviderParam>
      get copyWith => _ApkProviderParamCopyWithImpl(
          this as ApkProviderParam, $identity, $identity);
  @override
  String toString() {
    return ApkProviderParamMapper._guard((c) => c.asString(this));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (runtimeType == other.runtimeType &&
            ApkProviderParamMapper._guard((c) => c.isEqual(this, other)));
  }

  @override
  int get hashCode {
    return ApkProviderParamMapper._guard((c) => c.hash(this));
  }
}

extension ApkProviderParamValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ApkProviderParam, $Out> {
  ApkProviderParamCopyWith<$R, ApkProviderParam, $Out>
      get $asApkProviderParam =>
          $base.as((v, t, t2) => _ApkProviderParamCopyWithImpl(v, t, t2));
}

abstract class ApkProviderParamCopyWith<$R, $In extends ApkProviderParam, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call(
      {String? query, bool? includeSystemApps, bool? onlyAppsWithLaunchIntent});
  ApkProviderParamCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _ApkProviderParamCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ApkProviderParam, $Out>
    implements ApkProviderParamCopyWith<$R, ApkProviderParam, $Out> {
  _ApkProviderParamCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ApkProviderParam> $mapper =
      ApkProviderParamMapper.ensureInitialized();
  @override
  $R call(
          {String? query,
          bool? includeSystemApps,
          bool? onlyAppsWithLaunchIntent}) =>
      $apply(FieldCopyWithData({
        if (query != null) #query: query,
        if (includeSystemApps != null) #includeSystemApps: includeSystemApps,
        if (onlyAppsWithLaunchIntent != null)
          #onlyAppsWithLaunchIntent: onlyAppsWithLaunchIntent
      }));
  @override
  ApkProviderParam $make(CopyWithData data) => ApkProviderParam(
      query: data.get(#query, or: $value.query),
      includeSystemApps:
          data.get(#includeSystemApps, or: $value.includeSystemApps),
      onlyAppsWithLaunchIntent: data.get(#onlyAppsWithLaunchIntent,
          or: $value.onlyAppsWithLaunchIntent));

  @override
  ApkProviderParamCopyWith<$R2, ApkProviderParam, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _ApkProviderParamCopyWithImpl($value, $cast, t);
}
