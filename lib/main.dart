// ignore_for_file: avoid_print

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:convert';
import 'secrets.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "Cloud buffer",
        theme: ThemeData(
            colorScheme: ColorScheme.fromSwatch().copyWith(
                primary: const Color(0xFF283655),
                secondary: const Color(0xFF4facfe)),
            fontFamily: "Georgia"),
        home: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Image.asset(
              "logo-hori.png",
              width: 200,
              fit: BoxFit.contain,
            ),
          ),
          body: const HomePage(),
        ));
  }
}

class City {
  final String name;
  final String desc;
  final String country;
  final double temp;
  final double windSpeed;
  final double pressure;
  final double humidity;

  const City(
      {required this.name,
      required this.desc,
      required this.country,
      required this.temp,
      required this.windSpeed,
      required this.pressure,
      required this.humidity});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      name: json['name'],
      desc: json['weather'][0]['description'],
      country: json['sys']["country"],
      temp: json['main']['temp'],
      windSpeed: json['wind']['speed'],
      pressure: json['main']['pressure'],
      humidity: json['main']['humidity'],
    );
  }
}

Future<City> fetchWeather(search) async {
  final response = await http.get(Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?q=$search&appid=$API_KEY&units=metric'));

  if (response.statusCode == 200) {
    return City.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load the weather');
  }
}

late Future<City> futureCity = fetchWeather("london");

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();

  String query = "";

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topCenter,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 50),
      child: Column(
        children: [
          const Text(
            "The Clouds reach every corner in the world",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: 20,
          ),
          const Text(
              "Your search too, try finding your city's weather anywhere, at anytime",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(
            height: 50,
          ),
          SizedBox(
            width: 300,
            child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                          hintText: "Ex. London, New York, Paris",
                          labelText: "Search a city name"),
                      onChanged: (value) => query = value,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "You cant leave the field empty";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text("Searching for the weather...")));
                            setState(() {
                              futureCity = fetchWeather(query);
                              const WeatherDisplay();
                            });
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const WeatherDisplay()));
                          }
                        },
                        child: const Text("Submit"))
                  ],
                )),
          )
        ],
      ),
    );
  }
}

class WeatherDisplay extends StatefulWidget {
  const WeatherDisplay({Key? key}) : super(key: key);

  @override
  State<WeatherDisplay> createState() => WeatherDisplayState();
}

class WeatherDisplayState extends State<WeatherDisplay> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Searched Weather")),
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: FutureBuilder<City>(
          future: futureCity,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Weather in " + snapshot.data!.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 40),
                  ),
                  Text(snapshot.data!.desc,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 30),
                  Text(
                    '${snapshot.data!.temp.round().toString()} °c',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 40),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text('${snapshot.data!.windSpeed.toString()} m/s'),
                      Text('${snapshot.data!.humidity.toString()}%'),
                      Text('${snapshot.data!.pressure.toString()} hPa'),
                    ],
                  ),
                ],
              );
            } else if (snapshot.hasError) {
              return Text('${snapshot.error}');
            }
            return const CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}
