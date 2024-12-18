class Drinkslog {
  late int volume;
  late String time;
  late int ml;
  late int waveHeight;
  late double waveAmplitude;

  Drinkslog(
      {required this.volume,
      required this.time,
      required this.ml,
      required this.waveHeight,
      required this.waveAmplitude});

  Drinkslog.fromJson(Map<String, dynamic> json) {
    volume = json['volume'];
    time = json['time'];
    ml = json['ml'];
    waveHeight = json['waveHeight'];
    waveAmplitude = json['waveAmplitude'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['volume'] = this.volume;
    data['time'] = this.time;
    data['ml'] = this.ml;
    data['waveHeight'] = this.waveHeight;
    data['waveAmplitude'] = this.waveAmplitude;
    return data;
  }
}
