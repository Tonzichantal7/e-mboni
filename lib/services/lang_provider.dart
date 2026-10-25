import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Map<String, Map<String, String>> _translations = {
  'en': {
    // ── Blind user — welcome ─────────────────────────────────────────────────
    'appName':          'E-mboni',
    'tagline':          'Your mobility companion',
    'tapHint':          'tap anywhere to begin',

    // ── Blind user — voice ───────────────────────────────────────────────────
    'ready':            'E-mboni is ready. Tap once to start. Tap twice to record.',
    'startingNav':      'Starting navigation',
    'doneListening':    'Done listening',
    'listening':        'Listening. Say start to begin.',
    'sayStart':         'Say start to begin, or tap the screen.',
    'navStarted':       'Navigation started.',
    'navStopped':       'Navigation stopped. Stay safe.',
    'pathClear':        'Path is clear',
    'veryClose':        'very close',
    'ahead':            'ahead',
    'onYourLeft':       'on your left',
    'onYourRight':      'on your right',
    'moving':           'moving',
    'meters':           'meters',
    'lessThan1m':       'less than 1 meter',

    // ── Blind user — stop screen ─────────────────────────────────────────────
    'stopped':          'Stopped',
    'youAreSafe':       'You are safe.\nNavigation has ended.',
    'goHome':           'go home',

    // ── Blind user — navigation screen ──────────────────────────────────────
    'scanning':         'Scanning...',
    'holdToStop':       'hold to stop',
    'cameraNeeded':     'Camera access is needed to detect obstacles.',
    'allowCamera':      'Allow Camera',

    // ── Auth ─────────────────────────────────────────────────────────────────
    'whoAreYou':        'Who are you?',
    'guardian':         'Guardian',
    'guardianDesc':     'Parent, caregiver, or trusted person',
    'blindUser':        'Blind User',
    'blindUserDesc':    'Registered by a guardian on your behalf',
    'alreadyAccount':   'Already have an account?',
    'signIn':           'Sign in',
    'createAccount':    'Create Account',
    'yourDetails':      'YOUR DETAILS',
    'blindUserDetails': 'BLIND USER DETAILS',
    'yourFullName':     'Your Full Name',
    'yourPhone':        'Your Phone Number',
    'password':         'Password',
    'createPassword':   'Create a password',
    'theirName':        'Their Full Name',
    'relationship':     'Your Relationship (optional)',
    'relationshipHint': 'e.g. Mother, Sibling, Caregiver',
    'nextPrefs':        'Next — Set Preferences',
    'personGuiding':    'Person you are guiding',
    'registerBlind':    'Register Blind User',
    'registeringFor':   'You are registering this account on behalf of the blind user.',
    'phonOptional':     'Phone Number (optional)',
    'emergencyContact': 'Emergency Contact',
    'emergencyPhone':   'Emergency phone number',
    'preferredLang':    'Preferred Language',
    'voiceSpeed':       'Voice Speed',
    'slow':             'Slow',
    'normal':           'Normal',
    'fast':             'Fast',
    'done':             'Done — Go to Dashboard',
    'back':             'Back',
    'welcomeBack':      'Welcome back',
    'signInAccount':    'Sign in to your E-mboni account',

    // ── Emergency ────────────────────────────────────────────────────────────
    'emergencyActive':  'Emergency Active',
    'emergencyMsg':     'Stay calm. Your guardian is being notified.',
    'callGuardian':     'Call Guardian',
    'cancelEmergency':  'Cancel Emergency',
  },

  'rw': {
    // ── Blind user — welcome ─────────────────────────────────────────────────
    'appName':          'E-mboni',
    'tagline':          'Inshuti yawe yo gutunga',
    'tapHint':          'kanda aho ariho hose gutangira',

    // ── Blind user — voice ───────────────────────────────────────────────────
    'ready':            'E-mboni irategurwa. Kanda rimwe gutangira. Kanda kabiri kwandika.',
    'startingNav':      'Gutangira kuyobora',
    'doneListening':    'Kumva byarangiye',
    'listening':        'Ndumva. Vuga gutangira.',
    'sayStart':         'Vuga gutangira, cyangwa kanda aho ariho hose.',
    'navStarted':       'Kuyobora byatangiye.',
    'navStopped':       'Kuyobora byahagaritswe. Ugume mutekano.',
    'pathClear':        'Inzira irahari',
    'veryClose':        'hafi cyane',
    'ahead':            'imbere yawe',
    'onYourLeft':       'ibumoso bwawe',
    'onYourRight':      'iburyo bwawe',
    'moving':           'igenda',
    'meters':           'metero',
    'lessThan1m':       'munsi ya metero imwe',

    // ── Blind user — stop screen ─────────────────────────────────────────────
    'stopped':          'Byahagaritswe',
    'youAreSafe':       'Uri mugihe cyiza.\nKuyobora byarangiye.',
    'goHome':           'garuka ahabanza',

    // ── Blind user — navigation screen ──────────────────────────────────────
    'scanning':         'Gushakisha...',
    'holdToStop':       'shikama guhagarika',
    'cameraNeeded':     'Uburenganzira bwa kamera bukenewe kugira ngo tubashe kumenya inzitizi.',
    'allowCamera':      'Emera Kamera',

    // ── Auth ─────────────────────────────────────────────────────────────────
    'whoAreYou':        'Ni nde uri we?',
    'guardian':         'Umurezi',
    'guardianDesc':     'Umubyeyi, umujyanama, cyangwa umuntu wizewe',
    'blindUser':        'umuntu ufite ubumuga bwo kutabona',
    'blindUserDesc':    'Yandikishijwe na murezi mu izina ryawe',
    'alreadyAccount':   'Usanzwe ufite konti?',
    'signIn':           'Injira',
    'createAccount':    'Fungura Konti',
    'yourDetails':      'AMAKURU YAWE',
    'blindUserDetails': "AMAKURU Y'IMPUMYI",
    'yourFullName':     'Amazina Yawe Yose',
    'yourPhone':        'Nimero ya Telefoni Yawe',
    'password':         'Ijambo Banga',
    'createPassword':   'Shiraho ijambo banga',
    'theirName':        'Amazina Yabo Yose',
    'relationship':     'Isano Yanyu (si ngombwa)',
    'relationshipHint': 'urugero: Mama, Musaza, Umujyanama',
    'nextPrefs':        'Ibikurikira — Gushiraho Ibyo Ukunda',
    'personGuiding':    'Umuntu urongora',
    'registerBlind':    'Andika Impumyi',
    'registeringFor':   "Wandikisha konti iyi mu izina ry'impumyi.",
    'phonOptional':     'Nimero ya Telefoni (si ngombwa)',
    'emergencyContact': 'Uwahamagarwa mu Bihe Bikomeye',
    'emergencyPhone':   "Nimero ya telefoni y'uwahamagarwa",
    'preferredLang':    'Ururimi Rukunda',
    'voiceSpeed':       "Intera y'Ijwi",
    'slow':             'Buhoro',
    'normal':           'Bisanzwe',
    'fast':             'Vuba',
    'done':             'Rangiza — Jya ku Dashibodi',
    'back':             'Subira Inyuma',
    'welcomeBack':      'Murakaza neza',
    'signInAccount':    'Injira muri konti yawe ya E-mboni',

    // ── Emergency ────────────────────────────────────────────────────────────
    'emergencyActive':  'Impanuka Ihari',
    'emergencyMsg':     'Komera. Umurezi wawe aratangazwa.',
    'callGuardian':     'Hamagara Umurezi',
    'cancelEmergency':  'Hagarika Impanuka',
  },
};

class LangProvider extends ChangeNotifier {
  String _lang = 'en';
  String get lang => _lang;

  String t(String key) => _translations[_lang]?[key] ?? key;

  Future<void> setLang(String l) async {
    _lang = l;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', l);
  }

  Future<void> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    _lang = prefs.getString('lang') ?? 'en';
    notifyListeners();
  }
}
