import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocaleController extends ValueNotifier<String> {
  AppLocaleController() : super('ro');

  static const _storageKey = 'app_language';
  static const supportedLanguages = {'ro', 'en'};

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedLanguage = preferences.getString(_storageKey);
    if (savedLanguage != null && supportedLanguages.contains(savedLanguage)) {
      value = savedLanguage;
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    if (!supportedLanguages.contains(languageCode) || value == languageCode) {
      return;
    }

    value = languageCode;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, languageCode);
  }
}

final appLocaleController = AppLocaleController();

class AppTranslations {
  AppTranslations._();

  static const Map<String, String> _english = {
    'Favorite': 'Favorites',
    'Mesaje': 'Messages',
    'Notificări': 'Notifications',
    'Vinde': 'Sell',
    'Caută produse, branduri, categorii...':
        'Search products, brands, categories...',
    'Caută produse...': 'Search products...',
    'Adaugă anunț': 'Create listing',
    'Cont': 'Account',
    'Autentificare': 'Sign in',
    'Intră în contul tău': 'Access your account',
    'Creează cont': 'Create account',
    'Înregistrează-te gratuit': 'Register for free',
    'Profilul meu': 'My profile',
    'Vezi și editează profilul': 'View and edit your profile',
    'Anunțurile mele': 'My listings',
    'Anunț nou': 'New listing',
    'Editează anunțul': 'Edit listing',
    'Actualizează informațiile anunțului tău.':
        'Update your listing information.',
    'Salvează modificările': 'Save changes',
    'Se salvează...': 'Saving...',
    'Anunț actualizat cu succes!': 'Listing updated successfully!',
    'Vezi anunțul': 'View listing',
    'Editează': 'Edit',
    'Promovează': 'Promote',
    'Șterge': 'Delete',
    'Șterge anunțul': 'Delete listing',
    'Anulează': 'Cancel',
    'Anunțul a fost șters.': 'The listing was deleted.',
    'Mai multe acțiuni': 'More actions',
    'Activ': 'Active',
    'Inactiv': 'Inactive',
    'Vândut': 'Sold',
    'În verificare': 'Under review',
    'Nu ai niciun anunț.': 'You have no listings yet.',
    'Publică primul tău produs pentru a începe.':
        'Publish your first product to get started.',
    'Încearcă din nou': 'Try again',
    'Produsele pe care le vinzi': 'Products you are selling',
    'Comenzile mele': 'My orders',
    'Produsele cumpărate': 'Purchased products',
    'Sold și încasări': 'Balance and earnings',
    'Tranzacții și retrageri': 'Transactions and withdrawals',
    'Vânzările mele': 'My sales',
    'Produsele vândute': 'Sold products',
    'Cardurile mele': 'My cards',
    'Metodele tale de plată': 'Your payment methods',
    'Promovări': 'Promotions',
    'Promovează anunțurile tale': 'Promote your listings',
    'Adrese salvate': 'Saved addresses',
    'Adrese pentru livrare': 'Delivery addresses',
    'Recenziile mele': 'My reviews',
    'Evaluările primite de la cumpărători': 'Reviews from buyers',
    'Setări': 'Settings',
    'Preferințe și securitate': 'Preferences and security',
    'Securitate': 'Security',
    'Parolă, 2FA și sesiuni': 'Password, 2FA and sessions',
    'Ajutor și suport': 'Help and support',
    'Ai nevoie de ajutor?': 'Need help?',
    'Deconectare': 'Sign out',
    'Gestionează preferințele, securitatea și datele contului.':
        'Manage your preferences, security and account data.',
    'Parolă, autentificare 2FA și sesiuni active':
        'Password, two-factor authentication and active sessions',
    'Preferințe notificări': 'Notification preferences',
    'Mesaje, oferte și activitatea contului':
        'Messages, offers and account activity',
    'Tema aplicației': 'App theme',
    'Luminos, întunecat sau automat': 'Light, dark or automatic',
    'Gestionează adresele pentru livrare': 'Manage delivery addresses',
    'Explorează categoriile': 'Explore categories',
    'Produse recomandate': 'Recommended products',
    'Produse noi': 'New products',
    'Produse promovate': 'Featured products',
    'Vezi toate': 'View all',
    'Descoperă produse atent selectate': 'Discover carefully selected items',
    'Cumpără și vinde simplu, într-o comunitate de încredere.':
        'Buy and sell easily in a trusted community.',
    'Explorează produsele': 'Explore products',
    'Vezi marketplace-ul': 'Open marketplace',
    'Anunțuri verificate': 'Verified listings',
    'Plăți sigure': 'Secure payments',
    'Livrare rapidă': 'Fast delivery',
    'De ce să alegi Nexora': 'Why choose Nexora',
    'Cumpără și vinde cu încredere': 'Buy and sell with confidence',
    'Descarcă aplicația Nexora': 'Download the Nexora app',
    'Cumpără și vinde de oriunde din aplicația mobilă.':
        'Buy and sell anywhere with the mobile app.',
    'Toate categoriile': 'All categories',
    'Categorie': 'Category',
    'Stare': 'Condition',
    'Toate': 'All',
    'Nou': 'New',
    'Ca nou': 'Like new',
    'Bună': 'Good',
    'Acceptabilă': 'Fair',
    'Filtre': 'Filters',
    'Resetează': 'Reset',
    'Reîncarcă': 'Reload',
    'Reîncearcă': 'Try again',
    'Nu am găsit produse': 'No products found',
    'Încearcă alte filtre sau o altă căutare.':
        'Try different filters or another search.',
    'Acasă': 'Home',
    'Descriere': 'Description',
    'Detalii produs': 'Product details',
    'Categorie produs': 'Product category',
    'Brand': 'Brand',
    'Mărime': 'Size',
    'Culoare': 'Color',
    'Material': 'Material',
    'Cumpără acum': 'Buy now',
    'Trimite mesaj': 'Send message',
    'Mesaj': 'Message',
    'Profil': 'Profile',
    'Vânzător': 'Seller',
    'Livrare disponibilă': 'Shipping available',
    'Livrare indisponibilă': 'Shipping unavailable',
    'Produse similare': 'Similar products',
    'Publică un anunț': 'Create a listing',
    'Completează pașii de mai jos pentru a publica produsul.':
        'Complete the steps below to publish your product.',
    'Fotografii': 'Photos',
    'Detalii articol': 'Item details',
    'Preț și livrare': 'Price and delivery',
    'Verificare': 'Review',
    'Adaugă până la 10 fotografii clare ale produsului.':
        'Add up to 10 clear photos of the product.',
    'Adaugă poze': 'Add photos',
    'Principală': 'Main',
    'Titlu anunț': 'Listing title',
    'Ex. Geacă Nike neagră': 'E.g. Black Nike jacket',
    'Descrie produsul, starea, defectele, dimensiunile și ce include...': 'Describe the item, condition, defects, dimensions and included parts...',
    'Subcategorie': 'Subcategory',
    'Tip produs': 'Product type',
    'Selectează categoria': 'Select category',
    'Selectează subcategoria': 'Select subcategory',
    'Selectează tipul': 'Select product type',
    'Starea produsului': 'Item condition',
    'Culori': 'Colors',
    'Material (recomandat)': 'Material (recommended)',
    'Opțional': 'Optional',
    'Preț': 'Price',
    'Oraș': 'City',
    'Preț negociabil': 'Negotiable price',
    'Permite cumpărătorilor să îți trimită oferte':
        'Allow buyers to send you offers',
    'Permite livrarea produsului către cumpărător':
        'Allow the item to be shipped to the buyer',
    'Înapoi': 'Back',
    'Continuă': 'Continue',
    'Publică anunțul': 'Publish listing',
    'Se publică...': 'Publishing...',
    'Previzualizare anunț': 'Listing preview',
    'Verifică informațiile înainte de publicare.':
        'Review the information before publishing.',
    'Adaugă cel puțin o imagine': 'Add at least one image',
    'Anunț publicat cu succes!': 'Listing published successfully!',
    'Introdu un titlu': 'Enter a title',
    'Titlul trebuie să aibă cel puțin 3 caractere':
        'The title must have at least 3 characters',
    'Adaugă o descriere': 'Add a description',
    'Descrierea trebuie să aibă cel puțin 20 de caractere':
        'The description must have at least 20 characters',
    'Introdu prețul': 'Enter the price',
    'Preț invalid': 'Invalid price',
    'Prețul trebuie să fie mai mare decât 0':
        'The price must be greater than 0',
    'Introdu orașul': 'Enter the city',
    'Completează câmpurile obligatorii pentru a continua.':
        'Complete the required fields to continue.',
    'Prin publicare, anunțul tău va deveni vizibil pe Nexora.':
        'Once published, your listing will be visible on Nexora.',
    'Limba interfeței': 'Interface language',
    'Română': 'Romanian',
    'Engleză': 'English',
    'Resetare parolă': 'Reset password',
    'Recuperează accesul la contul tău Nexora.':
        'Recover access to your Nexora account.',
    'Schimbă parola': 'Change password',
    'Folosește o parolă unică și sigură pentru cont':
        'Use a unique and secure password for your account',
    'Promovează anunțul': 'Promote listing',
    'Alege durata potrivită pentru mai multă vizibilitate.':
        'Choose the right duration for more visibility.',
    'Conversație': 'Conversation',
    'Verificare email': 'Email verification',
    'Confirmă sau modifică adresa asociată contului':
        'Confirm or update the email address linked to your account',
    'Gestionează adresele folosite pentru livrare':
        'Manage the addresses used for delivery',
    'Verificare telefon': 'Phone verification',
    'Confirmă numărul folosit pentru securitatea contului':
        'Confirm the phone number used for account security',
    'Editează profilul': 'Edit profile',
    'Actualizează informațiile vizibile în marketplace':
        'Update the information visible in the marketplace',
    'Comenzi și vânzări': 'Orders and sales',
    'Urmărește cumpărăturile și produsele vândute':
        'Track purchases and sold products',
    'Detalii comandă': 'Order details',
    'Se încarcă informațiile comenzii.': 'Loading order information.',
    'Nu am putut încărca informațiile.': 'The information could not be loaded.',
    'Urmărește starea și informațiile tranzacției.':
        'Track the status and transaction details.',
    'Alege ce actualizări vrei să primești':
        'Choose which updates you want to receive',
    'Protejează-ți contul și gestionează sesiunile active':
        'Protect your account and manage active sessions',
    'Activitatea recentă a contului tău': 'Recent account activity',
    'Evaluează vânzătorul': 'Rate the seller',
    'Ajută comunitatea împărtășind experiența ta.':
        'Help the community by sharing your experience.',
    'Alege o parolă nouă': 'Choose a new password',
    'Folosește o parolă sigură pentru contul tău.':
        'Use a secure password for your account.',
    'Crește vizibilitatea anunțurilor tale':
        'Increase the visibility of your listings',
    'Conversație suport': 'Support conversation',
    'Trimite solicitări și urmărește răspunsurile echipei':
        'Send requests and track replies from the team',
    'Verificare în 2 pași': 'Two-step verification',
    'Confirmă autentificarea cu codul tău de securitate.':
        'Confirm sign-in with your security code.',
    'Gestionează tranzacțiile și retragerile':
        'Manage transactions and withdrawals',
    'Tema site-ului': 'Website theme',
    'Personalizează aspectul interfeței Nexora':
        'Customize the Nexora interface',
    'Autentificare în doi pași': 'Two-factor authentication',
    'Protecție suplimentară pentru contul tău':
        'Additional protection for your account',
    'Sesiuni și dispozitive': 'Sessions and devices',
    'Controlează dispozitivele conectate la cont':
        'Control devices connected to your account',
  };

  static String translate(String source, String languageCode) {
    if (languageCode != 'en') return source;
    return _english[source] ?? source;
  }
}

extension AppTranslationContext on BuildContext {
  String tr(String source) {
    return AppTranslations.translate(source, appLocaleController.value);
  }
}
