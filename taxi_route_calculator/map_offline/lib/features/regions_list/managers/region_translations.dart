/// Словарь переводов названий регионов и городов с английского на русский
/// для такси приложения. Используется для перевода данных, 
/// получаемых от Yandex MapKit API.
class RegionTranslations {
  static const Map<String, String> regionNames = {
    // Regions / Области
    'Perm Krai': 'Пермский край',
    'Rostov Oblast': 'Ростовская область',
    'Sverdlovsk Oblast': 'Свердловская область',
    'Krasnodar Krai': 'Краснодарский край',
    'Moscow Oblast': 'Московская область',
    'Saint Petersburg': 'Санкт-Петербург',
    'Nizhny Novgorod Oblast': 'Нижегородская область',
    'Chelyabinsk Oblast': 'Челябинская область',
    'Samara Oblast': 'Самарская область',
    'Tatarstan': 'Татарстан',
    'Bashkortostan': 'Башкортостан',
    'Novosibirsk Oblast': 'Новосибирская область',
    'Kemerovo Oblast': 'Кемеровская область',
    'Omsk Oblast': 'Омская область',
    'Volgograd Oblast': 'Волгоградская область',
    'Voronezh Oblast': 'Воронежская область',
    'Krasnoyarsk Krai': 'Красноярский край',
    'Saratov Oblast': 'Саратовская область',
    'Tula Oblast': 'Тульская область',
    'Yaroslavl Oblast': 'Ярославская область',
    
    // International Regions / Международные регионы
    'Abai Region': 'Абайская область',
    'Asir Region': 'Провинция Асир',
    'Abakan': 'Абакан',
    'Abidjan': 'Абиджан',
  };

  static const Map<String, String> cityNames = {
    // Major Cities / Крупные города
    'Perm': 'Пермь',
    'Berezniki': 'Березники',
    'Solikamsk': 'Соликамск',
    'Chaikovsky': 'Чайковский',
    'Kungur': 'Кунгур',
    'Lysva': 'Лысьва',
    'Krasnokamsk': 'Краснокамск',
    'Chusovoy': 'Чусовой',
    'Chernushka': 'Чернушка',
    'Kudimkar': 'Кудымкар',
    
    'Rostov-na-Donu': 'Ростов-на-Дону',
    'Taganrog': 'Таганрог',
    'Shakhty': 'Шахты',
    'Volgodonsk': 'Волгодонск',
    'Novocherkassk': 'Новочеркасск',
    'Bataysk': 'Батайск',
    'Novoshakhtinsk': 'Новошахтинск',
    'Kamensk-Shakhtinsky': 'Каменск-Шахтинский',
    'Azov': 'Азов',
    'Gukovo': 'Гуково',
    
    'Yekaterinburg': 'Екатеринбург',
    'Nizhniy Tagil': 'Нижний Тагил',
    'Kamensk-Uralskiy': 'Каменск-Уральский',
    'Pervouralsk': 'Первоуральск',
    'Serov': 'Серов',
    'Novouralsk': 'Новоуральск',
    'Verkhnyaya Pyshma': 'Верхняя Пышма',
    'Berezovskyi': 'Березовский',
    'Revda': 'Ревда',
    'Asbest': 'Асбест',
    
    // International Cities / Международные города
    'Bisha': 'Биша',
    'Abha': 'Абха',
    'Khamis Mushayt': 'Хамис-Мушайт',
    'Semey': 'Семей',
    'Abakan': 'Абакан',
  };

  /// Переводит название региона на русский язык
  static String translateRegionName(String originalName) {
    return regionNames[originalName] ?? originalName;
  }

  /// Переводит название города на русский язык
  static String translateCityName(String originalName) {
    return cityNames[originalName] ?? originalName;
  }

  /// Переводит список городов на русский язык
  static List<String> translateCityList(List<String> originalCities) {
    return originalCities
        .map((city) => translateCityName(city))
        .toList();
  }
}