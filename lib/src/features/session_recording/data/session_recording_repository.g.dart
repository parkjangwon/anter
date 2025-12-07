// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_recording_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sessionRecordingRepository)
const sessionRecordingRepositoryProvider =
    SessionRecordingRepositoryProvider._();

final class SessionRecordingRepositoryProvider
    extends
        $FunctionalProvider<
          SessionRecordingRepository,
          SessionRecordingRepository,
          SessionRecordingRepository
        >
    with $Provider<SessionRecordingRepository> {
  const SessionRecordingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionRecordingRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionRecordingRepositoryHash();

  @$internal
  @override
  $ProviderElement<SessionRecordingRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SessionRecordingRepository create(Ref ref) {
    return sessionRecordingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionRecordingRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionRecordingRepository>(value),
    );
  }
}

String _$sessionRecordingRepositoryHash() =>
    r'd17a701d92429abb5e6cbb430ee844374421a4e9';
