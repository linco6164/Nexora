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
          title: '1. Operatorul platformei',
          paragraphs: [
            'Platforma Nexora este operată de NEXORA STORE S.R.L., cu sediul social și adresa de corespondență în Str. Argentina nr. 25, etaj parter, Sector 1, București, cod poștal 011753, România, înregistrată la Registrul Comerțului sub nr. J2025029466000, CUI 51686427.',
            'Societatea nu are un punct de lucru secundar înregistrat. Contact: contact@nx-store.com, telefon 0720 249 911.',
          ],
        ),
        LegalSection(
          title: '2. Rolul Nexora și părțile tranzacției',
          paragraphs: [
            'NEXORA STORE S.R.L. operează un marketplace online și acționează ca intermediar în comerțul cu produse diverse. Platforma permite publicarea anunțurilor, comunicarea dintre utilizatori, plasarea comenzilor, facilitarea plăților și organizarea livrării.',
            'Vânzătorul produsului este utilizatorul identificat în pagina anunțului și în sumarul comenzii. Contractul de vânzare pentru produs se încheie între cumpărător și vânzătorul respectiv. Nexora nu devine automat proprietarul produsului listat de un utilizator.',
            'Dacă NEXORA STORE S.R.L. vinde direct un produs, această calitate este indicată explicit în pagina produsului și în documentele comenzii.',
          ],
        ),
        LegalSection(
          title: '3. Facturarea',
          paragraphs: [
            'Vânzătorul identificat în comandă emite documentul fiscal pentru produs atunci când are această obligație legală. NEXORA STORE S.R.L. emite factură pentru comisioanele și serviciile proprii facturate de platformă, inclusiv promovarea anunțurilor, după caz.',
            'Atunci când NEXORA STORE S.R.L. este indicată explicit drept vânzător al produsului, factura aferentă produsului este emisă de NEXORA STORE S.R.L.',
          ],
        ),
        LegalSection(
          title: '4. Produse, descrieri și prețuri',
          paragraphs: [
            'Fiecare pagină de produs afișează denumirea, descrierea, starea, caracteristicile disponibile, identitatea vânzătorului și prețul produsului. Vânzătorul răspunde pentru exactitatea și caracterul complet al anunțului.',
            'Prețul produsului este afișat în lei sau în moneda indicată în anunț. Costul livrării și totalul final sunt afișate separat în checkout, înainte ca utilizatorul să confirme plata.',
          ],
        ),
        LegalSection(
          title: '5. Comanda și plata',
          paragraphs: [
            'Înainte de plata comenzii, cumpărătorul poate verifica produsul, vânzătorul, adresa, metoda și costul livrării, prețul produsului și totalul de plată.',
            'Plățile cu cardul sunt procesate securizat prin NETOPIA Payments. Nexora nu solicită și nu stochează datele complete ale cardului introduse în pagina procesatorului de plăți.',
          ],
        ),
        LegalSection(
          title: '6. Livrare',
          paragraphs: [
            'Livrarea la adresa indicată de cumpărător se efectuează prin opțiunea de curier aleasă în checkout: Sameday, FAN Courier sau GLS, în funcție de disponibilitate.',
            'Termenul estimat este de 2-5 zile lucrătoare de la confirmarea comenzii: 1-2 zile lucrătoare pentru pregătire și predare, urmate de 1-3 zile lucrătoare pentru transport. Detaliile complete sunt publicate în pagina „Livrare”.',
          ],
        ),
        LegalSection(
          title: '7. Anularea comenzii',
          paragraphs: [
            'Anularea poate fi solicitată înainte ca produsul să fie predat curierului, prin Cont > Suport sau la contact@nx-store.com, cu indicarea numărului comenzii. După expediere se aplică, după caz, procedura de retragere și retur.',
          ],
        ),
        LegalSection(
          title: '8. Retur și dreptul de retragere',
          paragraphs: [
            'Consumatorul beneficiază, cu excepțiile prevăzute de lege, de 14 zile calendaristice pentru retragerea din contractul la distanță, fără să fie obligat să justifice decizia.',
            'Retragerea se poate transmite prin formularul online „Retur / retragere”, printr-un tichet în Cont > Suport sau printr-o declarație neechivocă trimisă la contact@nx-store.com. Procedura de returnare, rambursare și excepțiile sunt descrise în pagina dedicată.',
          ],
        ),
        LegalSection(
          title: '9. Contul de utilizator',
          paragraphs: [
            'Utilizatorul trebuie să furnizeze informații reale și actualizate și este responsabil pentru păstrarea confidențialității datelor de autentificare și pentru activitatea desfășurată prin contul său.',
            'Publicarea de produse interzise, informații înșelătoare, tentative de fraudă sau utilizarea abuzivă a platformei poate conduce la restricționarea contului, fără a afecta drepturile legale ale consumatorului.',
          ],
        ),
        LegalSection(
          title: '10. Protecția datelor și contact',
          paragraphs: [
            'Datele cu caracter personal sunt prelucrate conform Politicii de confidențialitate și legislației aplicabile. Pentru întrebări privind comenzile sau acești termeni: contact@nx-store.com, 0720 249 911 sau Cont > Suport.',
          ],
        ),
      ],
    );
  }
}
