import 'package:flutter/material.dart';

class LegalSectionData {
  final String title;
  final List<String> paragraphs;

  const LegalSectionData({required this.title, required this.paragraphs});
}

class LegalDocumentData {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<LegalSectionData> sections;

  const LegalDocumentData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.sections,
  });
}

const legalLastUpdated = '18 octombrie 2026';

const legalDocuments = <LegalDocumentData>[
  LegalDocumentData(
    title: 'Termeni și condiții',
    subtitle: 'Regulile de utilizare a platformei Nexora',
    icon: Icons.gavel_rounded,
    sections: [
      LegalSectionData(
        title: '1. Operatorul platformei',
        paragraphs: [
          'Platforma Nexora Store este operată de NEXORA STORE S.R.L., cu sediul social în Str. Argentina nr. 25, parter, Sector 1, București, 011753, înregistrată la Registrul Comerțului sub nr. J2025029466000, CUI 51686427. Contact: contact@nx-store.com, telefon 0720 249 911.',
          'Prin crearea unui cont sau folosirea platformei confirmi că ai citit și accepți acești termeni. Dacă nu ești de acord, nu utiliza serviciile Nexora.',
        ],
      ),
      LegalSectionData(
        title: '2. Rolul Nexora și contractul de vânzare',
        paragraphs: [
          'Nexora oferă infrastructura tehnică prin care utilizatorii publică anunțuri, comunică, plătesc și organizează livrarea. Dacă un produs este vândut de un utilizator terț, contractul de vânzare se încheie între cumpărător și acel vânzător, iar identitatea vânzătorului este afișată în anunț și în comandă.',
          'Nexora este parte în contractul de vânzare numai atunci când produsul este indicat în mod explicit ca fiind vândut de NEXORA STORE S.R.L. Facilitarea plății, livrării sau comunicării nu transformă automat Nexora în vânzător.',
          'Drepturile specifice consumatorilor, inclusiv retragerea legală, se aplică atunci când cumpărătorul este consumator, iar vânzătorul acționează ca profesionist. Pentru vânzările între persoane fizice, aceste drepturi nu se aplică automat, dacă legea sau acordul părților nu prevede altfel.',
        ],
      ),
      LegalSectionData(
        title: '3. Contul de utilizator',
        paragraphs: [
          'Trebuie să furnizezi date reale, actuale și complete, să păstrezi confidențialitatea datelor de acces și să ne anunți imediat dacă suspectezi acces neautorizat. Nu este permisă cedarea contului sau crearea de conturi în scop fraudulos.',
          'Poți utiliza platforma numai dacă ai capacitatea legală necesară. Pentru minori, folosirea serviciilor care presupun încheierea unui contract trebuie realizată cu acordul și sub supravegherea reprezentantului legal.',
          'Putem solicita verificări rezonabile de identitate, contact sau tranzacție pentru securitate, prevenirea fraudei și respectarea obligațiilor legale.',
        ],
      ),
      LegalSectionData(
        title: '4. Anunțuri și conduită',
        paragraphs: [
          'Vânzătorul răspunde pentru corectitudinea descrierii, fotografiilor, prețului, stării produsului, dreptului de a-l vinde și respectarea legislației. Sunt interzise produsele ilegale, contrafăcute, periculoase, furate sau care încalcă drepturile altor persoane.',
          'Nu sunt permise frauda, hărțuirea, mesajele nesolicitate, manipularea recenziilor, ocolirea mecanismelor de siguranță, tentativele de phishing, colectarea neautorizată de date ori folosirea platformei pentru activități ilegale.',
          'Putem limita vizibilitatea, suspenda sau elimina anunțuri și conturi atunci când există indicii rezonabile de încălcare, risc pentru utilizatori sau o obligație legală. În măsura permisă de lege, utilizatorul va fi informat despre motiv și căile disponibile de contestare.',
        ],
      ),
      LegalSectionData(
        title: '5. Comenzi, prețuri și plăți',
        paragraphs: [
          'Prețul produsului, costul livrării și orice taxe aplicabile sunt afișate înainte de confirmarea comenzii. Comanda este considerată acceptată conform stării afișate în aplicație și comunicărilor transmise părților.',
          'Plățile online sunt procesate prin furnizori autorizați. Nexora nu păstrează în clar numărul complet al cardului sau codul de securitate. Pentru cardurile salvate, furnizorul de plată poate emite un token tehnic reutilizabil.',
          'În caz de anulare, rambursare sau plată contestată, termenele bancare și regulile furnizorului de plată se pot adăuga timpului de procesare Nexora.',
        ],
      ),
      LegalSectionData(
        title: '6. Programul „Invită un prieten”',
        paragraphs: [
          'Persoana care invită și persoana invitată primesc fiecare câte 100 RON în soldul Nexora după îndeplinirea cumulativă a condițiilor: contul este creat folosind linkul sau codul de invitație, persoana invitată publică minimum două anunțuri eligibile după înregistrare și finalizează o vânzare pentru unul dintre acestea.',
          'Vânzarea este considerată finalizată numai când comanda ajunge la starea „completed”, după confirmarea cumpărătorului, finalizarea automată sau soluționarea validă în favoarea vânzătorului. Simpla publicare, rezervare, plată sau expediere nu acordă bonusul.',
          'Bonusul se acordă automat o singură dată pentru fiecare utilizator invitat eligibil. Nexora poate refuza sau retrage avantajele obținute prin conturi fictive, informații false, tranzacții simulate, abuz, coluziune ori alte încălcări ale termenilor sau legii.',
        ],
      ),
      LegalSectionData(
        title: '7. Livrare și recepție',
        paragraphs: [
          'Metoda, costul și termenul estimativ de livrare sunt prezentate înainte de plată. Termenul este estimativ și poate fi afectat de curier, adresă, sărbători, condiții meteo sau situații excepționale.',
          'Cumpărătorul trebuie să furnizeze o adresă și date de contact corecte, să urmărească expedierea și să verifice coletul în limitele permise de curier. Problemele vizibile ori lipsa coletului trebuie raportate fără întârziere din secțiunea de suport.',
        ],
      ),
      LegalSectionData(
        title: '8. Răspundere',
        paragraphs: [
          'Nexora depune eforturi rezonabile pentru disponibilitatea și securitatea platformei, dar nu poate garanta funcționarea neîntreruptă sau lipsa absolută a erorilor. Nimic din acești termeni nu exclude sau limitează o răspundere care nu poate fi exclusă prin lege.',
          'Utilizatorii răspund pentru propriul conținut, propriile obligații fiscale și comerciale și executarea contractelor încheiate cu alți utilizatori. Nexora poate interveni pentru suport și siguranță fără a prelua obligațiile vânzătorului terț.',
        ],
      ),
      LegalSectionData(
        title: '9. Proprietate intelectuală și modificări',
        paragraphs: [
          'Aplicația, identitatea vizuală, textele proprii, structura și software-ul Nexora sunt protejate de lege. Păstrezi drepturile asupra conținutului tău, dar acorzi Nexora o licență neexclusivă, limitată la funcționarea, promovarea și îmbunătățirea serviciului, cât timp conținutul este publicat.',
          'Putem actualiza acești termeni pentru schimbări legislative, de securitate sau funcționale. Modificările importante vor fi comunicate prin aplicație ori prin datele de contact ale contului și se vor aplica de la data indicată.',
        ],
      ),
      LegalSectionData(
        title: '10. Legea aplicabilă',
        paragraphs: [
          'Termenii sunt guvernați de legea română. Neînțelegerile se încearcă a fi soluționate amiabil, fără a limita dreptul consumatorului de a apela la autoritățile competente, la soluționarea alternativă a litigiilor sau la instanța competentă potrivit legii.',
        ],
      ),
    ],
  ),
  LegalDocumentData(
    title: 'Politica de confidențialitate',
    subtitle: 'Cum folosim și protejăm datele personale',
    icon: Icons.privacy_tip_outlined,
    sections: [
      LegalSectionData(
        title: '1. Operator și contact',
        paragraphs: [
          'NEXORA STORE S.R.L. este operatorul datelor prelucrate pentru administrarea platformei. Ne poți contacta la contact@nx-store.com sau la adresa Str. Argentina nr. 25, parter, Sector 1, București, 011753.',
          'În tranzacțiile dintre utilizatori, vânzătorul poate primi datele strict necesare executării contractului și poate avea responsabilități proprii privind protecția datelor.',
        ],
      ),
      LegalSectionData(
        title: '2. Date colectate',
        paragraphs: [
          'Putem prelucra date de identificare și cont, date de contact, profil și verificare, anunțuri și fotografii, mesaje și suport, comenzi, livrare, facturare, tranzacții și tokenuri de plată, preferințe, notificări, recenzii, date despre dispozitiv, adrese IP, jurnale de securitate și interacțiuni cu platforma.',
          'Nu solicităm codul PIN al cardului. Datele complete ale cardului sunt introduse în mediul securizat al procesatorului de plăți și nu sunt stocate în clar de Nexora.',
        ],
      ),
      LegalSectionData(
        title: '3. Scopuri și temeiuri',
        paragraphs: [
          'Folosim datele pentru crearea și administrarea contului, publicarea anunțurilor, comunicare, comenzi, plăți, livrare și suport, în baza executării contractului sau a demersurilor cerute de tine.',
          'Prelucrăm date pentru securitate, prevenirea fraudei, moderare, apărarea drepturilor, îmbunătățirea serviciilor și analize agregate în baza intereselor legitime, după evaluarea impactului asupra drepturilor tale.',
          'Respectăm obligații legale contabile, fiscale, de protecție a consumatorilor și de răspuns către autorități. Pentru comunicări de marketing sau tehnologii opționale folosim consimțământul, atunci când legea îl cere; acesta poate fi retras oricând.',
        ],
      ),
      LegalSectionData(
        title: '4. Destinatari și transferuri',
        paragraphs: [
          'Datele pot fi transmise, în limita necesară, celuilalt participant la tranzacție, procesatorilor de plăți, curierilor, furnizorilor de găzduire, comunicații, suport, securitate și analiză, consultanților și autorităților competente.',
          'Furnizorii sunt selectați și contractați cu obligații de confidențialitate și securitate. Dacă datele sunt transferate în afara Spațiului Economic European, folosim un mecanism legal adecvat, precum o decizie de adecvare sau clauze contractuale standard.',
        ],
      ),
      LegalSectionData(
        title: '5. Perioada de păstrare',
        paragraphs: [
          'Păstrăm datele cât timp contul este activ și ulterior numai atât cât este necesar scopului, soluționării litigiilor, prevenirii fraudei sau termenelor legale. Documentele financiar-contabile sunt păstrate conform termenelor obligatorii.',
          'La ștergerea contului, unele date sunt șterse sau anonimizate, iar datele care trebuie păstrate legal sunt izolate și accesate numai în scopurile permise.',
        ],
      ),
      LegalSectionData(
        title: '6. Securitate și decizii automate',
        paragraphs: [
          'Aplicăm măsuri tehnice și organizatorice adaptate riscului, inclusiv controlul accesului, criptarea comunicațiilor, jurnalizare și monitorizarea incidentelor. Nicio metodă nu poate elimina complet riscul, iar utilizatorul trebuie să își protejeze parola și dispozitivul.',
          'Putem folosi semnale automate pentru detectarea fraudei sau prioritizarea verificărilor. Dacă o decizie exclusiv automată produce efecte juridice ori similare semnificative, oferim informațiile și drepturile cerute de lege, inclusiv intervenție umană atunci când este aplicabilă.',
        ],
      ),
    ],
  ),
  LegalDocumentData(
    title: 'Drepturile tale GDPR',
    subtitle: 'Acces, rectificare, ștergere și control asupra datelor',
    icon: Icons.shield_outlined,
    sections: [
      LegalSectionData(
        title: 'Drepturile disponibile',
        paragraphs: [
          'În condițiile Regulamentului (UE) 2016/679, poți solicita accesul la date, rectificarea datelor inexacte, ștergerea, restricționarea prelucrării, portabilitatea datelor și opoziția față de prelucrările bazate pe interes legitim sau față de marketing direct.',
          'Poți retrage consimțământul oricând, fără a afecta legalitatea prelucrării anterioare. De asemenea, ai dreptul de a nu fi supus unei decizii exclusiv automate în cazurile prevăzute de lege.',
        ],
      ),
      LegalSectionData(
        title: 'Cum trimiți o cerere',
        paragraphs: [
          'Trimite solicitarea la contact@nx-store.com, din adresa asociată contului, și descrie clar dreptul exercitat. Putem cere informații suplimentare strict pentru confirmarea identității și protejarea contului.',
          'Răspundem fără întârzieri nejustificate și, de regulă, în cel mult o lună. Pentru cereri complexe sau numeroase, termenul poate fi prelungit în condițiile legii, cu informarea motivată a solicitantului.',
        ],
      ),
      LegalSectionData(
        title: 'Plângeri',
        paragraphs: [
          'Dacă apreciezi că drepturile tale au fost încălcate, ne poți contacta pentru rezolvare și poți depune o plângere la Autoritatea Națională de Supraveghere a Prelucrării Datelor cu Caracter Personal sau la autoritatea competentă din statul în care locuiești ori lucrezi.',
        ],
      ),
    ],
  ),
  LegalDocumentData(
    title: 'Livrare',
    subtitle: 'Metode, termene estimate și responsabilități',
    icon: Icons.local_shipping_outlined,
    sections: [
      LegalSectionData(
        title: 'Metode și costuri',
        paragraphs: [
          'Opțiunile disponibile pot include livrare prin curier la adresă sau la un punct de ridicare. Metoda concretă, curierul, costul și estimarea de livrare sunt afișate înainte de confirmarea comenzii.',
          'Costul livrării este distinct de prețul produsului, dacă nu este indicat expres că livrarea este inclusă sau gratuită.',
        ],
      ),
      LegalSectionData(
        title: 'Pregătire și urmărire',
        paragraphs: [
          'Vânzătorul trebuie să ambaleze produsul corespunzător, să respecte intervalul de predare comunicat și să furnizeze coletului informațiile necesare. Cumpărătorul primește actualizări în aplicație și, unde este disponibil, numărul de urmărire.',
          'Termenele sunt estimative. Întârzierile cauzate de curier, date de livrare greșite, lipsa destinatarului ori evenimente în afara controlului rezonabil vor fi gestionate prin suport și regulile curierului.',
        ],
      ),
      LegalSectionData(
        title: 'Recepție și probleme',
        paragraphs: [
          'Verifică integritatea ambalajului la primire. Dacă este deteriorat, solicită consemnarea situației de către curier, păstrează ambalajul și fotografiile și contactează suportul cât mai repede.',
          'Pentru colet nelivrat, produs lipsă sau produs diferit, deschide o solicitare din aplicație și atașează informațiile relevante. Soluția depinde de dovezi, de statutul vânzătorului și de drepturile aplicabile contractului.',
        ],
      ),
    ],
  ),
  LegalDocumentData(
    title: 'Anulare și rambursare',
    subtitle: 'Ce se întâmplă când o comandă este anulată',
    icon: Icons.cancel_outlined,
    sections: [
      LegalSectionData(
        title: 'Anularea comenzii',
        paragraphs: [
          'Cumpărătorul poate solicita anularea înainte de expediere din opțiunile disponibile în comandă sau prin suport. Dacă expedierea a început, anularea poate necesita refuzul coletului sau procedura de retur.',
          'Vânzătorul poate anula numai pentru un motiv real, precum indisponibilitatea produsului, deteriorarea înainte de predare sau o problemă de siguranță. Anulările repetate pot duce la limitarea contului.',
        ],
      ),
      LegalSectionData(
        title: 'Rambursarea',
        paragraphs: [
          'Dacă o plată eligibilă este anulată, suma este transmisă spre rambursare prin metoda inițială, dacă acest lucru este posibil. Momentul afișării în cont depinde și de banca emitentă sau furnizorul de plată.',
          'Taxele de livrare sau retur sunt rambursate ori suportate conform motivului anulării, informațiilor afișate în comandă și normelor legale aplicabile.',
        ],
      ),
    ],
  ),
  LegalDocumentData(
    title: 'Retur și drept de retragere',
    subtitle: 'Condiții, excepții și formular orientativ',
    icon: Icons.assignment_return_outlined,
    sections: [
      LegalSectionData(
        title: 'Când există dreptul legal de retragere',
        paragraphs: [
          'Pentru un contract la distanță între un consumator și un vânzător profesionist, consumatorul se poate retrage, de regulă, în 14 zile fără să invoce un motiv. Termenul se calculează potrivit OUG nr. 34/2014, de regulă de la data la care consumatorul sau persoana desemnată intră în posesia fizică a bunului.',
          'Dacă vânzătorul este o persoană fizică ce nu acționează profesional, dreptul legal de retragere de 14 zile nu se aplică automat. Poate exista totuși un retur acceptat voluntar, o garanție convenită sau un remediu pentru neconformitate, după caz.',
        ],
      ),
      LegalSectionData(
        title: 'Exercitarea retragerii',
        paragraphs: [
          'Înainte de expirarea termenului, transmite vânzătorului o declarație neechivocă prin funcția de retur/suport sau prin datele de contact disponibile. Menționează comanda, produsul, data primirii, numele și opțiunea solicitată.',
          'Produsul trebuie returnat fără întârzieri nejustificate, cel târziu în termenul legal de la comunicarea retragerii. Consumatorul suportă costul direct al returului dacă a fost informat astfel și dacă legea nu impune comerciantului să îl suporte.',
        ],
      ),
      LegalSectionData(
        title: 'Starea produsului și rambursarea',
        paragraphs: [
          'Consumatorul poate verifica produsul în măsura necesară stabilirii naturii, caracteristicilor și funcționării lui. Poate răspunde pentru diminuarea valorii rezultată din manipulări care depășesc această limită.',
          'Vânzătorul profesionist rambursează sumele datorate în termenul și condițiile legale și poate amâna rambursarea până la primirea bunului sau a dovezii expedierii, după caz.',
        ],
      ),
      LegalSectionData(
        title: 'Excepții',
        paragraphs: [
          'Retragerea poate fi exclusă în situațiile prevăzute de lege, inclusiv pentru anumite produse personalizate, perisabile, bunuri sigilate care nu pot fi returnate din motive de sănătate sau igienă după desigilare, înregistrări ori software sigilat desigilat și conținut digital furnizat în condițiile legale cu acordul consumatorului.',
          'Excepția trebuie evaluată concret și nu poate fi extinsă dincolo de ceea ce permite legea.',
        ],
      ),
      LegalSectionData(
        title: 'Model de declarație',
        paragraphs: [
          '„Vă informez prin prezenta cu privire la retragerea mea din contractul referitor la produsul [denumire], comanda [număr], comandat la [data] și primit la [data]. Nume: [nume]. Adresă: [adresă]. Data: [data].” Folosirea acestui model nu este obligatorie; orice declarație clară este suficientă.',
        ],
      ),
    ],
  ),
  LegalDocumentData(
    title: 'Plăți și carduri salvate',
    subtitle: 'Procesare, tokenizare și securitate',
    icon: Icons.credit_card_outlined,
    sections: [
      LegalSectionData(
        title: 'Procesarea plății',
        paragraphs: [
          'Plățile sunt inițiate din Nexora și procesate în infrastructura furnizorului de servicii de plată, inclusiv NETOPIA Payments atunci când aceasta este metoda afișată. Autorizarea poate necesita confirmare 3-D Secure sau verificarea portofelului digital.',
          'Nexora primește starea tranzacției și identificatori tehnici necesari comenzii, rambursării și prevenirii fraudei, nu codul PIN și nu codul CVV/CVC în clar.',
        ],
      ),
      LegalSectionData(
        title: 'Carduri salvate și Google Pay',
        paragraphs: [
          'Salvarea unui card depinde de emiterea unui token de către procesatorul de plăți. Tokenul nu este numărul cardului și poate fi revocat prin ștergerea metodei salvate ori potrivit regulilor furnizorului.',
          'Google Pay transmite datele de plată protejate prin mecanismele Google și ale procesatorului. Disponibilitatea depinde de dispozitiv, țară, card, bancă, configurarea comerciantului și mediul de plată.',
        ],
      ),
      LegalSectionData(
        title: 'Siguranță',
        paragraphs: [
          'Nu comunica altor persoane coduri de autorizare, parole sau date complete de card. Dacă observi o tranzacție necunoscută, contactează imediat banca și suportul Nexora. Putem bloca temporar o plată sau solicita verificări când există semnale de risc.',
        ],
      ),
    ],
  ),
  LegalDocumentData(
    title: 'Cookie-uri și stocare pe dispozitiv',
    subtitle: 'Tehnologii necesare și opționale',
    icon: Icons.cookie_outlined,
    sections: [
      LegalSectionData(
        title: 'În aplicația Android',
        paragraphs: [
          'Aplicația poate păstra pe dispozitiv informații strict necesare precum sesiunea autentificată în stocare securizată, preferințele de temă și limbă, setările de notificare și identificatorul tehnic pentru notificări push.',
          'Pot exista date temporare de tip cache pentru performanță și continuitatea experienței. Ștergerea datelor aplicației sau dezinstalarea elimină datele locale, dar nu șterge automat contul ori evidențele care trebuie păstrate pe server.',
        ],
      ),
      LegalSectionData(
        title: 'Permisiuni',
        paragraphs: [
          'Camera și galeria sunt folosite numai când adaugi fotografii sau actualizezi profilul. Notificările și locația sunt solicitate prin mecanismele Android și pot fi retrase din setările telefonului; unele funcții pot deveni indisponibile.',
          'Datele pentru funcționalități opționale sunt prelucrate numai potrivit alegerilor tale și politicii de confidențialitate.',
        ],
      ),
      LegalSectionData(
        title: 'Control',
        paragraphs: [
          'Poți modifica notificările, limba și tema din setările aplicației. Permisiunile se gestionează și din setările Android. Pentru ștergerea contului sau exercitarea drepturilor asupra datelor, contactează suportul ori folosește opțiunea disponibilă în cont.',
        ],
      ),
    ],
  ),
  LegalDocumentData(
    title: 'Reclamații și soluționarea litigiilor',
    subtitle: 'Suport, ANPC, SAL și instanțe competente',
    icon: Icons.support_agent_rounded,
    sections: [
      LegalSectionData(
        title: 'Contact și soluționare amiabilă',
        paragraphs: [
          'Pentru o problemă legată de cont, comandă, livrare, plată sau retur, contactează întâi suportul din aplicație ori la contact@nx-store.com. Include numărul comenzii, o descriere clară și dovezile relevante. Vom analiza cererea și vom comunica pașii disponibili.',
          'Dacă disputa privește produsul unui vânzător terț, îl putem contacta și putem facilita comunicarea, fără a înlocui răspunderea juridică a părții contractante.',
        ],
      ),
      LegalSectionData(
        title: 'Consumatori, ANPC și SAL',
        paragraphs: [
          'Consumatorii pot sesiza Autoritatea Națională pentru Protecția Consumatorilor și pot utiliza mecanismul de soluționare alternativă a litigiilor (SAL) disponibil prin ANPC, dacă sunt îndeplinite condițiile procedurii.',
          'Platforma europeană SOL/ODR nu mai primește reclamații din 20 martie 2025 și a fost închisă potrivit Regulamentului (UE) 2024/3228; de aceea nu afișăm un link vechi către această platformă.',
        ],
      ),
      LegalSectionData(
        title: 'Instanțe și autorități',
        paragraphs: [
          'Dreptul de a sesiza instanța competentă sau o autoritate nu este limitat de procedura internă. Consumatorul beneficiază de regulile imperative privind competența și protecția aplicabile situației sale.',
        ],
      ),
    ],
  ),
];
