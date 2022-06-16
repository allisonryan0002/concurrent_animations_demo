import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum DriveMode { normal, sport, eco }

enum Scale { small, large }

class GaugeState {
  const GaugeState({this.mode = DriveMode.normal, this.scale = Scale.small});

  final DriveMode mode;
  final Scale scale;

  GaugeState copyWith({DriveMode? mode, Scale? scale}) {
    return GaugeState(
      mode: mode ?? this.mode,
      scale: scale ?? this.scale,
    );
  }
}

class GaugeCubit extends Cubit<GaugeState> {
  GaugeCubit() : super(const GaugeState());

  void toggleDriveMode() {
    final nextDriveModeIndex = (state.mode.index + 1) % DriveMode.values.length;
    emit(state.copyWith(mode: DriveMode.values[nextDriveModeIndex]));
  }

  void toggleScale() {
    emit(
      state.copyWith(
        scale: state.scale == Scale.small ? Scale.large : Scale.small,
      ),
    );
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
              child: const Icon(Icons.color_lens),
            ),
            const SizedBox(height: 8),
            FloatingActionButton(
              onPressed: () => context.read<GaugeCubit>().toggleScale(),
              child: const Icon(Icons.swap_vert_circle),
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

class _GaugeState extends State<Gauge> with SingleTickerProviderStateMixin {
  late ColorTween _displayModeTween;
  late Tween<double> _scaleTween;
  late AnimationController _controller;

  late GaugeState _state;

  @override
  void initState() {
    super.initState();
    _state = context.read<GaugeCubit>().state;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    final theme = GaugeVisuals.fromState(_state);
    _displayModeTween = ColorTween(
      begin: theme.color,
      end: theme.color,
    );
    _scaleTween = Tween<double>(
      begin: theme.diameter,
      end: theme.diameter,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocListener<GaugeCubit, GaugeState>(
      listener: (context, state) {
        final theme = GaugeVisuals.fromState(state);
        _displayModeTween = ColorTween(
          begin: _displayModeTween.evaluate(_controller),
          end: theme.color,
        );
        _scaleTween = Tween<double>(
          begin: _scaleTween.evaluate(_controller),
          end: theme.diameter,
        );
        _state = state;
        _controller.forward(from: 0);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final diameter = _scaleTween.evaluate(_controller);
              final color = _displayModeTween.evaluate(_controller);
              return Container(
                width: diameter,
                height: diameter,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              );
            },
          ),
          BlocBuilder<GaugeCubit, GaugeState>(
            builder: (context, state) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.mode.name, style: theme.textTheme.headline6),
                  Text(state.scale.name, style: theme.textTheme.headline6),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class GaugeVisuals {
  const GaugeVisuals._({
    required this.diameter,
    required this.color,
  });

  factory GaugeVisuals.fromState(GaugeState state) {
    final color = state.mode.toColor();
    final diameter = state.scale.toDiameter();
    return GaugeVisuals._(diameter: diameter, color: color);
  }

  final double diameter;
  final Color color;
}

extension on DriveMode {
  Color toColor() {
    switch (this) {
      case DriveMode.normal:
        return Colors.grey;
      case DriveMode.sport:
        return Colors.red;
      case DriveMode.eco:
        return Colors.blue;
    }
  }
}

extension on Scale {
  double toDiameter() {
    switch (this) {
      case Scale.small:
        return 200.0;
      case Scale.large:
        return 500.0;
    }
  }
}
