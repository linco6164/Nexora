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
          title: '1. Date complete de identificare',
          paragraphs: [
            'Denumire: NEXORA STORE S.R.L.',
            'Sediu social și adresă de corespondență: Str. Argentina nr. 25, etaj parter, Sector 1, București, cod poștal 011753, România.',
            'Punct de lucru: societatea nu are un punct de lucru secundar înregistrat. Activitatea administrativă și corespondența se desfășoară la sediul social indicat mai sus.',
            'Număr de ordine în Registrul Comerțului: J2025029466000.',
            'Cod unic de înregistrare (CUI): 51686427.',
            'E-mail: contact@nx-store.com.',
            'Telefon: 0720 249 911.',
          ],
        ),

        LegalSection(
          title: '2. Rolul platformei Nexora',
          paragraphs: [
            'NEXORA STORE S.R.L. operează Nexora ca marketplace online și intermediar în comerțul cu produse diverse. Platforma furnizează infrastructura tehnică pentru publicarea anunțurilor, comunicarea dintre utilizatori, plasarea comenzilor, facilitarea plăților și organizarea livrării.',
            'Nexora nu devine automat proprietarul produselor publicate de utilizatori și nu este vânzătorul produsului atunci când în pagina anunțului este identificat un alt vânzător.',
          ],
        ),

        LegalSection(
          title: '3. Cine vinde și cine emite factura',
          paragraphs: [
            'Vânzătorul produsului este utilizatorul identificat în pagina anunțului și în sumarul comenzii. Contractul de vânzare pentru produs se încheie între cumpărător și acel vânzător.',
            'Vânzătorul emite documentele fiscale pentru produs atunci când are această obligație legală. NEXORA STORE S.R.L. emite factură pentru comisioanele și serviciile proprii facturate de platformă, inclusiv servicii de promovare, după caz.',
            'Dacă NEXORA STORE S.R.L. este vânzătorul unui anumit produs, acest lucru este indicat explicit în pagina produsului și în documentele comenzii, iar factura produsului este emisă de NEXORA STORE S.R.L.',
          ],
        ),

        LegalSection(
          title: '4. Contact',
          paragraphs: [
            'Pentru întrebări despre platformă, comenzi, plăți, livrare, anulare sau retur: contact@nx-store.com ori 0720 249 911. Utilizatorii autentificați pot trimite și un tichet din Cont > Suport.',
          ],
        ),

        LegalSection(
          title: '5. Informații privind produsele',
          paragraphs: [
            'Pagina fiecărui produs afișează denumirea, descrierea, starea, caracteristicile disponibile, identitatea vânzătorului și prețul produsului. Costul livrării și totalul comenzii sunt afișate separat înainte de plată.',
            'Vânzătorul răspunde pentru corectitudinea și caracterul complet al informațiilor publicate în anunț.',
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
