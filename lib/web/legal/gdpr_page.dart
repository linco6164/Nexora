import 'package:flutter/material.dart';
import 'web_legal_page.dart';

class GdprPage extends StatelessWidget {
  const GdprPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const WebLegalPage(
      title: 'GDPR și drepturile utilizatorilor',
      sections: [
        LegalSection(
          title: '1. Protecția datelor cu caracter personal',
          paragraphs: [
            'Nexora Store S.R.L. prelucrează datele cu caracter personal în conformitate cu legislația aplicabilă privind protecția datelor cu caracter personal.',
          ],
        ),

        LegalSection(
          title: '2. Dreptul de acces',
          paragraphs: [
            'Utilizatorii pot solicita informații privind datele cu caracter personal prelucrate și pot solicita accesul la aceste date, în condițiile prevăzute de legislația aplicabilă.',
          ],
        ),

        LegalSection(
          title: '3. Dreptul la rectificare',
          paragraphs: [
            'Utilizatorii pot solicita corectarea datelor personale inexacte sau completarea datelor incomplete.',
          ],
        ),

        LegalSection(
          title: '4. Dreptul la ștergerea datelor',
          paragraphs: [
            'În condițiile prevăzute de lege, utilizatorii pot solicita ștergerea datelor lor cu caracter personal.',
          ],
        ),

        LegalSection(
          title: '5. Dreptul la restricționarea prelucrării',
          paragraphs: [
            'În anumite situații, utilizatorii pot solicita restricționarea prelucrării datelor lor cu caracter personal.',
          ],
        ),

        LegalSection(
          title: '6. Dreptul la portabilitatea datelor',
          paragraphs: [
            'În situațiile în care legislația aplicabilă prevede acest drept, utilizatorii pot solicita primirea datelor personale într-un format structurat, utilizat în mod obișnuit și care poate fi citit automat.',
          ],
        ),

        LegalSection(
          title: '7. Dreptul la opoziție',
          paragraphs: [
            'Utilizatorii se pot opune anumitor forme de prelucrare a datelor cu caracter personal, în condițiile prevăzute de legislația aplicabilă.',
          ],
        ),

        LegalSection(
          title: '8. Retragerea consimțământului',
          paragraphs: [
            'În cazul în care prelucrarea datelor se bazează pe consimțământ, acesta poate fi retras în condițiile prevăzute de legislația aplicabilă.',
            'Retragerea consimțământului nu afectează legalitatea prelucrării efectuate înainte de retragere.',
          ],
        ),

        LegalSection(
          title: '9. Solicitări privind datele personale',
          paragraphs: [
            'Solicitările privind exercitarea drepturilor GDPR pot fi transmise prin datele de contact oficiale publicate pe platforma Nexora.',
          ],
        ),

        LegalSection(
          title: '10. Autoritatea de supraveghere',
          paragraphs: [
            'Persoanele vizate au dreptul de a se adresa autorității competente pentru protecția datelor cu caracter personal, în condițiile prevăzute de legislația aplicabilă.',
          ],
        ),
      ],
    );
  }
}