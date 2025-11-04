class ConvertCurrency {
  static const _rates = {
    'USD': 0.000064,
    'EUR': 0.000059,
    'SGD': 0.000086,
    'MYR': 0.00030,
  };

  /// Konversi nilai antar mata uang
  static double convert(double amount, String from, String to) {
    if (from == to) return amount;

    if (from == 'IDR' && _rates.containsKey(to)) {
      return amount * _rates[to]!;
    }

    if (_rates.containsKey(from) && to == 'IDR') {
      return amount / _rates[from]!;
    }

    if (_rates.containsKey(from) && _rates.containsKey(to)) {
      double idrValue = amount / _rates[from]!;
      return idrValue * _rates[to]!;
    }

    return amount;
  }
}
