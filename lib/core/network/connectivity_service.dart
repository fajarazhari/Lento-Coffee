import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_service.g.dart';

@riverpod
Stream<bool> isOnline(IsOnlineRef ref) {
  return Connectivity()
      .onConnectivityChanged
      .map((results) => !results.contains(ConnectivityResult.none));
}

@riverpod
class ConnectivityService extends _$ConnectivityService {
  @override
  Future<bool> build() async {
    final results = await Connectivity().checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }

  Future<bool> checkNow() async {
    final results = await Connectivity().checkConnectivity();
    final online = !results.contains(ConnectivityResult.none);
    state = AsyncData(online);
    return online;
  }
}
