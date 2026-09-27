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
          title: '1. Informații generale',
          paragraphs: [
            'Produsele comandate prin intermediul platformei Nexora sunt livrate la adresa indicată de cumpărător în timpul procesului de comandă.',
          ],
        ),

        LegalSection(
          title: '2. Metode de livrare',
          paragraphs: [
            'Metodele de livrare disponibile sunt afișate în funcție de configurația și disponibilitatea serviciilor de livrare.',
            'Integrarea cu serviciile de curierat Sameday, FAN Courier și GLS va fi disponibilă după configurarea API-urilor corespunzătoare.',
          ],
        ),

        LegalSection(
          title: '3. Costul livrării',
          paragraphs: [
            'Costul livrării este comunicat cumpărătorului înainte de finalizarea comenzii, atunci când acesta este disponibil.',
          ],
        ),

        LegalSection(
          title: '4. Termenul de livrare',
          paragraphs: [
            'Termenul estimat de livrare poate varia în funcție de produs, destinație, metoda de livrare și disponibilitatea serviciului de curierat.',
          ],
        ),

        LegalSection(
          title: '5. Întârzieri',
          paragraphs: [
            'Termenele de livrare pot fi afectate de factori independenți de platformă, inclusiv condiții meteorologice, perioade aglomerate sau situații operaționale ale transportatorului.',
          ],
        ),

        LegalSection(
          title: '6. Verificarea coletului',
          paragraphs: [
            'Cumpărătorul este încurajat să verifice starea coletului la primire și să semnaleze eventualele probleme conform procedurilor transportatorului și politicilor aplicabile.',
          ],
        ),

        LegalSection(
          title: '7. Colet nelivrat sau refuzat',
          paragraphs: [
            'În cazul în care un colet nu poate fi livrat sau este refuzat, soluționarea situației se va realiza în funcție de stadiul comenzii și condițiile aplicabile acesteia.',
          ],
        ),
      ],
    );
  }
}