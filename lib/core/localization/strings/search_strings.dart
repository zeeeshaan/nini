/// English display copy with stable local Search catalogue keys.
abstract final class SearchStrings {
  static const hint = "Search services";
  static const initialQuery = 'لوله‌کش';
  static const chooseCity = "Choose city";
  static const closeSearch = "Back to results";
  static const clearQuery = "Clear search";
  static const noResults = "No matching posts";
  static const providerUnavailable = 'Provider information is unavailable.';
  static const tryAnotherQuery =
      "Try a different keyword or choose another city.";
  static const showAll = "Browse all posts";
  static const allServices = 'All services';
  static const service = 'خدمات لوله‌کشی';
  static const currency = "toman";
  static const tehran = 'تهران';
  static const cities = [
    tehran,
    'مشهد',
    'اصفهان',
    'شیراز',
    'تبریز',
    'کرج',
    'اهواز',
    'قم',
    'کرمانشاه',
    'رشت',
    'ارومیه',
    'بندرعباس',
    'اراک',
    'یزد',
    'زاهدان',
    'همدان',
    'کرمان',
    'ساری',
    'قزوین',
    'سنندج',
    'اردبیل',
    'بوشهر',
    'بیرجند',
    'بجنورد',
    'ایلام',
    'خرم‌آباد',
    'زنجان',
    'سمنان',
    'شهرکرد',
    'گرگان',
    'یاسوج',
  ];
  static const emergencyPlumbing = 'لوله‌کشی فوری';
  static const drainCleaning = 'تخلیه چاه';
  static const blockedDrain = 'رفع گرفتگی فاضلاب';
  static const toiletRepair = 'تعمیر توالت';
  static const toiletInstallation = 'نصب توالت';
  static const leakDetection = 'تشخیص نشتی';
  static const waterLeakRepair = 'رفع نشتی آب';
  static const pipeRepair = 'تعمیر لوله';
  static const burstPipeRepair = 'تعمیر ترکیدگی لوله';
  static const boilerRepair = 'تعمیر پکیج';
  static const radiatorRepair = 'تعمیر رادیاتور';
  static const tapRepair = 'تعمیر شیر آب';
  static const faucetRepair = 'تعمیر شیرآلات';
  static const showerRepair = 'تعمیر دوش حمام';
  static const bathroomPlumbing = 'لوله‌کشی حمام';
  static const kitchenPlumbing = 'لوله‌کشی آشپزخانه';
  static const waterHeaterRepair = 'تعمیر آبگرمکن';
  static const gasPlumbing = 'لوله‌کشی گاز';

  // Keep canonical values stable for existing search IDs and saved bookings.
  static const _displayLabels = {
    emergencyPlumbing: 'Emergency plumbing',
    drainCleaning: 'Drain cleaning',
    blockedDrain: 'Blocked drain repair',
    toiletRepair: 'Toilet repair',
    toiletInstallation: 'Toilet installation',
    leakDetection: 'Leak detection',
    waterLeakRepair: 'Water leak repair',
    pipeRepair: 'Pipe repair',
    burstPipeRepair: 'Burst pipe repair',
    boilerRepair: 'Boiler repair',
    radiatorRepair: 'Radiator repair',
    tapRepair: 'Tap repair',
    faucetRepair: 'Faucet repair',
    showerRepair: 'Shower repair',
    bathroomPlumbing: 'Bathroom plumbing',
    kitchenPlumbing: 'Kitchen plumbing',
    waterHeaterRepair: 'Water heater repair',
    gasPlumbing: 'Gas plumbing',
    service: 'Plumbing services',
    tehran: "Tehran",
    'مشهد': "Mashhad",
    'اصفهان': "Isfahan",
    'شیراز': "Shiraz",
    'تبریز': "Tabriz",
    'کرج': "Karaj",
    'اهواز': "Ahvaz",
    'قم': "Qom",
    'کرمانشاه': "Kermanshah",
    'رشت': "Rasht",
    'ارومیه': "Urmia",
    'بندرعباس': "Bandar Abbas",
    'اراک': "Arak",
    'یزد': "Yazd",
    'زاهدان': "Zahedan",
    'همدان': "Hamadan",
    'کرمان': "Kerman",
    'ساری': "Sari",
    'قزوین': "Qazvin",
    'سنندج': "Sanandaj",
    'اردبیل': "Ardabil",
    'بوشهر': "Bushehr",
    'بیرجند': "Birjand",
    'بجنورد': "Bojnord",
    'ایلام': "Ilam",
    'خرم\u200cآباد': "Khorramabad",
    'زنجان': "Zanjan",
    'سمنان': "Semnan",
    'شهرکرد': "Shahrekord",
    'گرگان': "Gorgan",
    'یاسوج': "Yasuj",
    initialQuery: 'Plumber',
  };

  static String searchLabel(String value) => _displayLabels[value] ?? value;

  static String display(String value) => _displayLabels[value] ?? value;
}
