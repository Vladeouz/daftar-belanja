import 'package:equatable/equatable.dart';

import 'package:app/core/error/failure.dart';

/// Hasil operasi yang bisa gagal: [Ok] berisi nilai, [Err] berisi [Failure].
///
/// Use case dan repository mengembalikan `Result<T>` alih-alih melempar exception.
sealed class Result<T> extends Equatable {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;

  @override
  List<Object?> get props => [value];
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
