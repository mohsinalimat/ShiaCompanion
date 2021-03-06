import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class PrayerTimes extends StatefulWidget {
  PrayerTimes();

  @override
  PrayerTimesState createState() => PrayerTimesState();
}

class PrayerTimesState extends State<PrayerTimes> {
  PrayerTimesState();
  List prayerTimes;
  LocationData currentLocation;
  DateTime today = DateTime.now();

  Location location = Location();
  @override
  void initState() {
    super.initState();
    getLocation();
  }

  @override
  Widget build(BuildContext context) {
    DateTime startOfMonth = DateTime(today.year, today.month, 1);
    int ind = today.difference(startOfMonth).inDays;
    return prayerTimes != null
        ? SizedBox(
            height: 210.0,
            child: Container(),
          )
        : Container();
  }

  getLocation() async {
    try {
      currentLocation = await location.getLocation();
    } catch (e) {
      debugPrint(e.toString());
      currentLocation = null;
    }
    if (currentLocation != null) calculatePrayerTimes();
    setState(() {});
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  // Check if prayer time exists or not, if not get from API for the whole month
  Future<void> calculatePrayerTimes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String prayerTimesJson = prefs.getString('prayerTimes');

    if (prayerTimesJson == null) {
      prayerTimesJson = await getPrayerTimesFromAPI();
      if (prayerTimesJson == null) return;
      prayerTimes = json.decode(prayerTimesJson)['data'];
    } else {
      prayerTimes = json.decode(prayerTimesJson)['data'];

      double lat1 = prayerTimes[0]['meta']['latitude'],
          long1 = prayerTimes[0]['meta']['longitude'];

      int month = prayerTimes[0]['date']['gregorian']['month']['number'];
      if (calculateDistance(lat1, long1, currentLocation.latitude,
                  currentLocation.longitude) >
              20.0 ||
          month != DateTime.now().month) {
        prayerTimesJson = await getPrayerTimesFromAPI();
        if (prayerTimesJson == null) return;
        prayerTimes = json.decode(prayerTimesJson)['data'];
      }
    }
    await prefs.setString('prayerTimes', prayerTimesJson);
    setState(() {});
  }

  void setNotifications() async {
    DateTime now = DateTime.now();
    now.add(Duration(days: 5));
  }

  Future<String> getPrayerTimesFromAPI() async {
    String prayerTimesJson;
    String url =
        "https://api.aladhan.com/v1/calendar?latitude=${currentLocation.latitude}&longitude=${currentLocation.longitude}&method=0&month=${today.month}&year=${today.year}&midnightMode=1&tune=0,0,0,0,0,0,0,0,0&adjustment=$hijriDate";
    debugPrint(url);
    var request = await get(url);
    if (request.statusCode == 200) {
      prayerTimesJson = request.body;
    } else {
      key.currentState.showSnackBar(SnackBar(
        content: Text("Unable to get prayer times"),
      ));
    }
    return prayerTimesJson;
  }
}
