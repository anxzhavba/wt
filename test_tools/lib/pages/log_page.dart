import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

class LogPage extends StatelessWidget {
  const LogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: state.logs.isEmpty ? null : state.clearLogs,
                    child: const Text('清空日志'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: state.logs.isEmpty
                        ? null
                        : () async {
                            final path = await state.exportLogs();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('日志已导出到 $path')));
                            }
                          },
                    child: const Text('导出日志'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 0),
          Expanded(
            child: state.logs.isEmpty
                ? const Center(child: Text('暂无日志'))
                : ListView.separated(
                    reverse: false,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.logs.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      return Text(state.logs[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
