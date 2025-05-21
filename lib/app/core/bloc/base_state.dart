import 'package:equatable/equatable.dart';
import '../errors/app_error.dart';

enum Status {
  initial,
  loading,
  loaded,
  error,
}

abstract class BaseState extends Equatable {
  final Status status;
  final AppError? error;

  const BaseState({
    this.status = Status.initial,
    this.error,
  });

  bool get isInitial => status == Status.initial;
  bool get isLoading => status == Status.loading;
  bool get isLoaded => status == Status.loaded;
  bool get hasError => status == Status.error;

  @override
  List<Object?> get props => [status, error];
}
