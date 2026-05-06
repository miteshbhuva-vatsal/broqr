import 'package:flutter/material.dart';

/// Custom localization class covering EN / HI / GU.
/// Usage: `AppLocalizations.of(context).welcomeTitle`
class AppLocalizations {
  AppLocalizations(this.locale);
  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // ── All translations ───────────────────────────────────────────────────────

  static const Map<String, Map<String, String>> _t = {
    // ── English ──────────────────────────────────────────────────────────────
    'en': {
      // Common
      'appName': 'CPApp',
      'ok': 'OK',
      'cancel': 'Cancel',
      'save': 'Save',
      'back': 'Back',
      'loading': 'Loading…',
      'error': 'Error',
      'close': 'Close',
      'search': 'Search',
      'noResults': 'No results found',
      'retry': 'Retry',
      'done': 'Done',
      // Login
      'welcomeTitle': 'Welcome to CPApp',
      'welcomeSubtitle': 'Sign in to access exclusive broker deals',
      'signInWith': 'Sign in with',
      'continueWithGoogle': 'Continue with Google',
      'continueWithFacebook': 'Continue with Facebook',
      'termsText':
          'By continuing you agree to our Terms of Service\nand Privacy Policy.',
      'selectLanguage': 'Select Language',
      // Language screen
      'chooseLanguage': 'Choose Language',
      'languageEnglish': 'English',
      'languageHindi': 'हिंदी (Hindi)',
      'languageGujarati': 'ગુજરાતી (Gujarati)',
      'languageSaved': 'Language saved',
      // Onboarding
      'slide1Title': 'Find Stressed\nProperty Deals',
      'slide1Subtitle':
          'Browse exclusive Barter, Investor & Discount deals shared directly by verified brokers.',
      'slide2Title': 'Build Your\nBroker Network',
      'slide2Subtitle':
          'Connect with brokers across your city. Share deals, collaborate, and grow your referral pipeline.',
      'slide3Title': 'Manage Leads\nLike a Pro',
      'slide3Subtitle':
          'Built-in CRM to track every inquiry through your pipeline — from first contact to closed deal.',
      'skip': 'Skip',
      'next': 'Next',
      'getStarted': 'Get Started',
      // Profile setup / edit
      'setupProfileTitle': 'Set Up Your Profile',
      'setupProfileSubtitle':
          'Tell us who you are so others can connect with you.',
      'editProfileTitle': 'Edit Profile',
      'iAmA': 'I am a',
      'fullName': 'Full Name',
      'mobileNumber': 'Mobile Number',
      'city': 'City',
      'reraNumber': 'RERA Number',
      'tapToAddPhoto': 'Tap to add profile photo',
      'tapToChangePhoto': 'Tap to change photo',
      'reraHint': 'Leave blank if not yet registered with RERA',
      'saveAndContinue': 'Save & Continue',
      'saveChanges': 'Save Changes',
      'enterFullName': 'Enter your full name',
      'mobileRequired': 'Mobile number is required',
      'invalidMobile': 'Enter a valid 10-digit Indian mobile number',
      'selectCity': 'Please select your city',
      'selectRole': 'Please select your role',
      'selectYourCity': 'Select your city',
      'savingProfile': 'Saving your profile…',
      // Profile screen
      'contactInfo': 'Contact Info',
      'mobile': 'Mobile',
      'notSet': 'Not set',
      'email': 'Email',
      'verification': 'Verification',
      'signOut': 'Sign Out',
      'signOutConfirm': 'Are you sure you want to sign out?',
      'verifiedBroker': 'Verified Broker',
      'accountVerified': 'Your account is verified',
      'getVerified': 'Get Verified',
      'applyGreenTick': 'Apply for a green tick badge',
      'apply': 'Apply',
      'myListings': 'My Listings',
      'noListingsYet': 'No listings yet — tap + to post one',
      'myNetwork': 'My Network',
      'browseAndConnect': 'Browse and connect with brokers',
      'listings': 'Listings',
      'network': 'Network',
      'leads': 'Leads',
      'verificationRequestSent':
          'Verification request submitted. We\'ll review it shortly.',
      'profileUpdated': 'Profile updated',
      'couldNotLoadListings': 'Could not load listings',
      // Shell / nav
      'navFeed': 'Feed',
      'navNews': 'News',
      'navPost': 'Post',
      'navReminders': 'Reminders',
      'navCrm': 'CRM',
      // Feed
      'feedTitle': 'Property Feed',
      'inquiry': 'Inquiry',
      'contactLeadOwner': 'Contact Lead Owner',
      'noListings': 'No listings yet',
      'callNumber': 'Call',
      'allDeals': 'All',
      'myNetworkDeals': 'My Network',
      'myListingsDeals': 'My Listings',
      'filterDeals': 'Filter',
      'dealType': 'Deal Type',
      'propertyType': 'Property Type',
      'clearFilters': 'Clear Filters',
      'applyFilters': 'Apply Filters',
      // Network
      'networkTitle': 'Broker Network',
      'discover': 'Discover',
      'following': 'Following',
      'follow': 'Follow',
      'followingBtn': 'Following',
      'connections': 'connections',
      'brokerConnected': 'broker connected',
      'brokersConnected': 'brokers connected',
      'noFollowingYet': 'Not following anyone yet',
      'discoverAndFollow': 'Discover brokers and tap Follow',
      'followingHeader': 'FOLLOWING',
      'noBrokersFound': 'No brokers found',
      // CRM
      'crmTitle': 'My Pipeline',
      'noLeads': 'No leads yet',
      'addLead': 'Add Lead',
      'active': 'Active',
      'contacted': 'Contacted',
      'closed': 'Closed',
      'lost': 'Lost',
      'notes': 'Notes',
      'addNote': 'Add Note',
      'pipeline': 'Pipeline',
      'addFirstLead': '+ Add First Lead',
      'addFirstLeadHint': 'Start by adding your first lead or inquire on a listing.',
      'tryDifferentFilter': 'Try a different stage filter.',
      // Feed
      'brokerage': 'Brokerage',
      // Add Listing
      'addListingTitle': 'Add Listing',
      'publish': 'Publish',
      'uploadingPhotos': 'Uploading photos…',
      'publishingListing': 'Publishing your listing…',
      // OTP
      'verifyMobile': 'Verify Mobile Number',
      'requiredForContact': 'Required before contacting leads',
      'enterOtp': 'Enter OTP',
      'mobileLabel': 'Mobile Number',
      'otpLabel': '6-digit OTP',
      'sendOtp': 'Send OTP',
      'verifyOtp': 'Verify OTP',
      'enterValidMobile': 'Enter a valid 10-digit mobile number',
      'enterSixDigitOtp': 'Enter the 6-digit OTP',
      'changeNumber': 'Change number',
      'sentTo': 'Sent to +91 ',
      // App Guide
      'guideTitle': 'Quick Tour',
      'guideSkip': 'Skip Tour',
      'guideNext': 'Next',
      'guideDone': 'Done!',
      'guide1Title': 'Browse Property Deals',
      'guide1Body':
          'Swipe through exclusive stressed property listings shared by brokers.',
      'guide2Title': 'Post a Listing',
      'guide2Body':
          'Tap + to post your own deal and reach hundreds of brokers instantly.',
      'guide3Title': 'Manage Your Leads',
      'guide3Body':
          'Every inquiry you receive lands in your CRM automatically.',
      'guide4Title': 'Grow Your Network',
      'guide4Body':
          'Connect with brokers to collaborate and share co-broking opportunities.',
      'guide5Title': 'Track Reminders',
      'guide5Body':
          'Set follow-up reminders so you never miss a lead.',
    },

    // ── Hindi ─────────────────────────────────────────────────────────────────
    'hi': {
      // Common
      'appName': 'CPApp',
      'ok': 'ठीक है',
      'cancel': 'रद्द करें',
      'save': 'सेव करें',
      'back': 'वापस',
      'loading': 'लोड हो रहा है…',
      'error': 'त्रुटि',
      'close': 'बंद करें',
      'search': 'खोजें',
      'noResults': 'कोई परिणाम नहीं मिला',
      'retry': 'पुनः प्रयास करें',
      'done': 'हो गया',
      // Login
      'welcomeTitle': 'CPApp में आपका स्वागत है',
      'welcomeSubtitle': 'एक्सक्लूसिव ब्रोकर डील तक पहुंचने के लिए साइन इन करें',
      'signInWith': 'साइन इन करें',
      'continueWithGoogle': 'Google से जारी रखें',
      'continueWithFacebook': 'Facebook से जारी रखें',
      'termsText':
          'जारी रखकर आप हमारी सेवा की शर्तों और\nगोपनीयता नीति से सहमत होते हैं।',
      'selectLanguage': 'भाषा चुनें',
      // Language screen
      'chooseLanguage': 'भाषा चुनें',
      'languageEnglish': 'English',
      'languageHindi': 'हिंदी',
      'languageGujarati': 'ગુજરાતી (Gujarati)',
      'languageSaved': 'भाषा सेव की गई',
      // Onboarding
      'slide1Title': 'स्ट्रेस्ड प्रॉपर्टी\nडील खोजें',
      'slide1Subtitle':
          'सत्यापित ब्रोकरों द्वारा साझा किए गए एक्सक्लूसिव बार्टर, इन्वेस्टर और डिस्काउंट डील ब्राउज़ करें।',
      'slide2Title': 'अपना ब्रोकर\nनेटवर्क बनाएं',
      'slide2Subtitle':
          'अपने शहर के ब्रोकरों से जुड़ें। डील शेयर करें, सहयोग करें और अपनी रेफरल पाइपलाइन बढ़ाएं।',
      'slide3Title': 'प्रोफेशनल की तरह\nलीड मैनेज करें',
      'slide3Subtitle':
          'हर इंक्वायरी को पहले संपर्क से बंद डील तक ट्रैक करने के लिए बिल्ट-इन CRM।',
      'skip': 'छोड़ें',
      'next': 'आगे',
      'getStarted': 'शुरू करें',
      // Profile setup / edit
      'setupProfileTitle': 'अपना प्रोफाइल सेट करें',
      'setupProfileSubtitle': 'बताएं आप कौन हैं ताकि अन्य लोग आपसे जुड़ सकें।',
      'editProfileTitle': 'प्रोफाइल संपादित करें',
      'iAmA': 'मैं हूं',
      'fullName': 'पूरा नाम',
      'mobileNumber': 'मोबाइल नंबर',
      'city': 'शहर',
      'reraNumber': 'RERA नंबर',
      'tapToAddPhoto': 'प्रोफाइल फोटो जोड़ने के लिए टैप करें',
      'tapToChangePhoto': 'फोटो बदलने के लिए टैप करें',
      'reraHint': 'RERA में रजिस्टर नहीं हैं तो खाली छोड़ें',
      'saveAndContinue': 'सेव करें और जारी रखें',
      'saveChanges': 'बदलाव सेव करें',
      'enterFullName': 'अपना पूरा नाम दर्ज करें',
      'mobileRequired': 'मोबाइल नंबर आवश्यक है',
      'invalidMobile': 'एक वैध 10-अंकीय भारतीय मोबाइल नंबर दर्ज करें',
      'selectCity': 'कृपया अपना शहर चुनें',
      'selectRole': 'कृपया अपनी भूमिका चुनें',
      'selectYourCity': 'अपना शहर चुनें',
      'savingProfile': 'प्रोफाइल सेव हो रहा है…',
      // Profile screen
      'contactInfo': 'संपर्क जानकारी',
      'mobile': 'मोबाइल',
      'notSet': 'सेट नहीं है',
      'email': 'ईमेल',
      'verification': 'सत्यापन',
      'signOut': 'साइन आउट',
      'signOutConfirm': 'क्या आप वाकई साइन आउट करना चाहते हैं?',
      'verifiedBroker': 'सत्यापित ब्रोकर',
      'accountVerified': 'आपका खाता सत्यापित है',
      'getVerified': 'सत्यापित हों',
      'applyGreenTick': 'ग्रीन टिक बैज के लिए आवेदन करें',
      'apply': 'आवेदन करें',
      'myListings': 'मेरी लिस्टिंग',
      'noListingsYet': 'अभी कोई लिस्टिंग नहीं — + टैप करके पोस्ट करें',
      'myNetwork': 'मेरा नेटवर्क',
      'browseAndConnect': 'ब्रोकरों के साथ जुड़ें',
      'listings': 'लिस्टिंग',
      'network': 'नेटवर्क',
      'leads': 'लीड्स',
      'verificationRequestSent':
          'सत्यापन अनुरोध सबमिट हो गया। हम जल्द समीक्षा करेंगे।',
      'profileUpdated': 'प्रोफाइल अपडेट हो गया',
      'couldNotLoadListings': 'लिस्टिंग लोड नहीं हो सकी',
      // Shell / nav
      'navFeed': 'फीड',
      'navNews': 'समाचार',
      'navPost': 'पोस्ट',
      'navReminders': 'रिमाइंडर',
      'navCrm': 'CRM',
      // Feed
      'feedTitle': 'प्रॉपर्टी फीड',
      'inquiry': 'जांच करें',
      'contactLeadOwner': 'लीड ओनर से संपर्क करें',
      'noListings': 'अभी कोई लिस्टिंग नहीं',
      'callNumber': 'कॉल करें',
      'allDeals': 'सभी',
      'myNetworkDeals': 'मेरा नेटवर्क',
      'myListingsDeals': 'मेरी लिस्टिंग',
      'filterDeals': 'फ़िल्टर',
      'dealType': 'डील प्रकार',
      'propertyType': 'संपत्ति प्रकार',
      'clearFilters': 'फ़िल्टर हटाएं',
      'applyFilters': 'फ़िल्टर लगाएं',
      // Network
      'networkTitle': 'ब्रोकर नेटवर्क',
      'discover': 'खोजें',
      'following': 'फॉलोइंग',
      'follow': 'फॉलो करें',
      'followingBtn': 'फॉलो कर रहे हैं',
      'connections': 'कनेक्शन',
      'brokerConnected': 'ब्रोकर जुड़ा',
      'brokersConnected': 'ब्रोकर जुड़े',
      'noFollowingYet': 'अभी कोई फॉलो नहीं',
      'discoverAndFollow': 'ब्रोकरों को खोजें और फॉलो टैप करें',
      'followingHeader': 'फॉलोइंग',
      'noBrokersFound': 'कोई ब्रोकर नहीं मिला',
      // CRM
      'crmTitle': 'मेरी पाइपलाइन',
      'noLeads': 'अभी कोई लीड नहीं',
      'addLead': 'लीड जोड़ें',
      'active': 'सक्रिय',
      'contacted': 'संपर्क किया',
      'closed': 'बंद',
      'lost': 'खो गई',
      'notes': 'नोट्स',
      'addNote': 'नोट जोड़ें',
      'pipeline': 'पाइपलाइन',
      'addFirstLead': '+ पहली लीड जोड़ें',
      'addFirstLeadHint': 'पहली लीड जोड़कर या किसी लिस्टिंग पर इन्क्वायरी करके शुरू करें।',
      'tryDifferentFilter': 'अलग स्टेज फ़िल्टर आज़माएं।',
      // Feed
      'brokerage': 'ब्रोकरेज',
      // Add Listing
      'addListingTitle': 'लिस्टिंग जोड़ें',
      'publish': 'प्रकाशित करें',
      'uploadingPhotos': 'फोटो अपलोड हो रहे हैं…',
      'publishingListing': 'लिस्टिंग प्रकाशित हो रही है…',
      // OTP
      'verifyMobile': 'मोबाइल नंबर सत्यापित करें',
      'requiredForContact': 'लीड से संपर्क करने से पहले आवश्यक',
      'enterOtp': 'OTP दर्ज करें',
      'mobileLabel': 'मोबाइल नंबर',
      'otpLabel': '6-अंकीय OTP',
      'sendOtp': 'OTP भेजें',
      'verifyOtp': 'OTP सत्यापित करें',
      'enterValidMobile': 'एक वैध 10-अंकीय मोबाइल नंबर दर्ज करें',
      'enterSixDigitOtp': '6-अंकीय OTP दर्ज करें',
      'changeNumber': 'नंबर बदलें',
      'sentTo': '+91 पर भेजा गया ',
      // App Guide
      'guideTitle': 'त्वरित टूर',
      'guideSkip': 'टूर छोड़ें',
      'guideNext': 'आगे',
      'guideDone': 'हो गया!',
      'guide1Title': 'प्रॉपर्टी डील देखें',
      'guide1Body': 'ब्रोकरों द्वारा साझा की गई एक्सक्लूसिव प्रॉपर्टी लिस्टिंग देखें।',
      'guide2Title': 'लिस्टिंग पोस्ट करें',
      'guide2Body': '+ टैप करके अपनी डील पोस्ट करें और सैकड़ों ब्रोकरों तक पहुंचें।',
      'guide3Title': 'लीड्स मैनेज करें',
      'guide3Body': 'हर इंक्वायरी अपने आप आपके CRM में आ जाती है।',
      'guide4Title': 'नेटवर्क बढ़ाएं',
      'guide4Body': 'को-ब्रोकिंग के अवसर शेयर करने के लिए ब्रोकरों से जुड़ें।',
      'guide5Title': 'रिमाइंडर ट्रैक करें',
      'guide5Body': 'फॉलो-अप रिमाइंडर सेट करें ताकि कोई लीड न छूटे।',
    },

    // ── Gujarati ──────────────────────────────────────────────────────────────
    'gu': {
      // Common
      'appName': 'CPApp',
      'ok': 'ઠીક છે',
      'cancel': 'રદ કરો',
      'save': 'સેવ કરો',
      'back': 'પાછળ',
      'loading': 'લોડ થઈ રહ્યું છે…',
      'error': 'ભૂલ',
      'close': 'બંધ કરો',
      'search': 'શોધો',
      'noResults': 'કોઈ પરિણામ મળ્યું નથી',
      'retry': 'ફરી પ્રયાસ કરો',
      'done': 'થઈ ગ્યું',
      // Login
      'welcomeTitle': 'CPApp માં આપનું સ્વાગત છે',
      'welcomeSubtitle': 'એક્સક્લુઝિવ બ્રોકર ડીલ્સ ઍક્સેસ કરવા સાઇન ઇન કરો',
      'signInWith': 'સાઇન ઇન કરો',
      'continueWithGoogle': 'Google સાથે ચાલુ રાખો',
      'continueWithFacebook': 'Facebook સાથે ચાલુ રાખો',
      'termsText':
          'ચાલુ રાખવાથી તમે અમારી સેવાની શરતો અને\nગોપનીયતા નીતિ સાથે સહમત છો.',
      'selectLanguage': 'ભાષા પસંદ કરો',
      // Language screen
      'chooseLanguage': 'ભાષા પસંદ કરો',
      'languageEnglish': 'English',
      'languageHindi': 'हिंदी (Hindi)',
      'languageGujarati': 'ગુજરાતી',
      'languageSaved': 'ભાષા સેવ થઈ',
      // Onboarding
      'slide1Title': 'સ્ટ્રેસ્ડ પ્રોપર્ટી\nડીલ્સ શોધો',
      'slide1Subtitle':
          'સત્યાપિત બ્રોકરો દ્વારા સીધી શેર કરેલ એક્સક્લુઝિવ બાર્ટર, ઇન્વેસ્ટર અને ડિસ્કાઉન્ટ ડીલ્સ જુઓ.',
      'slide2Title': 'તમારું બ્રોકર\nનેટવર્ક બનાવો',
      'slide2Subtitle':
          'તમારા શહેરના બ્રોકરો સાથે જોડાઓ. ડીલ્સ શેર કરો, સહયોગ કરો અને રેફરલ પાઇપલાઇન વધારો.',
      'slide3Title': 'પ્રો જેવા લીડ્સ\nમેનેજ કરો',
      'slide3Subtitle':
          'દરેક ઇન્ક્વાયરીને પ્રથમ સંપર્કથી બંધ ડીલ સુધી ટ્રૅક કરવા માટે બિલ્ટ-ઇન CRM.',
      'skip': 'છોડો',
      'next': 'આગળ',
      'getStarted': 'શરૂ કરો',
      // Profile setup / edit
      'setupProfileTitle': 'તમારી પ્રોફાઇલ સેટ કરો',
      'setupProfileSubtitle':
          'જણાવો કે તમે કોણ છો જેથી અન્ય લોકો તમારી સાથે જોડાઈ શકે.',
      'editProfileTitle': 'પ્રોફાઇલ સંપાદિત કરો',
      'iAmA': 'હું છું',
      'fullName': 'પૂરું નામ',
      'mobileNumber': 'મોબાઇલ નંબર',
      'city': 'શહેર',
      'reraNumber': 'RERA નંબર',
      'tapToAddPhoto': 'પ્રોફાઇલ ફોટો ઉમેરવા ટૅપ કરો',
      'tapToChangePhoto': 'ફોટો બદલવા ટૅપ કરો',
      'reraHint': 'RERA માં નોંધણી ન હોય તો ખાલી છોડો',
      'saveAndContinue': 'સેવ કરો અને ચાલુ રાખો',
      'saveChanges': 'ફેરફારો સેવ કરો',
      'enterFullName': 'તમારું પૂરું નામ દાખલ કરો',
      'mobileRequired': 'મોબાઇલ નંબર જરૂરી છે',
      'invalidMobile': '10 અંકનો માન્ય ભારતીય મોબાઇલ નંબર દાખલ કરો',
      'selectCity': 'કૃપા કરીને તમારું શહેર પસંદ કરો',
      'selectRole': 'કૃપા કરીને તમારી ભૂમિકા પસંદ કરો',
      'selectYourCity': 'તમારું શહેર પસંદ કરો',
      'savingProfile': 'પ્રોફાઇલ સેવ થઈ રહ્યું છે…',
      // Profile screen
      'contactInfo': 'સંપર્ક માહિતી',
      'mobile': 'મોબાઇલ',
      'notSet': 'સેટ નથી',
      'email': 'ઇમેઇલ',
      'verification': 'ચકાસણી',
      'signOut': 'સાઇન આઉટ',
      'signOutConfirm': 'શું તમે ખરેખર સાઇન આઉટ કરવા માંગો છો?',
      'verifiedBroker': 'ચકાસાયેલ બ્રોકર',
      'accountVerified': 'તમારું ખાતું ચકાસાઈ ગ્યું છે',
      'getVerified': 'ચકાસણી મેળવો',
      'applyGreenTick': 'ગ્રીન ટિક બેજ માટે અરજી કરો',
      'apply': 'અરજી કરો',
      'myListings': 'મારી લિસ્ટિંગ',
      'noListingsYet': 'હજી કોઈ લિસ્ટિંગ નથી — + ટૅપ કરીને પોસ્ટ કરો',
      'myNetwork': 'મારું નેટવર્ક',
      'browseAndConnect': 'બ્રોકરો સાથે જોડાઓ',
      'listings': 'લિસ્ટિંગ',
      'network': 'નેટવર્ક',
      'leads': 'લીડ્સ',
      'verificationRequestSent':
          'ચકાસણી વિનંતી સબમિટ થઈ. અમે ટૂંક સમયમાં સમીક્ષા કરીશું.',
      'profileUpdated': 'પ્રોફાઇલ અપડેટ થઈ',
      'couldNotLoadListings': 'લિસ્ટિંગ લોડ ન થઈ',
      // Shell / nav
      'navFeed': 'ફીડ',
      'navNews': 'સમાચાર',
      'navPost': 'પોસ્ટ',
      'navReminders': 'રિમાઇન્ડર',
      'navCrm': 'CRM',
      // Feed
      'feedTitle': 'પ્રોપર્ટી ફીડ',
      'inquiry': 'ઇન્ક્વાયરી',
      'contactLeadOwner': 'લીડ ઓનરનો સંપર્ક કરો',
      'noListings': 'હજી કોઈ લિસ્ટિંગ નથી',
      'callNumber': 'કૉલ કરો',
      'allDeals': 'બધા',
      'myNetworkDeals': 'મારું નેટવર્ક',
      'myListingsDeals': 'મારી લિસ્ટિંગ',
      'filterDeals': 'ફિલ્ટર',
      'dealType': 'ડીલ પ્રકાર',
      'propertyType': 'સંપત્તિ પ્રકાર',
      'clearFilters': 'ફિલ્ટર સાફ કરો',
      'applyFilters': 'ફિલ્ટર લગાવો',
      // Network
      'networkTitle': 'બ્રોકર નેટવર્ક',
      'discover': 'શોધો',
      'following': 'ફૉલોઇંગ',
      'follow': 'ફૉલો કરો',
      'followingBtn': 'ફૉલો કરી રહ્યા છો',
      'connections': 'કનેક્શન',
      'brokerConnected': 'બ્રોકર જોડાયો',
      'brokersConnected': 'બ્રોકર જોડાયા',
      'noFollowingYet': 'હજી કોઈ ફૉલો નથી',
      'discoverAndFollow': 'બ્રોકરો શોધો અને ફૉલો ટૅપ કરો',
      'followingHeader': 'ફૉલોઇંગ',
      'noBrokersFound': 'કોઈ બ્રોકર ન મળ્યો',
      // CRM
      'crmTitle': 'મારી પાઇપલાઇન',
      'noLeads': 'હજી કોઈ લીડ નથી',
      'addLead': 'લીડ ઉમેરો',
      'active': 'સક્રિય',
      'contacted': 'સંપર્ક કર્યો',
      'closed': 'બંધ',
      'lost': 'ગુમ',
      'notes': 'નોંધ',
      'addNote': 'નોંધ ઉમેરો',
      'pipeline': 'પાઇપલાઇન',
      'addFirstLead': '+ પ્રથમ લીડ ઉમેરો',
      'addFirstLeadHint': 'પ્રથમ લીડ ઉમેરીને અથવા કોઈ લિસ્ટિંગ પર ઇન્ક્વાયરી કરીને શરૂ કરો.',
      'tryDifferentFilter': 'અલગ સ્ટેજ ફિલ્ટર અજમાવો.',
      // Feed
      'brokerage': 'બ્રોકરેજ',
      // Add Listing
      'addListingTitle': 'લિસ્ટિંગ ઉમેરો',
      'publish': 'પ્રકાશિત કરો',
      'uploadingPhotos': 'ફોટો અપલોડ થઈ રહ્યા છે…',
      'publishingListing': 'લિસ્ટિંગ પ્રકાશિત થઈ રહી છે…',
      // OTP
      'verifyMobile': 'મોબાઇલ નંબર ચકાસો',
      'requiredForContact': 'લીડ્સ સંપર્ક કરતા પહેલા જરૂરી',
      'enterOtp': 'OTP દાખલ કરો',
      'mobileLabel': 'મોબાઇલ નંબર',
      'otpLabel': '6 અંકનો OTP',
      'sendOtp': 'OTP મોકલો',
      'verifyOtp': 'OTP ચકાસો',
      'enterValidMobile': '10 અંકનો માન્ય મોબાઇલ નંબર દાખલ કરો',
      'enterSixDigitOtp': '6 અંકનો OTP દાખલ કરો',
      'changeNumber': 'નંબર બદલો',
      'sentTo': '+91 પર મોકલ્યો ',
      // App Guide
      'guideTitle': 'ઝડપી ટૂર',
      'guideSkip': 'ટૂર છોડો',
      'guideNext': 'આગળ',
      'guideDone': 'થઈ ગ્યું!',
      'guide1Title': 'પ્રોપર્ટી ડીલ્સ જુઓ',
      'guide1Body': 'બ્રોકરો દ્વારા શેર કરેલ એક્સક્લુઝિવ સ્ટ્રેસ્ડ પ્રોપર્ટી લિસ્ટિંગ જુઓ.',
      'guide2Title': 'લિસ્ટિંગ પોસ્ટ કરો',
      'guide2Body': '+ ટૅપ કરીને ડીલ પોસ્ટ કરો અને સેંકડો બ્રોકરો સુધી પહોંચો.',
      'guide3Title': 'લીડ્સ મેનેજ કરો',
      'guide3Body': 'દરેક ઇન્ક્વાયરી આપોઆપ તમારા CRM માં આવે છે.',
      'guide4Title': 'નેટવર્ક વધારો',
      'guide4Body': 'કો-બ્રોકિંગ તકો શેર કરવા બ્રોકરો સાથે જોડાઓ.',
      'guide5Title': 'રિમાઇન્ડર ટ્રૅક કરો',
      'guide5Body': 'ફૉલો-અપ રિમાઇન્ડર સેટ કરો જેથી કોઈ લીડ ચૂકી ન જાઓ.',
    },
  };

  // ── Named string accessors ─────────────────────────────────────────────────

  String _s(String key) =>
      _t[locale.languageCode]?[key] ?? _t['en']![key] ?? key;

  // Common
  String get appName => _s('appName');
  String get ok => _s('ok');
  String get cancel => _s('cancel');
  String get save => _s('save');
  String get back => _s('back');
  String get loading => _s('loading');
  String get error => _s('error');
  String get close => _s('close');
  String get search => _s('search');
  String get noResults => _s('noResults');
  String get retry => _s('retry');
  String get done => _s('done');
  // Login
  String get welcomeTitle => _s('welcomeTitle');
  String get welcomeSubtitle => _s('welcomeSubtitle');
  String get signInWith => _s('signInWith');
  String get continueWithGoogle => _s('continueWithGoogle');
  String get continueWithFacebook => _s('continueWithFacebook');
  String get termsText => _s('termsText');
  String get selectLanguage => _s('selectLanguage');
  // Language screen
  String get chooseLanguage => _s('chooseLanguage');
  String get languageEnglish => _s('languageEnglish');
  String get languageHindi => _s('languageHindi');
  String get languageGujarati => _s('languageGujarati');
  String get languageSaved => _s('languageSaved');
  // Onboarding
  String get slide1Title => _s('slide1Title');
  String get slide1Subtitle => _s('slide1Subtitle');
  String get slide2Title => _s('slide2Title');
  String get slide2Subtitle => _s('slide2Subtitle');
  String get slide3Title => _s('slide3Title');
  String get slide3Subtitle => _s('slide3Subtitle');
  String get skip => _s('skip');
  String get next => _s('next');
  String get getStarted => _s('getStarted');
  // Profile setup / edit
  String get setupProfileTitle => _s('setupProfileTitle');
  String get setupProfileSubtitle => _s('setupProfileSubtitle');
  String get editProfileTitle => _s('editProfileTitle');
  String get iAmA => _s('iAmA');
  String get fullName => _s('fullName');
  String get mobileNumber => _s('mobileNumber');
  String get city => _s('city');
  String get reraNumber => _s('reraNumber');
  String get tapToAddPhoto => _s('tapToAddPhoto');
  String get tapToChangePhoto => _s('tapToChangePhoto');
  String get reraHint => _s('reraHint');
  String get saveAndContinue => _s('saveAndContinue');
  String get saveChanges => _s('saveChanges');
  String get enterFullName => _s('enterFullName');
  String get mobileRequired => _s('mobileRequired');
  String get invalidMobile => _s('invalidMobile');
  String get selectCity => _s('selectCity');
  String get selectRole => _s('selectRole');
  String get selectYourCity => _s('selectYourCity');
  String get savingProfile => _s('savingProfile');
  // Profile screen
  String get contactInfo => _s('contactInfo');
  String get mobile => _s('mobile');
  String get notSet => _s('notSet');
  String get email => _s('email');
  String get verification => _s('verification');
  String get signOut => _s('signOut');
  String get signOutConfirm => _s('signOutConfirm');
  String get verifiedBroker => _s('verifiedBroker');
  String get accountVerified => _s('accountVerified');
  String get getVerified => _s('getVerified');
  String get applyGreenTick => _s('applyGreenTick');
  String get apply => _s('apply');
  String get myListings => _s('myListings');
  String get noListingsYet => _s('noListingsYet');
  String get myNetwork => _s('myNetwork');
  String get browseAndConnect => _s('browseAndConnect');
  String get listings => _s('listings');
  String get network => _s('network');
  String get leads => _s('leads');
  String get verificationRequestSent => _s('verificationRequestSent');
  String get profileUpdated => _s('profileUpdated');
  String get couldNotLoadListings => _s('couldNotLoadListings');
  // Shell / nav
  String get navFeed => _s('navFeed');
  String get navNews => _s('navNews');
  String get navPost => _s('navPost');
  String get navReminders => _s('navReminders');
  String get navCrm => _s('navCrm');
  // Feed
  String get feedTitle => _s('feedTitle');
  String get inquiry => _s('inquiry');
  String get contactLeadOwner => _s('contactLeadOwner');
  String get noListings => _s('noListings');
  String get callNumber => _s('callNumber');
  String get allDeals => _s('allDeals');
  String get myNetworkDeals => _s('myNetworkDeals');
  String get myListingsDeals => _s('myListingsDeals');
  String get filterDeals => _s('filterDeals');
  String get dealType => _s('dealType');
  String get propertyType => _s('propertyType');
  String get clearFilters => _s('clearFilters');
  String get applyFilters => _s('applyFilters');
  // Network
  String get networkTitle => _s('networkTitle');
  String get discover => _s('discover');
  String get following => _s('following');
  String get follow => _s('follow');
  String get followingBtn => _s('followingBtn');
  String get connections => _s('connections');
  String get brokerConnected => _s('brokerConnected');
  String get brokersConnected => _s('brokersConnected');
  String get noFollowingYet => _s('noFollowingYet');
  String get discoverAndFollow => _s('discoverAndFollow');
  String get followingHeader => _s('followingHeader');
  String get noBrokersFound => _s('noBrokersFound');
  // CRM
  String get crmTitle => _s('crmTitle');
  String get noLeads => _s('noLeads');
  String get addLead => _s('addLead');
  String get active => _s('active');
  String get contacted => _s('contacted');
  String get closed => _s('closed');
  String get lost => _s('lost');
  String get notes => _s('notes');
  String get addNote => _s('addNote');
  String get pipeline => _s('pipeline');
  String get addFirstLead => _s('addFirstLead');
  String get addFirstLeadHint => _s('addFirstLeadHint');
  String get tryDifferentFilter => _s('tryDifferentFilter');
  // Feed
  String get brokerage => _s('brokerage');
  // Add Listing
  String get addListingTitle => _s('addListingTitle');
  String get publish => _s('publish');
  String get uploadingPhotos => _s('uploadingPhotos');
  String get publishingListing => _s('publishingListing');
  // OTP
  String get verifyMobile => _s('verifyMobile');
  String get requiredForContact => _s('requiredForContact');
  String get enterOtp => _s('enterOtp');
  String get mobileLabel => _s('mobileLabel');
  String get otpLabel => _s('otpLabel');
  String get sendOtp => _s('sendOtp');
  String get verifyOtp => _s('verifyOtp');
  String get enterValidMobile => _s('enterValidMobile');
  String get enterSixDigitOtp => _s('enterSixDigitOtp');
  String get changeNumber => _s('changeNumber');
  String get sentTo => _s('sentTo');
  // App Guide
  String get guideTitle => _s('guideTitle');
  String get guideSkip => _s('guideSkip');
  String get guideNext => _s('guideNext');
  String get guideDone => _s('guideDone');
  String get guide1Title => _s('guide1Title');
  String get guide1Body => _s('guide1Body');
  String get guide2Title => _s('guide2Title');
  String get guide2Body => _s('guide2Body');
  String get guide3Title => _s('guide3Title');
  String get guide3Body => _s('guide3Body');
  String get guide4Title => _s('guide4Title');
  String get guide4Body => _s('guide4Body');
  String get guide5Title => _s('guide5Title');
  String get guide5Body => _s('guide5Body');
}

// ── Delegate ──────────────────────────────────────────────────────────────────

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'hi', 'gu'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
