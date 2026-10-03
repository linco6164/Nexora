import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api_service.dart';
import 'web_legal_page.dart';

class WithdrawalPage extends StatefulWidget {
  const WithdrawalPage({super.key});

  @override
  State<WithdrawalPage> createState() => _WithdrawalPageState();
}

class _WithdrawalPageState extends State<WithdrawalPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _orderController = TextEditingController();
  final _productController = TextEditingController();
  final _detailsController = TextEditingController();

  bool _confirmed = false;
  bool _sending = false;
  String? _confirmationReference;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _orderController.dispose();
    _productController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Câmp obligatoriu';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final requiredMessage = _required(value);
    if (requiredMessage != null) return requiredMessage;

    final email = value!.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Introdu o adresă de e-mail validă';
    }
    return null;
  }

  String get _requestMessage =>
      '''
Cerere de retragere din contract

Nume: ${_nameController.text.trim()}
E-mail: ${_emailController.text.trim()}
Număr comandă: ${_orderController.text.trim()}
Produs: ${_productController.text.trim()}

Detalii suplimentare:
${_detailsController.text.trim().isEmpty ? 'Nu au fost furnizate.' : _detailsController.text.trim()}

Declar în mod neechivoc că doresc să mă retrag din contractul aferent comenzii indicate mai sus.
''';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_confirmed) {
      _showMessage('Confirmă declarația de retragere pentru a continua.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _sending = true);

    try {
      final isLoggedIn = await ApiService.isLoggedIn();

      if (isLoggedIn) {
        final response = await ApiService.createSupportTicket(
          subject:
              'Cerere de retragere - comanda ${_orderController.text.trim()}',
          category: 'orders',
          message: _requestMessage,
        );

        if (!mounted) return;
        final ticket = response['ticket'] ?? response['data'];
        final reference = ticket is Map
            ? (ticket['_id'] ?? ticket['id'])?.toString()
            : null;
        setState(() {
          _confirmationReference = reference?.isNotEmpty == true
              ? reference
              : 'înregistrată în Cont > Suport';
        });
        _clearForm();
        _showMessage(
          'Cererea a fost înregistrată. O găsești și în Cont > Suport.',
        );
        return;
      }

      final uri = Uri(
        scheme: 'mailto',
        path: 'contact@nx-store.com',
        queryParameters: {
          'subject':
              'Cerere de retragere - comanda ${_orderController.text.trim()}',
          'body': _requestMessage,
        },
      );

      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        throw const FormatException(
          'Nu s-a putut deschide aplicația de e-mail.',
        );
      }

      if (!mounted) return;
      setState(() => _confirmationReference = null);
      _showMessage(
        'Cererea este pregătită în aplicația de e-mail. Apasă Trimite pentru a o înregistra.',
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException
          ? error.message
          : 'Cererea nu a putut fi trimisă. Scrie-ne la contact@nx-store.com.';
      _showMessage(message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _orderController.clear();
    _productController.clear();
    _detailsController.clear();
    setState(() => _confirmed = false);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  InputDecoration _decoration(String label, IconData icon) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: theme.colorScheme.onSurface.withValues(alpha: .035),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: theme.dividerColor.withValues(alpha: .18),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WebLegalPage(
      title: 'Retur / dreptul de retragere',
      sections: const [
        LegalSection(
          title: '1. Termenul de retragere',
          paragraphs: [
            'Consumatorul se poate retrage dintr-un contract încheiat la distanță, fără să își justifice decizia, în termen de 14 zile calendaristice, cu excepția situațiilor prevăzute de lege.',
            'Pentru produse, termenul curge din ziua în care consumatorul sau persoana indicată de acesta, alta decât curierul, intră în posesia fizică a produsului. Pentru o comandă cu produse livrate separat, termenul curge de la primirea ultimului produs.',
          ],
        ),
        LegalSection(
          title: '2. Cum anunți retragerea',
          paragraphs: [
            'Completează formularul online de mai jos înainte de expirarea termenului. Utilizatorii autentificați primesc un tichet în Cont > Suport; vizitatorilor li se deschide un e-mail precompletat către contact@nx-store.com.',
            'Poți trimite și o declarație neechivocă direct la contact@nx-store.com. Menționează numărul comenzii, numele, adresa de e-mail folosită la comandă și produsul returnat. Nu este obligatoriu să precizezi motivul.',
          ],
        ),
        LegalSection(
          title: '3. Returnarea produsului',
          paragraphs: [
            'După transmiterea retragerii, vei primi datele vânzătorului și instrucțiunile de retur. Produsul trebuie expediat fără întârziere nejustificată și în cel mult 14 zile de la comunicarea deciziei de retragere.',
            'Consumatorul suportă costul direct al returului, exceptând cazul în care vânzătorul acceptă să îl suporte sau nu a informat consumatorul despre acest cost. Păstrează dovada predării coletului.',
          ],
        ),
        LegalSection(
          title: '4. Rambursarea',
          paragraphs: [
            'Sumele datorate se rambursează fără întârziere nejustificată și cel târziu în 14 zile de la informarea profesionistului despre retragere, prin aceeași metodă de plată, dacă nu se convine altfel.',
            'Rambursarea poate fi amânată până la recepționarea produsului sau până la primirea dovezii că produsul a fost expediat, luându-se în considerare data cea mai apropiată. Costul suplimentar al unei livrări mai scumpe decât varianta standard nu se rambursează.',
          ],
        ),
        LegalSection(
          title: '5. Starea produsului',
          paragraphs: [
            'Consumatorul răspunde numai pentru diminuarea valorii produsului rezultată din manipulări care depășesc ceea ce este necesar pentru stabilirea naturii, caracteristicilor și funcționării acestuia.',
          ],
        ),
        LegalSection(
          title: '6. Excepții',
          paragraphs: [
            'Conform art. 16 din OUG nr. 34/2014, pot fi exceptate, între altele, produsele realizate după specificațiile consumatorului sau clar personalizate, produsele perisabile și produsele sigilate care nu pot fi returnate din motive de sănătate ori igienă după desigilare.',
            'Excepția aplicabilă unui produs trebuie indicată clar în pagina produsului sau înainte de comandă.',
          ],
        ),
      ],
      bottom: _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: .045),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: .18),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Formular online de retragere',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Câmpurile marcate sunt necesare pentru identificarea comenzii. Motivul returului este opțional.',
              style: TextStyle(
                height: 1.5,
                color: theme.colorScheme.onSurface.withValues(alpha: .68),
              ),
            ),
            const SizedBox(height: 22),
            if (_confirmationReference != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: .28),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Cerere înregistrată. Referință: $_confirmationReference',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 700;
                final name = TextFormField(
                  controller: _nameController,
                  validator: _required,
                  textInputAction: TextInputAction.next,
                  decoration: _decoration(
                    'Nume complet *',
                    Icons.person_outline,
                  ),
                );
                final email = TextFormField(
                  controller: _emailController,
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: _decoration('E-mail *', Icons.email_outlined),
                );

                if (!isWide) {
                  return Column(
                    children: [name, const SizedBox(height: 14), email],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: name),
                    const SizedBox(width: 14),
                    Expanded(child: email),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _orderController,
              validator: _required,
              textInputAction: TextInputAction.next,
              decoration: _decoration(
                'Numărul comenzii *',
                Icons.receipt_long_outlined,
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _productController,
              validator: _required,
              textInputAction: TextInputAction.next,
              decoration: _decoration(
                'Produsul returnat *',
                Icons.inventory_2_outlined,
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _detailsController,
              minLines: 3,
              maxLines: 5,
              decoration: _decoration(
                'Detalii sau motiv (opțional)',
                Icons.notes_outlined,
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _confirmed,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: _sending
                  ? null
                  : (value) => setState(() => _confirmed = value ?? false),
              title: const Text(
                'Declar în mod neechivoc că doresc retragerea din contractul aferent comenzii indicate.',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _sending ? null : _submit,
              icon: _sending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(_sending ? 'Se trimite...' : 'Trimite cererea'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Alternativ: contact@nx-store.com • 0720 249 911',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: .6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
