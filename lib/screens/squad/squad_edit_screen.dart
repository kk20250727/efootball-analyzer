import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/squad_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/squad.dart';
import '../../utils/app_theme.dart';

class SquadEditScreen extends StatefulWidget {
  final Squad? squad;

  const SquadEditScreen({
    super.key,
    this.squad,
  });

  @override
  State<SquadEditScreen> createState() => _SquadEditScreenState();
}

class _SquadEditScreenState extends State<SquadEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _formationController = TextEditingController();
  final _memoController = TextEditingController();
  bool _isSaving = false;

  final List<String> _commonFormations = [
    '4-3-3',
    '4-4-2',
    '3-5-2',
    '4-2-3-1',
    '3-4-3',
    '4-1-4-1',
    '5-3-2',
    '4-3-2-1',
    '3-2-3-2',
    '4-5-1',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.squad != null) {
      _nameController.text = widget.squad!.name;
      _formationController.text = widget.squad!.formation;
      _memoController.text = widget.squad!.memo;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _formationController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _saveSquad() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final authProvider = context.read<AuthProvider>();
    final squadProvider = context.read<SquadProvider>();
    final user = authProvider.user;

    if (user == null) {
      setState(() {
        _isSaving = false;
      });
      return;
    }

    try {
      final squad = Squad(
        id: widget.squad?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.id,
        name: _nameController.text.trim(),
        formation: _formationController.text.trim(),
        memo: _memoController.text.trim(),
        createdAt: widget.squad?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.squad != null) {
        await squadProvider.updateSquad(squad);
      } else {
        await squadProvider.addSquad(squad);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.squad != null ? 'スカッドを更新しました' : 'スカッドを追加しました'),
            backgroundColor: AppTheme.green,
          ),
        );
        context.go('/squad-list');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存に失敗しました: $e'),
            backgroundColor: AppTheme.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.squad != null ? 'スカッドを編集' : 'スカッドを追加'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveSquad,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                    ),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.darkGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ヘッダー
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.primaryGradient,
                        boxShadow: [
                        BoxShadow(
                          color: AppTheme.cyan.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                        ],
                      ),
                      child: const Icon(
                        Icons.group,
                        size: 40,
                        color: AppTheme.primaryBlack,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    widget.squad != null ? 'スカッドを編集' : '新しいスカッドを追加',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppTheme.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // スカッド名
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'スカッド名',
                      hintText: '例: ポゼッション用4-3-3',
                      prefixIcon: Icon(Icons.label),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'スカッド名を入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // フォーメーション
                  TextFormField(
                    controller: _formationController,
                    decoration: InputDecoration(
                      labelText: 'フォーメーション',
                      hintText: '例: 4-3-3',
                      prefixIcon: const Icon(Icons.sports_soccer),
                      suffixIcon: PopupMenuButton<String>(
                        icon: const Icon(Icons.arrow_drop_down),
                        onSelected: (formation) {
                          _formationController.text = formation;
                        },
                        itemBuilder: (context) => _commonFormations.map((formation) {
                          return PopupMenuItem<String>(
                            value: formation,
                            child: Text(formation),
                          );
                        }).toList(),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'フォーメーションを入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // メモ
                  TextFormField(
                    controller: _memoController,
                    decoration: const InputDecoration(
                      labelText: 'メモ（任意）',
                      hintText: '使用感やコンセプトなどを記述',
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),

                  // 保存ボタン
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveSquad,
                      child: _isSaving
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.primaryBlack,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('保存中...'),
                              ],
                            )
                          : Text(widget.squad != null ? '更新' : '追加'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // キャンセルボタン
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => context.go('/squad-list'),
                      child: const Text('キャンセル'),
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
