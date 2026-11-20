import '../../domain/entities/link_request.dart';

sealed class LinkRequestState {}

final class LinkRequestIdle extends LinkRequestState {}

final class LinkRequestSubmitting extends LinkRequestState {}

final class LinkRequestSubmitted extends LinkRequestState {
  final int requestId;
  LinkRequestSubmitted(this.requestId);
}

final class LinkRequestFailure extends LinkRequestState {
  final String message;
  LinkRequestFailure(this.message);
}

final class LinkRequestListLoaded extends LinkRequestState {
  final List<LinkRequest> requests;
  LinkRequestListLoaded(this.requests);
}
