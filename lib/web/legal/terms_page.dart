import 'package:flutter/material.dart';
import 'web_legal_page.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const WebLegalPage(
      title: 'Termeni și condiții',
      sections: [
        LegalSection(
          title: '1. Informații generale',
          paragraphs: [
            'Prezentele Termeni și condiții reglementează utilizarea platformei Nexora și a serviciilor disponibile prin intermediul acesteia.',
            'Platforma este operată de Nexora Store S.R.L.',
          ],
        ),

        LegalSection(
          title: '2. Utilizarea platformei',
          paragraphs: [
            'Utilizatorii trebuie să furnizeze informații reale, complete și actualizate atunci când își creează un cont sau utilizează serviciile platformei.',
            'Utilizatorul este responsabil pentru păstrarea confidențialității datelor de autentificare.',
          ],
        ),

        LegalSection(
          title: '3. Produse și listări',
          paragraphs: [
            'Produsele și listările disponibile pe platformă sunt prezentate împreună cu informațiile relevante disponibile la momentul publicării.',
            'Disponibilitatea, prețul și caracteristicile produselor pot fi actualizate.',
          ],
        ),

        LegalSection(
          title: '4. Comenzi și plată',
          paragraphs: [
            'O comandă este inițiată prin parcurgerea procesului de checkout și confirmarea acesteia.',
            'Plățile online sunt procesate prin furnizorii de servicii de plată integrați în platformă.',
          ],
        ),

        LegalSection(
          title: '5. Livrare',
          paragraphs: [
            'Livrarea comenzilor se realizează prin metodele de livrare disponibile în momentul plasării comenzii.',
            'Costurile și condițiile de livrare sunt afișate înainte de finalizarea comenzii, atunci când aceste informații sunt disponibile.',
          ],
        ),

        LegalSection(
          title: '6. Anularea comenzilor',
          paragraphs: [
            'O comandă poate fi anulată în condițiile și în limitele prevăzute de politica de anulare a comenzilor.',
          ],
        ),

        LegalSection(
          title: '7. Dreptul de retragere',
          paragraphs: [
            'Consumatorii beneficiază, în situațiile prevăzute de legislația aplicabilă, de dreptul de retragere din contract.',
            'Condițiile și modalitatea de exercitare a dreptului de retragere sunt prezentate în pagina dedicată retragerii.',
          ],
        ),

        LegalSection(
          title: '8. Protecția datelor',
          paragraphs: [
            'Datele cu caracter personal sunt prelucrate conform politicii de confidențialitate și legislației aplicabile privind protecția datelor.',
          ],
        ),

        LegalSection(
          title: '9. Contact',
          paragraphs: [
            'Pentru întrebări privind platforma, comenzile sau aceste condiții, utilizatorii pot utiliza datele de contact publicate pe site.',
          ],
        ),
      ],
    );
  }
}