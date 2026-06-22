import 'onmu_exception.dart';

enum OnmuErrorPresentation {
  silent,
  snackbar,
  inline,
  fullScreen,
  retryableCard,
}

enum OnmuErrorUiContext { initialLoad, mutation, optionalBackground }

class OnmuUiError {
  const OnmuUiError({
    required this.message,
    required this.presentation,
    required this.canRetry,
  });

  final String message;
  final OnmuErrorPresentation presentation;
  final bool canRetry;

  factory OnmuUiError.fromException(
    Object error, {
    OnmuErrorUiContext context = OnmuErrorUiContext.mutation,
  }) {
    final onmuError = error is OnmuException ? error : null;
    final kind = onmuError?.kind ?? OnmuErrorKind.unknown;
    final message = onmuError?.userMessage ?? '잠시 문제가 생겼어요. 다시 시도해 주세요.';
    final canRetry = onmuError?.retryable ?? true;

    return OnmuUiError(
      message: message,
      presentation: _presentationFor(kind, context),
      canRetry: canRetry,
    );
  }
}

OnmuErrorPresentation _presentationFor(
  OnmuErrorKind kind,
  OnmuErrorUiContext context,
) {
  if (context == OnmuErrorUiContext.optionalBackground) {
    return OnmuErrorPresentation.silent;
  }
  if (context == OnmuErrorUiContext.mutation) {
    return OnmuErrorPresentation.snackbar;
  }
  return switch (kind) {
    OnmuErrorKind.server ||
    OnmuErrorKind.unavailable ||
    OnmuErrorKind.timeout ||
    OnmuErrorKind.network => OnmuErrorPresentation.fullScreen,
    OnmuErrorKind.notFound => OnmuErrorPresentation.fullScreen,
    OnmuErrorKind.unauthorized => OnmuErrorPresentation.fullScreen,
    _ => OnmuErrorPresentation.retryableCard,
  };
}
