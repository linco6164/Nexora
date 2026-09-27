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
          title: '1. Anularea unei comenzi',
          paragraphs: [
            'Cumpărătorul poate solicita anularea unei comenzi înainte ca aceasta să fie predată serviciului de livrare, în măsura în care procesarea comenzii permite acest lucru.',
          ],
        ),

        LegalSection(
          title: '2. Cum se solicită anularea',
          paragraphs: [
            'Solicitarea de anulare poate fi transmisă prin metodele de contact disponibile pe platforma Nexora.',
            'Solicitarea trebuie să conțină suficiente informații pentru identificarea comenzii.',
          ],
        ),

        LegalSection(
          title: '3. Comenzi deja expediate',
          paragraphs: [
            'În cazul în care comanda a fost deja predată transportatorului, anularea poate să nu mai poată fi procesată ca o anulare obișnuită.',
            'În această situație pot deveni aplicabile procedurile privind refuzul livrării sau dreptul de retragere, după caz.',
          ],
        ),

        LegalSection(
          title: '4. Rambursarea sumelor',
          paragraphs: [
            'În cazul în care anularea este acceptată și plata a fost efectuată, suma aferentă va fi rambursată conform metodei de plată și condițiilor aplicabile.',
          ],
        ),

        LegalSection(
          title: '5. Produse deja livrate',
          paragraphs: [
            'Pentru produsele deja primite de consumator se aplică, după caz, procedura privind dreptul de retragere și returul produsului.',
          ],
        ),

        LegalSection(
          title: '6. Situații speciale',
          paragraphs: [
            'În anumite situații, anularea poate fi limitată de stadiul procesării comenzii, de caracteristicile produsului sau de alte condiții aplicabile tranzacției.',
          ],
        ),
      ],
    );
  }
}