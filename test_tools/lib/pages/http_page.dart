import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

class HttpPage extends StatefulWidget {
  const HttpPage({super.key});

  @override
  State<HttpPage> createState() => _HttpPageState();
}

class _HttpPageState extends State<HttpPage> {
  final _urlController = TextEditingController(text: 'https://jsonplaceholder.typicode.com/posts');
  final _headersController = TextEditingController(text: '{"Content-Type": "application/json"}');
  final _bodyController = TextEditingController(text: '{"title": "hello"}');
  String _method = 'GET';
  String _response = '';
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _method,
              decoration: const InputDecoration(labelText: '请求方法', border: OutlineInputBorder()),
              items: ['GET', 'POST', 'PUT', 'DELETE']
                  .map((method) => DropdownMenuItem(value: method, child: Text(method)))
                  .toList(),
              onChanged: (value) => setState(() => _method = value ?? 'GET'),
            ),
            const SizedBox(height: 8),
            _buildTextField(_urlController, 'URL', keyboardType: TextInputType.url),
            const SizedBox(height: 8),
            _buildTextField(_headersController, 'Headers (JSON)', maxLines: 4),
            const SizedBox(height: 8),
            _buildTextField(_bodyController, 'Body', maxLines: 6),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _busy ? null : () async {
                      setState(() => _busy = true);
                      try {
                        final uri = Uri.parse(_urlController.text.trim());
                        Map<String, String> headers = {};
                        try {
                          final decoded = json.decode(_headersController.text.trim());
                          if (decoded is Map<String, dynamic>) {
                            headers = decoded.map((key, value) => MapEntry(key, value.toString()));
                          }
                        } catch (_) {
                          headers = {};
                        }
                        final result = await state.httpService.sendRequest(
                          method: _method,
                          uri: uri,
                          headers: headers,
                          body: _method == 'GET' || _method == 'DELETE' ? null : _bodyController.text.trim(),
                        );
                        setState(() => _response = result);
                        await state.saveHttpUrl(_urlController.text.trim());
                      } catch (error) {
                        setState(() => _response = '请求失败: $error');
                      } finally {
                        setState(() => _busy = false);
                      }
                    },
                    child: Text(_busy ? '请求中...' : '发送请求'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _busy
                        ? null
                        : () {
                            setState(() => _response = '');
                          },
                    child: const Text('清空响应'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (state.savedHttpUrls.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('保存的 HTTP 地址', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: state.savedHttpUrls
                        .map((url) => ActionChip(
                              label: Text(url, overflow: TextOverflow.ellipsis),
                              onPressed: () => setState(() => _urlController.text = url),
                            ))
                        .toList(),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            const Align(alignment: Alignment.centerLeft, child: Text('响应内容', style: TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_response.isEmpty ? '等待请求结果...' : _response),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    );
  }
}
