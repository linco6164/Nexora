import 'package:flutter/material.dart';
import 'web_legal_page.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const WebLegalPage(
      title: 'Informații juridice',
      sections: [
        LegalSection(
          title: '1. Identificarea comerciantului',
          paragraphs: [
            'Nexora Store S.R.L. este operatorul platformei Nexora și desfășoară activități comerciale prin intermediul acesteia, în conformitate cu legislația aplicabilă.',
          ],
        ),

        LegalSection(
          title: '2. Rolul platformei Nexora',
          paragraphs: [
            'Platforma Nexora permite utilizatorilor să publice, să descopere și să achiziționeze produse prin intermediul serviciilor disponibile pe platformă.',
            'În funcție de natura listării și a tranzacției, rolul Nexora poate include furnizarea infrastructurii tehnice, facilitarea comunicării dintre utilizatori, procesarea comenzilor și facilitarea plăților.',
          ],
        ),

        LegalSection(
          title: '3. Datele companiei',
          paragraphs: [
            'Denumire: Nexora Store S.R.L.',
            'Sediul social: Strada Argentina, Numarul 25, Etaj Parter, Bucuresti, Sectorul 1',
            'Număr de ordine în Registrul Comerțului: J2025029466000',
            'CUI: 51686427',
            'E-mail: contact@nx-store.com',
            'Telefon: 0720249911',
          ],
        ),

        LegalSection(
          title: '4. Contact',
          paragraphs: [
            'Pentru întrebări privind platforma, comenzile, plățile, retururile sau exercitarea drepturilor utilizatorilor, poate fi utilizată adresa oficială de contact publicată pe platformă.',
          ],
        ),

        LegalSection(
          title: '5. Informații privind produsele',
          paragraphs: [
            'Informațiile referitoare la produse sunt prezentate în pagina fiecărei listări. Utilizatorii trebuie să verifice informațiile disponibile înainte de finalizarea unei comenzi.',
          ],
        ),

        LegalSection(
          title: '6. Proprietatea intelectuală',
          paragraphs: [
            'Elementele grafice, textele, logo-urile, interfața și alte materiale aparținând Nexora nu pot fi reproduse sau utilizate fără acordul titularului drepturilor, cu excepția situațiilor permise de lege.',
          ],
        ),
      ],
    );
  }
}