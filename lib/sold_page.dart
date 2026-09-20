import 'package:flutter/material.dart';

import 'api_service.dart';

class SoldPage extends StatefulWidget {
  const SoldPage({super.key});

  @override
  State<SoldPage> createState() => _SoldPageState();
}

class _SoldPageState extends State<SoldPage> {
  bool _isLoading = true;
  double _balance = 0.0;
  String? _error;

  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await ApiService.getCurrentUser();
      final transactions = await ApiService.getWalletTransactions();

      final balance = (user['balance'] as num?)?.toDouble() ?? 0.0;

      if (!mounted) return;

      setState(() {
        _balance = balance;
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('LOAD WALLET ERROR: $e');

      if (!mounted) return;

      setState(() {
        _error = 'Nu am putut încărca soldul.';
        _isLoading = false;
      });
    }
  }

  String _formatBalance(double value) {
    return '${value.toStringAsFixed(2).replaceAll('.', ',')} RON';
  }

  void _openWithdraw() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) {
        return _WithdrawSheet(
          balance: _balance,
          onContinue: (amount, iban, accountName) {
            _startWithdrawal(amount, iban, accountName);
          },
        );
      },
    );
  }

  Future<void> _startWithdrawal(
    double amount,
    String iban,
    String accountName,
  ) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.withdrawMoney(
        amount: amount,
        iban: iban,
        accountName: accountName,
      );

      final newBalance = (result['balance'] as num?)?.toDouble() ?? _balance;

      if (!mounted) return;

      setState(() {
        _balance = newBalance;
        _isLoading = false;
      });

      await _loadWallet();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cererea de retragere a fost trimisă și așteaptă aprobarea.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('ApiException: ', '')),
        ),
      );
    }
  }

  void _openPurchase() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alege un produs pentru a continua cumpărarea.'),
      ),
    );
  }

  String _transactionTypeLabel(String type) {
    switch (type) {
      case 'purchase':
        return 'Cumpărare produs';
      case 'withdrawal':
        return 'Retragere';
      case 'refund':
        return 'Rambursare';
      case 'fee':
        return 'Comision';
      default:
        return 'Tranzacție';
    }
  }

  String _transactionStatusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Finalizată';
      case 'pending':
        return 'În așteptare';
      case 'failed':
        return 'Eșuată';
      case 'rejected':
        return 'Respinsă';
      default:
        return status.isEmpty ? 'Necunoscut' : status;
    }
  }

  IconData _transactionIcon(String type) {
    switch (type) {
      case 'purchase':
        return Icons.shopping_bag_outlined;
      case 'withdrawal':
        return Icons.account_balance_outlined;
      case 'refund':
        return Icons.undo_rounded;
      case 'fee':
        return Icons.percent_rounded;
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }

  bool _isPositiveTransaction(String type) {
    return type == 'refund';
  }

  Widget _buildEmptyTransactions(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 44,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'Nu ai încă tranzacții',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Cumpărăturile și retragerile tale vor apărea aici.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactions(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _transactions.length,
        separatorBuilder: (_, _) =>
            Divider(height: 1, color: colorScheme.outlineVariant),
        itemBuilder: (context, index) {
          final transaction = _transactions[index];

          final type = transaction['type']?.toString() ?? '';

          final status = transaction['status']?.toString() ?? '';

          final description =
              transaction['description']?.toString() ??
              _transactionTypeLabel(type);

          final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;

          final isPositive = _isPositiveTransaction(type);

          final amountText =
              '${isPositive ? '+' : '-'}${_formatBalance(amount)}';

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: CircleAvatar(
              backgroundColor: colorScheme.surface,
              child: Icon(_transactionIcon(type), color: colorScheme.primary),
            ),
            title: Text(
              description,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              _transactionStatusLabel(status),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Text(
              amountText,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isPositive ? Colors.green : colorScheme.onSurface,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sold'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadWallet,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizează',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadWallet,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            // SOLD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 42,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sold disponibil',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_isLoading)
                    const SizedBox(
                      height: 42,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    Column(
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colorScheme.error),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _loadWallet,
                          child: const Text('Încearcă din nou'),
                        ),
                      ],
                    )
                  else
                    Text(
                      _formatBalance(_balance),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ACTIUNI
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _openPurchase,
                      icon: const Icon(Icons.shopping_bag_outlined),
                      label: const Text(
                        'Cumpără produse',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading || _balance <= 0
                          ? null
                          : _openWithdraw,
                      icon: const Icon(Icons.account_balance_outlined),
                      label: const Text(
                        'Retrage bani',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ISTORIC
            Text(
              'Istoric tranzacții',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _transactions.isEmpty
                ? _buildEmptyTransactions(context)
                : _buildTransactions(context),
          ],
        ),
      ),
    );
  }
}

class _WithdrawSheet extends StatefulWidget {
  final double balance;

  final void Function(double amount, String iban, String accountName)
  onContinue;

  const _WithdrawSheet({required this.balance, required this.onContinue});

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  late final TextEditingController _amountController;

  late final TextEditingController _ibanController;

  late final TextEditingController _accountNameController;

  @override
  void initState() {
    super.initState();

    _amountController = TextEditingController();

    _ibanController = TextEditingController();

    _accountNameController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _ibanController.dispose();
    _accountNameController.dispose();

    super.dispose();
  }

  void _continue() {
    final amount = double.tryParse(
      _amountController.text.trim().replaceAll(',', '.'),
    );

    final iban = _ibanController.text.trim();

    final accountName = _accountNameController.text.trim();

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Introdu o sumă validă.')));
      return;
    }

    if (amount > widget.balance) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Sold insuficient.')));
      return;
    }

    if (iban.length < 15) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Introdu un IBAN valid.')));
      return;
    }

    if (accountName.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introdu numele titularului.')),
      );
      return;
    }

    Navigator.pop(context);

    widget.onContinue(amount, iban, accountName);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          8,
          24,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Retrage bani',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Banii vor fi transferați în contul bancar asociat.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Sumă',
                  hintText: 'Ex. 100',
                  suffixText: 'RON',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _ibanController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'IBAN',
                  hintText: 'RO49AAAA1B31007593840000',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _accountNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nume titular cont',
                  hintText: 'Nume Prenume',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _continue,
                  child: const Text(
                    'Continuă',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
