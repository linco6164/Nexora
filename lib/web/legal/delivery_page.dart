import 'package:flutter/material.dart';
import 'web_legal_page.dart';

class DeliveryPage extends StatelessWidget {
  const DeliveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const WebLegalPage(
      title: 'Politica de livrare',
      sections: [
        LegalSection(
          title: '1. Unde livrăm',
          paragraphs: [
            'Produsele comandate prin Nexora sunt livrate în România, la adresa selectată sau introdusă de cumpărător în checkout. Cumpărătorul trebuie să verifice numele, numărul de telefon și adresa înainte de confirmarea comenzii.',
          ],
        ),

        LegalSection(
          title: '2. Metode de livrare',
          paragraphs: [
            'Livrarea la adresă se realizează prin curier. În checkout sunt afișate opțiunile disponibile pentru comandă: Sameday, FAN Courier și GLS.',
            'Metoda aleasă și adresa de livrare apar în sumarul comenzii înainte de efectuarea plății.',
          ],
        ),

        LegalSection(
          title: '3. Costul livrării',
          paragraphs: [
            'Costul fiecărei opțiuni de curierat este afișat separat în checkout. Înainte de plată, cumpărătorul vede prețul produsului, costul livrării și totalul final al comenzii.',
          ],
        ),

        LegalSection(
          title: '4. Termenul de livrare',
          paragraphs: [
            'Termenul estimat este de 2-5 zile lucrătoare de la confirmarea comenzii: 1-2 zile lucrătoare pentru pregătirea și predarea coletului de către vânzător, apoi 1-3 zile lucrătoare pentru transport.',
            'Termenul poate fi diferit dacă pagina produsului sau confirmarea comenzii indică în mod clar un alt interval. În lipsa unui termen convenit separat, livrarea se efectuează fără întârziere nejustificată și în cel mult 30 de zile de la încheierea contractului, conform OUG nr. 34/2014.',
          ],
        ),

        LegalSection(
          title: '5. Întârzieri',
          paragraphs: [
            'Termenul estimat poate fi afectat de zile nelucrătoare, localități greu accesibile, condiții meteo, perioade aglomerate sau întârzieri operaționale ale curierului. Cumpărătorul este informat prin datele de contact asociate comenzii atunci când este cunoscută o întârziere importantă.',
          ],
        ),

        LegalSection(
          title: '6. Verificarea coletului',
          paragraphs: [
            'La primire, cumpărătorul trebuie să verifice integritatea ambalajului. Un colet deteriorat sau o neconformitate se semnalează cât mai repede vânzătorului și echipei Nexora la contact@nx-store.com ori prin Cont > Suport, menționând numărul comenzii și atașând fotografii relevante.',
          ],
        ),

        LegalSection(
          title: '7. Colet nelivrat sau refuzat',
          paragraphs: [
            'Dacă livrarea nu poate fi efectuată din cauza unei adrese sau a unui număr de telefon incorect, coletul poate fi returnat vânzătorului. Pentru reexpediere poate fi solicitat un nou cost de transport, comunicat în prealabil cumpărătorului.',
            'Refuzarea coletului nu înlocuiește în toate situațiile notificarea clară de retragere. Pentru o evidență corectă, cumpărătorul trebuie să folosească formularul online „Retur / retragere” sau adresa contact@nx-store.com.',
          ],
        ),
      ],
    );
  }
}
