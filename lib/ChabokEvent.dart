class ChabokEvent {
  dynamic data;
  double revenue;
  String currency;

  ChabokEvent(double revenue, [String currency]) {
    this.revenue = revenue;
    this.currency = currency;
  }

  setData(dynamic data) {
    this.data = data;
  }

  setCurrency(String currency) {
    this.currency = currency;
  }
}
