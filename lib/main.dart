import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum DriveMode {
  normal(Colors.grey),
  sport(Colors.red),
  eco(Colors.blue);

  final Color color;
  const DriveMode(this.color);
}

class GaugeState {
  const GaugeState({this.mode = DriveMode.normal});

  final DriveMode mode;
}

class GaugeCubit extends Cubit<GaugeState> {
  GaugeCubit() : super(const GaugeState());

  void toggleDriveMode() {
    final nextDriveModeIndex = (state.mode.index + 1) % DriveMode.values.length;
    emit(GaugeState(mode: DriveMode.values[nextDriveModeIndex]));
  }
}

void main() => runApp(
      BlocProvider(
        create: (_) => GaugeCubit(),
        child: const App(),
      ),
    );

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: const Center(
          child: Gauge(),
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: () => context.read<GaugeCubit>().toggleDriveMode(),
              child: const Text(
                'Drive Mode',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Gauge extends StatefulWidget {
  const Gauge({Key? key}) : super(key: key);

  @override
  State<Gauge> createState() => _GaugeState();
}

class _GaugeState extends State<Gauge> with TickerProviderStateMixin {
  late ColorTween _colorTween;
  late Animation<double> _scaleTween;
  late AnimationController _colorController;
  late AnimationController _scaleController;

  late GaugeState _state;

  @override
  void initState() {
    super.initState();
    _state = context.read<GaugeCubit>().state;
    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _colorTween = ColorTween(
      begin: _state.mode.color,
      end: _state.mode.color,
    );
    _scaleTween = TweenSequence<double>(
      <TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(
            begin: 400,
            end: 400,
          ),
          weight: 50,
        ),
      ],
    ).animate(_scaleController);
  }

  @override
  void dispose() {
    _colorController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocListener<GaugeCubit, GaugeState>(
      listener: (context, state) {
        _colorTween = ColorTween(
          begin: _colorTween.evaluate(_colorController),
          end: state.mode.color,
        );
        _scaleTween = TweenSequence<double>(
          <TweenSequenceItem<double>>[
            TweenSequenceItem<double>(
              tween: Tween<double>(begin: _scaleTween.value, end: 0),
              weight: 50,
            ),
            TweenSequenceItem<double>(
              tween: Tween<double>(begin: 0, end: 400),
              weight: 50,
            ),
          ],
        ).animate(_scaleController);
        _state = state;
        _colorController.forward(from: 0);
        _scaleController.forward(from: 0);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _scaleController,
            builder: (context, child) {
              return AnimatedBuilder(
                animation: _colorController,
                builder: (context, child) {
                  final diameter = _scaleTween.value;
                  final color = _colorTween.evaluate(_colorController);
                  return _Circle(diameter: diameter, color: color);
                },
              );
            },
          ),
          BlocBuilder<GaugeCubit, GaugeState>(
            builder: (context, state) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.mode.name, style: theme.textTheme.headline6),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({
    Key? key,
    required this.diameter,
    required this.color,
  }) : super(key: key);

  final double diameter;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
