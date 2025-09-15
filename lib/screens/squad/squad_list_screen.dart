import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/squad_provider.dart';
import '../../models/squad.dart';
import '../../utils/app_theme.dart';

class SquadListScreen extends StatefulWidget {
  const SquadListScreen({super.key});

  @override
  State<SquadListScreen> createState() => _SquadListScreenState();
}

class _SquadListScreenState extends State<SquadListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SquadProvider>().loadSquads();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('スカッド管理'),
        actions: [
          IconButton(
            onPressed: () => context.push('/squads/add'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.darkGradient,
        ),
        child: Consumer<SquadProvider>(
          builder: (context, squadProvider, child) {
            if (squadProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (squadProvider.squads.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.group,
                      size: 80,
                      color: AppTheme.lightGray,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'スカッドが登録されていません',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '最初のスカッドを登録しましょう',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.lightGray,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/squads/add'),
                      icon: const Icon(Icons.add),
                      label: const Text('スカッドを追加'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: squadProvider.squads.length,
              itemBuilder: (context, index) {
                final squad = squadProvider.squads[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      onTap: () => context.push('/squads/detail', extra: {'squad': squad}),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.cyan,
                      child: Text(
                        squad.formation.split('-').first,
                        style: const TextStyle(
                          color: AppTheme.primaryBlack,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      squad.name,
                      style: const TextStyle(
                        color: AppTheme.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'フォーメーション: ${squad.formation}',
                          style: const TextStyle(
                            color: AppTheme.lightGray,
                          ),
                        ),
                        if (squad.memo.isNotEmpty)
                          Text(
                            squad.memo,
                            style: const TextStyle(
                              color: AppTheme.lightGray,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            context.push('/squads/edit', extra: {'squad': squad});
                            break;
                          case 'delete':
                            _showDeleteDialog(squad);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 8),
                              Text('編集'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 16, color: AppTheme.red),
                              SizedBox(width: 8),
                              Text('削除', style: TextStyle(color: AppTheme.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/squads/add'),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteDialog(Squad squad) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('スカッドを削除'),
        content: Text('「${squad.name}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final squadProvider = context.read<SquadProvider>();
              await squadProvider.deleteSquad(squad.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('スカッドを削除しました'),
                    backgroundColor: AppTheme.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.red,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}
