import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PathErrorPage extends StatefulWidget {
  final String? error;
  const PathErrorPage({super.key, this.error = 'Page Not Found'});

  @override
  State<PathErrorPage> createState() => _PathErrorPageState();
}

class _PathErrorPageState extends State<PathErrorPage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/404_not_found.png',
                height: 200,
              ),
              SizedBox(height: 20),
              Text(
                '404',
                style: TextStyle(
                  fontSize: 100,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 20),
              Text(
                GoRouterState.of(context).extra.toString() ?? widget.error!,
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Page you are loking for might have been removed, had its name changed ,or is temporarily unavailable.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  context.go('/login');

                  // Navigator.of(context).pushReplacement(
                  //   MaterialPageRoute(
                  //     builder: (context) => HomePage(), // Remplace HomePage par la page d'accueil de ton application
                  //   ),
                  // );
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: Colors.blue,
                ),
                child: Text(
                  'Go to Home',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PathErrorPage2 extends StatefulWidget {
  final String? error;
  const PathErrorPage2({super.key, this.error = 'Page Not Found'});

  @override
  State<PathErrorPage2> createState() => _PathErrorPage2State();
}

class _PathErrorPage2State extends State<PathErrorPage2> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/404_not_found.png',
                height: 200,
              ),
              SizedBox(height: 20),
              Text(
                '404',
                style: TextStyle(
                  fontSize: 100,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 20),
              Text(
                widget.error!,
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Page you are loking for might have been removed, had its name changed ,or is temporarily unavailable.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  context.go('/login');

                  // Navigator.of(context).pushReplacement(
                  //   MaterialPageRoute(
                  //     builder: (context) => HomePage(), // Remplace HomePage par la page d'accueil de ton application
                  //   ),
                  // );
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: Colors.blue,
                ),
                child: Text(
                  'Go to Home',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
