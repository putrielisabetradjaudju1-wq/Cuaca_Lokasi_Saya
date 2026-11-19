// UI LAYER - ViewModel halaman gempa.

import 'package:flutter/foundation.dart';

import '../../data/api_exception.dart';
import '../../data/earthquake_repository.dart';
import '../../models/earthquake.dart';
import '../ui_state.dart';

class EarthquakeViewModel extends ChangeNotifier {
  EarthquakeViewModel(this._repository);

  final EarthquakeRepository _repository;

  UiState<EarthquakeFeed> _state = const Idle();
  UiState<EarthquakeFeed> get state => _state;

  /// Memuat dengan indikator penuh.
  Future<void> load() async {
    _state = const Loading();
    notifyListeners();
    await _fetch();
  }

  /// Memuat ulang tanpa menghapus data lama dari layar.
  Future<void> refresh() => _fetch();

  Future<void> _fetch() async {
    try {
      _state = Success(await _repository.getFeed());
    } on ApiException catch (e) {
      _state = Failure(e);
    }
    notifyListeners();
  }
}
