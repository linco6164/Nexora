import 'package:flutter/material.dart';
import 'web_legal_page.dart';

class CancellationPage extends StatelessWidget {
  const CancellationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const WebLegalPage(
      title: 'Politica de anulare a comenzii',
      sections: [
        LegalSection(
          title: '1. Când poate fi anulată comanda',
          paragraphs: [
            'Cumpărătorul poate solicita anularea comenzii înainte ca vânzătorul să predea coletul curierului. Cererea este verificată în funcție de stadiul real al comenzii.',
          ],
        ),

        LegalSection(
          title: '2. Cum se solicită anularea',
          paragraphs: [
            'Solicitarea se transmite prin Cont > Suport, categoria „Comenzi”, sau prin e-mail la contact@nx-store.com. Mesajul trebuie să conțină numărul comenzii, numele cumpărătorului și produsul comandat.',
            'Confirmarea primirii solicitării este transmisă prin tichet sau e-mail. Cererile sunt analizate, de regulă, în maximum o zi lucrătoare.',
          ],
        ),

        LegalSection(
          title: '3. Comenzi deja expediate',
          paragraphs: [
            'După predarea coletului curierului, comanda nu mai poate fi oprită întotdeauna. Consumatorul poate comunica decizia de retragere și poate returna produsul conform politicii „Retur / retragere”.',
          ],
        ),

        LegalSection(
          title: '4. Rambursarea sumelor',
          paragraphs: [
            'Dacă anularea este acceptată înainte de expediere și plata a fost efectuată, suma încasată se rambursează prin aceeași metodă de plată. Inițierea rambursării se face fără întârziere nejustificată; timpul până la afișarea banilor depinde și de banca emitentă.',
          ],
        ),

        LegalSection(
          title: '5. Produse deja livrate',
          paragraphs: [
            'Pentru produsele deja primite nu se mai folosește procedura de anulare. Consumatorul poate exercita dreptul de retragere în termenul și condițiile descrise în pagina „Retur / retragere”.',
          ],
        ),

        LegalSection(
          title: '6. Situații speciale',
          paragraphs: [
            'Anularea unei comenzi înainte de expediere și dreptul legal de retragere după primirea produsului sunt proceduri diferite. Excepțiile legale de la dreptul de retragere sunt prezentate în pagina dedicată retragerii.',
          ],
        ),
      ],
    );
  }
}
