import 'package:equatable/equatable.dart';

/// Pagination state used by providers that load lists with cursor-based paging
class PaginationState<T> extends Equatable {
  const PaginationState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.lastDocumentId,
  });

  final List<T> items;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final String? lastDocumentId; // Firestore cursor

  PaginationState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? hasMore,
    String? error,
    String? lastDocumentId,
  }) =>
      PaginationState<T>(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        hasMore: hasMore ?? this.hasMore,
        error: error ?? this.error,
        lastDocumentId: lastDocumentId ?? this.lastDocumentId,
      );

  PaginationState<T> appended(List<T> newItems, {required bool hasMore, String? lastDocumentId}) =>
      copyWith(
        items: [...items, ...newItems],
        isLoading: false,
        hasMore: hasMore,
        lastDocumentId: lastDocumentId,
      );

  bool get isEmpty => items.isEmpty && !isLoading;

  @override
  List<Object?> get props => [items, isLoading, hasMore, error, lastDocumentId];
}
