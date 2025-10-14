// lib/widgets/navigation_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/navigation_service.dart';
import '../models/delivery_point.dart';
import '../l10n/app_localizations.dart';

class NavigationWidget extends StatefulWidget {
  final List<DeliveryPoint> route;
  final double? currentLat;
  final double? currentLng;
  final Function(int)? onStepCompleted;
  
  const NavigationWidget({
    super.key,
    required this.route,
    this.currentLat,
    this.currentLng,
    this.onStepCompleted,
  });

  @override
  State<NavigationWidget> createState() => _NavigationWidgetState();
}

class _NavigationWidgetState extends State<NavigationWidget> {
  final NavigationService _navigationService = NavigationService();
  NavigationRoute? _navigationRoute;
  int _currentStepIndex = 0;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNavigationRoute();
  }

  @override
  void didUpdateWidget(NavigationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Перезагружаем маршрут если изменился список точек
    if (oldWidget.route.length != widget.route.length ||
        oldWidget.currentLat != widget.currentLat ||
        oldWidget.currentLng != widget.currentLng) {
      _loadNavigationRoute();
    }
  }

  Future<void> _loadNavigationRoute() async {
    if (widget.route.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      NavigationRoute? route;
      
      if (widget.currentLat != null && widget.currentLng != null) {
        // Навигация от текущей позиции до первой точки, затем между точками
        final firstPoint = widget.route.first;
        
        if (widget.route.length == 1) {
          // Только одна точка
          route = await _navigationService.getNavigationRoute(
            startLat: widget.currentLat!,
            startLng: widget.currentLng!,
            endLat: firstPoint.latitude,
            endLng: firstPoint.longitude,
          );
        } else {
          // Несколько точек - используем waypoints
          final waypoints = widget.route.skip(1).toList();
          final lastPoint = widget.route.last;
          
          route = await _navigationService.getMultiPointRoute(
            startLat: widget.currentLat!,
            startLng: widget.currentLng!,
            waypoints: waypoints,
            endLat: lastPoint.latitude,
            endLng: lastPoint.longitude,
          );
        }
      } else {
        // Навигация между точками маршрута без учета текущей позиции
        if (widget.route.length > 1) {
          final waypoints = widget.route.skip(1).take(widget.route.length - 2).toList();
          final startPoint = widget.route.first;
          final endPoint = widget.route.last;
          
          route = await _navigationService.getMultiPointRoute(
            startLat: startPoint.latitude,
            startLng: startPoint.longitude,
            waypoints: waypoints,
            endLat: endPoint.latitude,
            endLng: endPoint.longitude,
          );
        }
      }

      if (mounted) {
        setState(() {
          _navigationRoute = route;
          _isLoading = false;
          _currentStepIndex = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _nextStep() {
    if (_navigationRoute != null && _currentStepIndex < _navigationRoute!.steps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
      
      // Уведомляем родительский виджет о завершении шага
      widget.onStepCompleted?.call(_currentStepIndex);
    }
  }

  void _previousStep() {
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              l10n.loadingNavigation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.navigationError,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNavigationRoute,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (_navigationRoute == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.route,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noNavigationRoute,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    final currentStep = _navigationRoute!.steps[_currentStepIndex];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Заголовок с информацией о маршруте
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.navigation,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.navigation,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_navigationRoute!.distance} • ${_navigationRoute!.duration}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_currentStepIndex + 1}/${_navigationRoute!.steps.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Текущий шаг навигации
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.directions,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        currentStep.instruction,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Icon(
                      Icons.straighten,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currentStep.distance,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currentStep.duration,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Кнопки управления
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _currentStepIndex > 0 ? _previousStep : null,
                    icon: const Icon(Icons.arrow_back),
                    label: Text(l10n.previous),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _currentStepIndex < _navigationRoute!.steps.length - 1
                        ? _nextStep
                        : null,
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(l10n.next),
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
