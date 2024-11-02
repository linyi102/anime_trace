import 'dart:io';

T? systemWhen<T>({
  String? system,
  T Function()? android,
  T Function()? fuchsia,
  T Function()? ios,
  T Function()? linux,
  T Function()? macos,
  T Function()? windows,
}) {
  switch (system ?? Platform.operatingSystem) {
    case 'android':
      return android?.call();
    case 'fuchsia':
      return fuchsia?.call();
    case 'ios':
      return ios?.call();
    case 'linux':
      return linux?.call();
    case 'macos':
      return macos?.call();
    case 'windows':
      return windows?.call();
    default:
      return null;
  }
}
