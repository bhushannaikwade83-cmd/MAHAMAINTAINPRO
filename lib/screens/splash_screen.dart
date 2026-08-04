import 'package:flutter/material.dart';

/// Splash screen — "विश्वास महाराष्ट्राचा"
///
/// pubspec.yaml:
///   flutter:
///     assets:
///       - assets/images/splash_bg.png
///     fonts:
///       - family: NotoSerifDevanagari
///         fonts:
///           - asset: assets/fonts/NotoSerifDevanagari-Bold.ttf
///             weight: 700
///           - asset: assets/fonts/NotoSerifDevanagari-Regular.ttf
///             weight: 400
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const Color _bgNavy = Color(0xFF0A1020);
  static const Color _saffron = Color(0xFFD9761F);
  static const Color _goldPale = Color(0xFFE8C46A);
  static const Color _tagline = Color(0xFFBFC7D5);
  static const String _fontFamily = 'NotoSerifDevanagari';

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double w = size.width;
    final double h = size.height;

    // Responsive scale, clamped so it stays sane on tablets.
    final double scale = (w / 390).clamp(0.85, 1.6);

    return Scaffold(
      backgroundColor: _bgNavy,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // 1. Background image (Maharashtra map texture)
          Image.asset(
            'assets/images/maharashtra.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),

          // 2. Bottom fade for text readability
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.transparent,
                  Color(0x330A1020),
                  Color(0xE60A1020),
                ],
                stops: <double>[0.35, 0.65, 1.0],
              ),
            ),
          ),

          // 3. Centered logo block
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24 * scale),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'विश्वास',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 64 * scale,
                      height: 1.25,
                      letterSpacing: 0.5,
                      color: _saffron,
                      shadows: const <Shadow>[
                        Shadow(
                          color: Color(0x99000000),
                          blurRadius: 12,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4 * scale),
                  Text(
                    'महाराष्ट्राचा',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 44 * scale,
                      height: 1.35,
                      letterSpacing: 0.5,
                      color: _goldPale,
                      shadows: const <Shadow>[
                        Shadow(
                          color: Color(0x99000000),
                          blurRadius: 12,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20 * scale),

                  // 4. Subtitle / tagline
                  Text(
                    'महाराष्ट्राचा स्वतःचा डिजिटल मंच',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontWeight: FontWeight.w400,
                      fontSize: 16 * scale,
                      height: 1.6,
                      letterSpacing: 0.2,
                      color: _tagline,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 5. Version + loading indicator
          Positioned(
            left: 0,
            right: 0,
            bottom: h * 0.08,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'v1.0.0',
                  style: TextStyle(
                    fontSize: 13 * scale,
                    letterSpacing: 1.2,
                    color: Colors.white.withOpacity(0.55),
                  ),
                ),
                SizedBox(height: 18 * scale),
                SizedBox(
                  width: 28 * scale,
                  height: 28 * scale,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.6,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF07A1A)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
