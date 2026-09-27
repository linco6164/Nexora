import 'package:flutter/material.dart';
import 'web_legal_page.dart';

class WithdrawalPage extends StatelessWidget {
  const WithdrawalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const WebLegalPage(
      title: 'Dreptul de retragere',
      sections: [
        LegalSection(
          title: '1. Dreptul de retragere',
          paragraphs: [
            'În cazul contractelor încheiate la distanță, consumatorii beneficiază, în situațiile prevăzute de legislația aplicabilă, de dreptul de a se retrage din contract fără a fi necesară justificarea deciziei.',
          ],
        ),

        LegalSection(
          title: '2. Termenul de retragere',
          paragraphs: [
            'Termenul și condițiile pentru exercitarea dreptului de retragere sunt cele prevăzute de legislația aplicabilă contractelor încheiate la distanță.',
          ],
        ),

        LegalSection(
          title: '3. Exercitarea dreptului de retragere',
          paragraphs: [
            'Pentru exercitarea dreptului de retragere, consumatorul trebuie să transmită o declarație neechivocă prin care informează comerciantul cu privire la decizia sa de retragere.',
            'Solicitarea poate fi transmisă prin datele de contact disponibile pe platforma Nexora.',
          ],
        ),

        LegalSection(
          title: '4. Formular de retragere',
          paragraphs: [
            'Consumatorul poate utiliza formularul-model de retragere pus la dispoziție de Nexora sau poate transmite o solicitare proprie care conține informațiile necesare identificării contractului și a deciziei de retragere.',
          ],
        ),

        LegalSection(
          title: '5. Returnarea produsului',
          paragraphs: [
            'După exercitarea dreptului de retragere, produsul trebuie returnat conform instrucțiunilor comunicate de Nexora și în condițiile prevăzute de legislația aplicabilă.',
          ],
        ),

        LegalSection(
          title: '6. Rambursarea',
          paragraphs: [
            'În cazul exercitării valabile a dreptului de retragere, sumele achitate vor fi rambursate conform legislației aplicabile și condițiilor tranzacției.',
          ],
        ),

        LegalSection(
          title: '7. Excepții',
          paragraphs: [
            'Dreptul de retragere nu se aplică în toate situațiile. Pot exista excepții prevăzute de legislația aplicabilă, în funcție de natura produsului sau serviciului.',
          ],
        ),

        LegalSection(
          title: '8. Contact',
          paragraphs: [
            'Pentru exercitarea dreptului de retragere sau pentru informații suplimentare, consumatorii pot utiliza datele de contact oficiale publicate pe platforma Nexora.',
          ],
        ),
      ],
    );
  }
}