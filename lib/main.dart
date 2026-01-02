import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // Required for BlendMask
import 'dart:math'; // Required for Random simulation

void main() {
  runApp(const SciFiLabApp());
}

class SciFiLabApp extends StatelessWidget {
  const SciFiLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sci-Fi Lab Control',
      theme: ThemeData.dark(),
      home: const SciFiLabControl(),
    );
  }
}

class SciFiLabControl extends StatefulWidget {
  const SciFiLabControl({super.key});

  @override
  State<SciFiLabControl> createState() => _SciFiLabControlState();
}

class _SciFiLabControlState extends State<SciFiLabControl>
    with TickerProviderStateMixin {
  late AnimationController _introController;
  late AnimationController _vpnConnectionController;

  bool isSystemOn = false;
  bool isVpnConnected = false;
  String? selectedRegion;

  // --- NEW: Connection Logic State ---
  bool hasConnectionError = false;
  bool isHandshaking = false; // To track the "Connecting..." phase

  // Responsive Reference Dimensions (iPhone 12 Pro)
  static const double designWidth = 390.0;
  static const double designHeight = 844.0;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _vpnConnectionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _introController.dispose();
    _vpnConnectionController.dispose();
    super.dispose();
  }

  // --- LOGIC HANDLERS ---

  void _toggleSystem() {
    if (isVpnConnected || isHandshaking) return; // Lock if busy

    setState(() {
      isSystemOn = !isSystemOn;
      if (isSystemOn) {
        _introController.forward();
      } else {
        _introController.reverse();
        selectedRegion = null;
        hasConnectionError = false;
      }
    });
  }

  // --- THE "REAL" VPN SIMULATION LOGIC ---
  Future<void> _toggleVpnConnection() async {
    // 1. Validation
    if (!isSystemOn || selectedRegion == null || isHandshaking) return;

    // 2. DISCONNECT SEQUENCE
    if (isVpnConnected) {
      setState(() {
        isVpnConnected = false;
        hasConnectionError = false;
      });
      _vpnConnectionController.reverse(); // Play Close Animation
      return;
    }

    // 3. CONNECT SEQUENCE (Simulation)
    setState(() {
      isHandshaking = true;
      hasConnectionError = false;
    });

    // Start the visual animation (Wires start flowing)
    _vpnConnectionController.forward();

    // SIMULATION: Fake network delay (2 seconds)
    // *In a real app, you would await your VPN plugin here*
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // SIMULATION: Random Failure Logic
    // 30% Chance of failure to demonstrate the Error Screen
    bool simulatedFailure = Random().nextBool() && Random().nextBool(); // ~25-30% chance

    // NOTE: To force failure for testing, uncomment below:
    // simulatedFailure = true;

    setState(() {
      isHandshaking = false;
      isVpnConnected = true; // Visually we are "done" attempting

      if (simulatedFailure) {
        hasConnectionError = true;
        // If error, we keep the controller forward but show Error Screen
        // You might want to stop wires here, but visually it looks cool if they freeze or stay.
      } else {
        hasConnectionError = false;
      }
    });
  }

  void _selectRegion(String region) {
    if (!isSystemOn || isVpnConnected || isHandshaking) return;

    setState(() {
      if (selectedRegion == region) {
        selectedRegion = null;
      } else {
        selectedRegion = region;
      }
    });
  }

  // --- ANIMATION HELPERS ---
  Widget _buildFadeLayer({
    required AnimationController controller,
    required String assetPath,
    required double startInterval,
    required double endInterval,
  }) {
    return Positioned.fill(
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(startInterval, endInterval, curve: Curves.linear),
          ),
        ),
        child: Image.asset(assetPath, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildFlowingLayer({
    required AnimationController controller,
    required String assetPath,
    required double startInterval,
    required double endInterval,
  }) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          double t = controller.value;
          double localProgress = 0.0;
          if (t > startInterval && t < endInterval) {
            localProgress = (t - startInterval) / (endInterval - startInterval);
          } else if (t >= endInterval) {
            localProgress = 1.0;
          }
          if (localProgress == 0.0) return const SizedBox();

          return ShaderMask(
            shaderCallback: (rect) {
              return LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: [localProgress, localProgress + 0.15],
                colors: const [Colors.white, Colors.transparent],
              ).createShader(rect);
            },
            blendMode: BlendMode.dstIn,
            child: Image.asset(assetPath, fit: BoxFit.cover),
          );
        },
      ),
    );
  }

  // ===============================================================
  // LAYER: HOLOGRAPHIC REGION SCREENS (SUCCESS)
  // ===============================================================
  Widget _buildHolographicScreens() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _vpnConnectionController,
        builder: (context, child) {
          // LOGIC UPDATE: If there is an Error, do NOT show the success screen.
          // Also wait until the controller > 0.3 so it fades in properly.
          if (!isVpnConnected || hasConnectionError) return const SizedBox();

          String? screenAsset;
          if (selectedRegion == 'us_east') {
            screenAsset = 'assets/connect/us_east_screen_00000.png';
          } else if (selectedRegion == 'uk') {
            screenAsset = 'assets/connect/uk_screen_00000.png';
          } else if (selectedRegion == 'germany') {
            screenAsset = 'assets/connect/germany_screen_00000.png';
          } else if (selectedRegion == 'eduroam') {
            // FIXED: Eduroam now shows its own success screen!
            screenAsset = 'assets/connect/eduroam_screen_00000.png';
          }

          if (screenAsset == null) return const SizedBox();

          double t = _vpnConnectionController.value;
          double opacity = 0.0;

          if (t > 0.3) {
            opacity = (t - 0.3) / 0.7;
          }

          return BlendMask(
            blendMode: BlendMode.screen,
            opacity: opacity.clamp(0.0, 1.0),
            child: Image.asset(
              screenAsset,
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }

  // ===============================================================
  // LAYER: ERROR SCREEN (DYNAMIC)
  // ===============================================================
  Widget _buildErrorScreen() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _vpnConnectionController,
        builder: (context, child) {
          // LOGIC UPDATE: Show this for ANY region if hasConnectionError is true
          if (!isVpnConnected || !hasConnectionError) return const SizedBox();

          // Animation: Fade in quickly
          double t = _vpnConnectionController.value;
          double opacity = 0.0;
          if (t > 0.1) {
            opacity = (t - 0.1) / 0.4;
          }

          // NO BLEND MODE - Solid Error Overlay
          return Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Image.asset(
              'assets/connect/error_screen_00000.png',
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }

  // ===============================================================
  // VISUAL LAYERS
  // ===============================================================
  Widget _buildVpnVisuals() {
    Widget buildRegionHighlight({
      required String id,
      required String asset,
      required double left,
      required double bottom,
      required double size,
    }) {
      return Positioned(
        left: left,
        bottom: bottom,
        width: size,
        child: GestureDetector(
          onTap: () => _selectRegion(id),
          child: Opacity(
            opacity: selectedRegion == id ? 1.0 : 0.0,
            child: Image.asset(asset, fit: BoxFit.contain),
          ),
        ),
      );
    }

    return Stack(
      children: [
        // 1. Region Buttons
        buildRegionHighlight(id: 'us_east', asset: 'assets/connect/us_east_button_00000.png', left: 87, bottom: 201.5, size: 85),
        buildRegionHighlight(id: 'uk', asset: 'assets/connect/uk_button.png', left: 154, bottom: 194, size: 88),
        buildRegionHighlight(id: 'germany', asset: 'assets/connect/germany_button_00000.png', left: 226, bottom: 196, size: 84),
        buildRegionHighlight(id: 'eduroam', asset: 'assets/connect/eduroam_button_00000.png', left: 288.5, bottom: 194.5, size: 101),

        // 2. Green Wire Flow
        Positioned(
          bottom: 275.5,
          left: 144,
          width: 136,
          child: AnimatedBuilder(
            animation: _vpnConnectionController,
            builder: (context, child) {
              // Hide wires if Error? (Optional, kept visible for depth as requested)

              double t = _vpnConnectionController.value;
              double localProgress = (t / 0.8).clamp(0.0, 1.0);
              if (localProgress == 0.0) return const SizedBox();

              return ShaderMask(
                shaderCallback: (rect) {
                  return LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: [localProgress, localProgress + 0.15],
                    colors: const [Colors.white, Colors.transparent],
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn,
                child: Image.asset('assets/connect/status_update_currentflow_00000.png', fit: BoxFit.contain),
              );
            },
          ),
        ),

        // 3. Green Globe
        Positioned(
          bottom: 357,
          left: 115,
          width: 169,
          child: AnimatedBuilder(
            animation: _vpnConnectionController,
            builder: (context, child) {
              // If Error, maybe we hide the globe update?
              if (hasConnectionError) return const SizedBox();

              double t = _vpnConnectionController.value;
              double fade = 0.0;
              if (t > 0.8) fade = (t - 0.8) / 0.2;
              if (fade == 0.0) return const SizedBox();

              return Opacity(
                opacity: fade.clamp(0.0, 1.0),
                child: Image.asset('assets/connect/globe_update_00000.png', fit: BoxFit.contain),
              );
            },
          ),
        ),

        // 4. Stop Button Visual
        Positioned(
          bottom: 150,
          left: 157.5,
          width: 78,
          child: IgnorePointer(
            ignoring: true,
            child: AnimatedBuilder(
                animation: _vpnConnectionController,
                builder: (context, child) {
                  // Show Stop button as long as we are connected or connecting
                  return Opacity(
                    opacity: (isVpnConnected || isHandshaking) ? 1.0 : 0.0,
                    child: Image.asset('assets/connect/stop_button_00000.png', fit: BoxFit.contain),
                  );
                }
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: screenSize.width,
        height: screenSize.height,
        color: Colors.black,
        child: Center(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: designWidth,
              height: designHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // =================================================
                  // LAYER 1: BASE
                  // =================================================
                  Positioned.fill(child: Image.asset('assets/complete_lab_off_00000.png', fit: BoxFit.cover)),
                  _buildFadeLayer(controller: _introController, assetPath: 'assets/buttons_00000.png', startInterval: 0.05, endInterval: 0.20),
                  _buildFlowingLayer(controller: _introController, assetPath: 'assets/wire_to_globe_00001.png', startInterval: 0.20, endInterval: 0.60),
                  _buildFadeLayer(controller: _introController, assetPath: 'assets/central_globe_00000.png', startInterval: 0.60, endInterval: 0.63),
                  _buildFadeLayer(controller: _introController, assetPath: 'assets/ceiling_bulb_00000.png', startInterval: 0.65, endInterval: 0.80),
                  _buildFadeLayer(controller: _introController, assetPath: 'assets/complete_lab_on_00000.png', startInterval: 0.80, endInterval: 1.0),

                  // =================================================
                  // LAYER 2: VPN FEATURES
                  // =================================================
                  _buildVpnVisuals(),

                  // =================================================
                  // LAYER 3: HOLOGRAPHIC SCREENS (SUCCESS)
                  // =================================================
                  _buildHolographicScreens(),

                  // =================================================
                  // LAYER 4: ERROR SCREEN (FAILURE)
                  // =================================================
                  _buildErrorScreen(),

                  // =================================================
                  // LAYER 5: STOP BUTTON OVERLAY
                  // =================================================
                  Positioned(
                    bottom: 150,
                    left: 157.5,
                    width: 78,
                    child: IgnorePointer(
                      ignoring: true,
                      child: AnimatedBuilder(
                          animation: _vpnConnectionController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: (isVpnConnected || isHandshaking) ? 1.0 : 0.0,
                              child: Image.asset('assets/connect/stop_button_00000.png', fit: BoxFit.contain),
                            );
                          }
                      ),
                    ),
                  ),

                  // =================================================
                  // LAYER 6: INTERACTION
                  // =================================================
                  Positioned(
                    bottom: 175,
                    left: 4,
                    width: 100,
                    height: 140,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _toggleSystem,
                      child: AnimatedBuilder(
                        animation: _introController,
                        builder: (context, child) {
                          double opacity = (_introController.value > 0.01) ? 1.0 : 0.0;
                          return Opacity(
                            opacity: opacity,
                            child: Image.asset('assets/turn_on_button_00000.png', fit: BoxFit.contain),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 150,
                    left: 157.5,
                    width: 78,
                    height: 78,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _toggleVpnConnection,
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===============================================================
// CUSTOM WIDGET: BLEND MASK
// ===============================================================
class BlendMask extends SingleChildRenderObjectWidget {
  final BlendMode blendMode;
  final double opacity;

  const BlendMask({
    required this.blendMode,
    this.opacity = 1.0,
    super.key,
    super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderBlendMask(blendMode, opacity);
  }

  @override
  void updateRenderObject(BuildContext context, RenderBlendMask renderObject) {
    renderObject.blendMode = blendMode;
    renderObject.opacity = opacity;
  }
}

class RenderBlendMask extends RenderProxyBox {
  BlendMode _blendMode;
  double _opacity;

  RenderBlendMask(this._blendMode, this._opacity);

  set blendMode(BlendMode value) {
    if (_blendMode == value) return;
    _blendMode = value;
    markNeedsPaint();
  }

  set opacity(double value) {
    if (_opacity == value) return;
    _opacity = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.canvas.saveLayer(
      offset & size,
      Paint()
        ..blendMode = _blendMode
        ..color = Color.fromARGB((_opacity * 255).round(), 255, 255, 255),
    );

    super.paint(context, offset);

    context.canvas.restore();
  }
}