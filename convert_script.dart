import 'dart:io';

void main() {
  final file = File('/Users/anuragchakraborty/Code/ios Projects/illish/lib/screens/recognition_sheet.dart');
  var content = file.readAsStringSync();

  // Convert to StatefulWidget
  content = content.replaceFirst(
    'class RecognitionSheet extends StatelessWidget {',
    'class RecognitionSheet extends StatefulWidget {\n'
    '  final Map<String, dynamic> aiData;\n'
    '  const RecognitionSheet({super.key, required this.aiData});\n'
    '\n'
    '  @override\n'
    '  State<RecognitionSheet> createState() => _RecognitionSheetState();\n'
    '}\n'
    '\n'
    'class _RecognitionSheetState extends State<RecognitionSheet> with SingleTickerProviderStateMixin {\n'
    '  late AnimationController _animController;\n'
    '  bool _isUnlocking = false;\n'
    '\n'
    '  @override\n'
    '  void initState() {\n'
    '    super.initState();\n'
    '    _animController = AnimationController(\n'
    '      vsync: this,\n'
    '      duration: const Duration(milliseconds: 1500),\n'
    '    )..repeat();\n' // Continuous shimmer
    '  }\n'
    '\n'
    '  @override\n'
    '  void dispose() {\n'
    '    _animController.dispose();\n'
    '    super.dispose();\n'
    '  }\n'
    '\n'
    '  void _handleAction() async {\n'
    '    if (!AppConfig.kIsPremiumUser) {\n'
    '      setState(() => _isUnlocking = true);\n'
    '      await Future.delayed(const Duration(milliseconds: 400));\n'
    '    }\n'
    '    if (!mounted) return;\n'
    '    Navigator.pop(context);\n'
    '    Navigator.push(context, PageRouteBuilder(\n'
    '      pageBuilder: (context, animation, secondaryAnimation) => PaymentScreen(aiData: widget.aiData),\n'
    '      transitionsBuilder: (context, animation, secondaryAnimation, child) {\n'
    '        const begin = Offset(0.0, 1.0);\n'
    '        const end = Offset.zero;\n'
    '        const curve = Curves.easeOutCubic;\n'
    '        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));\n'
    '        return SlideTransition(position: animation.drive(tween), child: child);\n'
    '      },\n'
    '    ));\n'
    '  }'
  );

  // Remove the old fields
  content = content.replaceFirst(
    '  final Map<String, dynamic> aiData;\n'
    '\n'
    '  const RecognitionSheet({super.key, required this.aiData});\n',
    ''
  );

  // Replace aiData with widget.aiData everywhere inside build
  content = content.replaceAll('aiData[', 'widget.aiData[');

  // Replace GestureDetector tap with _handleAction
  content = content.replaceFirst(
    '                    onTap: () {\n'
    '                      Navigator.pop(context);\n'
    '                      Navigator.push(context, PageRouteBuilder(\n'
    '                        pageBuilder: (context, animation, secondaryAnimation) => PaymentScreen(aiData: widget.aiData),\n'
    '                        transitionsBuilder: (context, animation, secondaryAnimation, child) {\n'
    '                          const begin = Offset(0.0, 1.0);\n'
    '                          const end = Offset.zero;\n'
    '                          const curve = Curves.easeOutCubic;\n'
    '                          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));\n'
    '                          return SlideTransition(position: animation.drive(tween), child: child);\n'
    '                        },\n'
    '                      ));\n'
    '                    },',
    '                    onTap: _handleAction,'
  );

  // Replace onVerticalDragEnd action
  content = content.replaceFirst(
    '        if (details.primaryVelocity != null && details.primaryVelocity! < -300) {\n'
    '          Navigator.pop(context);\n'
    '          Navigator.push(context, PageRouteBuilder(\n'
    '            pageBuilder: (context, animation, secondaryAnimation) => PaymentScreen(aiData: widget.aiData),\n'
    '            transitionsBuilder: (context, animation, secondaryAnimation, child) {\n'
    '              const begin = Offset(0.0, 1.0);\n'
    '              const end = Offset.zero;\n'
    '              const curve = Curves.easeOutCubic;\n'
    '              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));\n'
    '              return SlideTransition(position: animation.drive(tween), child: child);\n'
    '            },\n'
    '          ));\n'
    '        }',
    '        if (details.primaryVelocity != null && details.primaryVelocity! < -300) {\n'
    '          _handleAction();\n'
    '        }'
  );
  
  // Replace the lock icon logic
  final lockIconOld = 
    '                            Container(\n'
    '                              padding: const EdgeInsets.all(4),\n'
    '                              decoration: BoxDecoration(\n'
    '                                shape: BoxShape.circle,\n'
    '                                border: Border.all(color: AppTheme.neonCyan, width: 1.5),\n'
    '                              ),\n'
    '                              child: const Icon(Icons.lock_outline, color: AppTheme.neonCyan, size: 14),\n'
    '                            ),';
    
  final newIconLogic = 
    '                            if (AppConfig.kIsPremiumUser)\n'
    '                              AnimatedBuilder(\n'
    '                                animation: _animController,\n'
    '                                builder: (context, child) {\n'
    '                                  return Container(\n'
    '                                    padding: const EdgeInsets.all(4),\n'
    '                                    decoration: BoxDecoration(\n'
    '                                      shape: BoxShape.circle,\n'
    '                                      color: Colors.greenAccent.withOpacity(0.15),\n'
    '                                      border: Border.all(\n'
    '                                        color: Colors.greenAccent.withOpacity(0.4 + 0.6 * _animController.value),\n'
    '                                        width: 1.5\n'
    '                                      ),\n'
    '                                      boxShadow: [\n'
    '                                        BoxShadow(\n'
    '                                          color: Colors.greenAccent.withOpacity(0.3 * _animController.value),\n'
    '                                          blurRadius: 8,\n'
    '                                          spreadRadius: 2,\n'
    '                                        ),\n'
    '                                      ],\n'
    '                                    ),\n'
    '                                    child: const Icon(Icons.check, color: Colors.greenAccent, size: 14),\n'
    '                                  );\n'
    '                                },\n'
    '                              )\n'
    '                            else\n'
    '                              Container(\n'
    '                                padding: const EdgeInsets.all(4),\n'
    '                                decoration: BoxDecoration(\n'
    '                                  shape: BoxShape.circle,\n'
    '                                  border: Border.all(color: AppTheme.neonCyan, width: 1.5),\n'
    '                                ),\n'
    '                                child: AnimatedSwitcher(\n'
    '                                  duration: const Duration(milliseconds: 300),\n'
    '                                  transitionBuilder: (Widget child, Animation<double> animation) {\n'
    '                                    return ScaleTransition(scale: animation, child: child);\n'
    '                                  },\n'
    '                                  child: Icon(\n'
    '                                    _isUnlocking ? Icons.lock_open : Icons.lock_outline,\n'
    '                                    key: ValueKey<bool>(_isUnlocking),\n'
    '                                    color: AppTheme.neonCyan,\n'
    '                                    size: 14,\n'
    '                                  ),\n'
    '                                ),\n'
    '                              ),';
                              
  content = content.replaceFirst(lockIconOld, newIconLogic);

  file.writeAsStringSync(content);
}
