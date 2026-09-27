import 'package:flutter/material.dart';
import 'web_legal_page.dart';

class CookiesPage extends StatelessWidget {
  const CookiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const WebLegalPage(
      title: 'Politica de cookie-uri',
      sections: [
        LegalSection(
          title: '1. Ce sunt cookie-urile',
          paragraphs: [
            'Cookie-urile sunt fișiere de mici dimensiuni stocate pe dispozitivul utilizatorului atunci când acesta accesează un site web. Acestea pot permite funcționarea anumitor funcții ale platformei și pot ajuta la îmbunătățirea experienței utilizatorului.',
          ],
        ),

        LegalSection(
          title: '2. Cookie-uri necesare',
          paragraphs: [
            'Anumite cookie-uri pot fi necesare pentru funcționarea corectă a platformei, pentru menținerea sesiunii utilizatorului, securitate și furnizarea funcțiilor solicitate.',
          ],
        ),

        LegalSection(
          title: '3. Cookie-uri de preferințe',
          paragraphs: [
            'Cookie-urile de preferințe pot fi utilizate pentru memorarea anumitor opțiuni ale utilizatorului, precum preferințele de afișare sau alte setări ale platformei.',
          ],
        ),

        LegalSection(
          title: '4. Cookie-uri analitice',
          paragraphs: [
            'În cazul utilizării unor servicii de analiză, acestea pot utiliza cookie-uri pentru a furniza informații statistice despre modul în care este utilizată platforma.',
          ],
        ),

        LegalSection(
          title: '5. Cookie-uri de marketing',
          paragraphs: [
            'Cookie-urile de marketing sau tehnologiile similare vor fi utilizate numai în condițiile permise de legislația aplicabilă și, atunci când este necesar, după obținerea consimțământului utilizatorului.',
          ],
        ),

        LegalSection(
          title: '6. Gestionarea cookie-urilor',
          paragraphs: [
            'Utilizatorii pot controla sau șterge cookie-urile prin intermediul setărilor browserului utilizat.',
            'Dezactivarea anumitor cookie-uri poate afecta funcționarea unor funcții ale platformei.',
          ],
        ),

        LegalSection(
          title: '7. Modificarea politicii',
          paragraphs: [
            'Nexora poate actualiza această politică atunci când apar modificări ale platformei, tehnologiilor utilizate sau legislației aplicabile.',
          ],
        ),

        LegalSection(
          title: '8. Contact',
          paragraphs: [
            'Pentru întrebări privind utilizarea cookie-urilor, utilizatorii pot utiliza datele oficiale de contact publicate pe platforma Nexora.',
          ],
        ),
      ],
    );
  }
}