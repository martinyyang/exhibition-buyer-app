import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/network_status_service.dart';

/// 网络状态指示器组件
/// 显示当前网络连接状态和延迟
class NetworkStatusIndicator extends ConsumerWidget {
  const NetworkStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkStatus = ref.watch(networkStatusServiceProvider);

    // 只在网络状态不佳时显示
    if (networkStatus.isConnected && networkStatus.latencyMs < 500) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: networkStatus.connectionColor.withOpacity(0.1),
        border: Border.all(
          color: networkStatus.connectionColor.withOpacity(0.5),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            networkStatus.isConnected
                ? Icons.wifi_outlined
                : Icons.wifi_off_outlined,
            size: 16,
            color: networkStatus.connectionColor,
          ),
          const SizedBox(width: 4),
          Text(
            networkStatus.isConnected
                ? '${networkStatus.latencyMs}ms'
                : '断线',
            style: TextStyle(
              fontSize: 12,
              color: networkStatus.connectionColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// 网络状态横幅组件
/// 在网络断开时显示全屏横幅提示
class NetworkStatusBanner extends ConsumerWidget {
  final Widget child;

  const NetworkStatusBanner({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkStatus = ref.watch(networkStatusServiceProvider);

    return Column(
      children: [
        // 网络断开提示横幅
        if (!networkStatus.isConnected)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.red.shade700,
            child: Row(
              children: [
                const Icon(Icons.wifi_off, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '网络连接已断开，请检查网络设置',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                  onPressed: () {
                    networkStatus.refresh();
                  },
                  tooltip: '重试',
                ),
              ],
            ),
          ),

        // 网络较慢提示
        if (networkStatus.isConnected && networkStatus.latencyMs >= 1000)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            color: Colors.orange.shade700,
            child: Row(
              children: [
                const Icon(Icons.wifi_tethering_error, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '网络连接较慢 (${networkStatus.latencyMs}ms)，操作可能延迟',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

        Expanded(child: child),
      ],
    );
  }
}
