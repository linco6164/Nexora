import 'package:flutter/material.dart';
import 'web_legal_page.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const WebLegalPage(
      title: 'Politica de confidențialitate',
      sections: [
        LegalSection(
          title: '1. Informații generale',
          paragraphs: [
            'Nexora Store S.R.L. acordă o importanță deosebită protejării datelor cu caracter personal ale utilizatorilor platformei Nexora.',
            'Prezenta politică descrie modul în care datele cu caracter personal sunt colectate, utilizate și protejate.',
          ],
        ),

        LegalSection(
          title: '2. Datele pe care le colectăm',
          paragraphs: [
            'În funcție de serviciile utilizate, putem prelucra date precum numele de utilizator, adresa de email, numărul de telefon și informațiile necesare pentru livrarea comenzilor.',
            'Putem prelucra, de asemenea, informații referitoare la comenzile și tranzacțiile efectuate prin intermediul platformei.',
          ],
        ),

        LegalSection(
          title: '3. Datele de livrare',
          paragraphs: [
            'Pentru procesarea și livrarea comenzilor pot fi prelucrate informații precum județul, localitatea, strada, numărul și codul poștal.',
          ],
        ),

        LegalSection(
          title: '4. Date tehnice',
          paragraphs: [
            'Platforma poate prelucra anumite informații tehnice necesare funcționării serviciilor, securității și prevenirii utilizării abuzive a platformei.',
          ],
        ),

        LegalSection(
          title: '5. Scopurile prelucrării',
          paragraphs: [
            'Datele pot fi utilizate pentru crearea și administrarea contului, procesarea comenzilor, procesarea plăților, livrarea produselor, comunicarea cu utilizatorii și îndeplinirea obligațiilor legale.',
          ],
        ),

        LegalSection(
          title: '6. Plățile online',
          paragraphs: [
            'Datele necesare procesării plăților sunt transmise către furnizorii de servicii de plată integrați în platformă, conform fluxurilor tehnice și condițiilor acestora.',
            'Nexora nu trebuie să stocheze în mod direct datele complete ale cardului atunci când acestea sunt procesate de furnizorul de plăți.',
          ],
        ),

        LegalSection(
          title: '7. Păstrarea datelor',
          paragraphs: [
            'Datele cu caracter personal sunt păstrate atât timp cât este necesar pentru scopurile pentru care au fost colectate și pentru perioadele impuse de obligațiile legale aplicabile.',
          ],
        ),

        LegalSection(
          title: '8. Drepturile utilizatorilor',
          paragraphs: [
            'În condițiile prevăzute de legislația aplicabilă, utilizatorii pot avea drepturi privind accesul la date, rectificarea, ștergerea, restricționarea prelucrării, opoziția și portabilitatea datelor.',
          ],
        ),

        LegalSection(
          title: '9. Securitatea datelor',
          paragraphs: [
            'Nexora utilizează măsuri tehnice și organizatorice adecvate pentru protejarea datelor împotriva accesului neautorizat, pierderii, modificării sau divulgării neautorizate.',
          ],
        ),

        LegalSection(
          title: '10. Contact',
          paragraphs: [
            'Pentru întrebări sau solicitări referitoare la prelucrarea datelor cu caracter personal, utilizatorii pot utiliza datele de contact oficiale publicate pe platformă.',
          ],
        ),
      ],
    );
  }
}