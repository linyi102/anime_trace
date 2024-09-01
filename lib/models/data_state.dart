class DataState<T> {
  final T? value;
  final Object? error;
  final StackTrace? stackTrace;
  final bool isLoading;
  final String? message;

  const DataState._({
    this.value,
    this.error,
    this.stackTrace,
    this.isLoading = false,
    this.message,
  });

  factory DataState.data(
    T data, {
    String? message,
  }) {
    return DataState._(
      value: data,
      message: message,
    );
  }

  factory DataState.error({
    required Object error,
    required StackTrace stackTrace,
    String? message,
  }) {
    return DataState._(
      error: error,
      stackTrace: stackTrace,
      message: message,
    );
  }

  factory DataState.loading({
    String? message,
  }) {
    return DataState._(
      isLoading: true,
      message: message,
    );
  }

  @Deprecated('不推荐使用，因为手动传入null并不会清空数据')
  DataState<T> copyWith({
    T? value,
    Object? error,
    StackTrace? stackTrace,
    String? message,
    bool? isLoading,
  }) {
    return DataState._(
      value: value ?? this.value,
      error: error ?? this.error,
      stackTrace: stackTrace ?? this.stackTrace,
      message: message ?? this.message,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

extension DataStateX<T> on DataState<T> {
  bool get hasValue => value != null;

  T get requireValue => value!;

  bool get hasError => error != null && stackTrace != null;

  DataState<T> toData(
    T data, {
    String? message,
  }) {
    return DataState.data(
      data,
      message: message,
    );
  }

  DataState<T> toLoadMore<S>(List<S> data) {
    if (value != null && value is! List<S>) {
      throw Exception('Fail to loadMore: DataState value is not List');
    }

    List<S> newList = [
      ...value == null ? [] : value as List,
      ...data,
    ].cast<S>();
    return DataState.data(newList as T);
  }

  DataState<T> toLoading({
    String? message,
    bool resetData = false,
    bool resetError = true,
  }) {
    return DataState._(
      value: resetData ? null : value,
      error: resetError ? null : error,
      stackTrace: resetError ? null : stackTrace,
      isLoading: true,
      message: message,
    );
  }

  DataState<T> toError({
    required Object error,
    required StackTrace stackTrace,
    String? message,
    bool resetData = false,
  }) {
    return DataState._(
      value: resetData ? null : value,
      error: error,
      stackTrace: stackTrace,
      isLoading: false,
      message: message,
    );
  }

  /// - [skipLoading] 为 true 时，加载时若 [hasValue] 为 true，则不调用 [loading]
  ///   如果在某种情况下不想跳过，可以使用 [DataState.loading]，或使用 [toLoading] 并指定 resetData 为 true
  /// - [skipError] 为 true 时，错误时若 [hasValue] 为 true，则不调用 [error]
  R when<R>({
    required R Function(T data) data,
    required R Function(Object error, StackTrace stackTrace, String? message)
        error,
    required R Function(String? message) loading,
    bool skipLoading = true,
    bool skipError = true,
  }) {
    if (isLoading && !(hasValue && skipLoading)) {
      return loading(message);
    }
    if (hasError && !(hasValue && skipError)) {
      return error(this.error!, stackTrace!, message);
    }
    if (hasValue) return data(value as T);
    throw Exception('DataState没有与之对应的状态');
  }
}
