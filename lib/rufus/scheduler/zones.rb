#--
# Copyright (c) 2006-2015, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++


class Rufus::Scheduler

TIMEZONES = %w[
GB NZ UCT EET CET PRC ROC WET GMT EST ROK UTC MST HST MET Zulu Cuba Iran W-SU
Eire GMT0 Libya Japan Egypt GMT+0 GMT-0 Israel Poland Navajo Turkey GB-Eire
Iceland PST8PDT Etc/UCT CST6CDT NZ-CHAT MST7MDT Jamaica EST5EDT Etc/GMT Etc/UTC
US/Samoa Etc/GMT0 Portugal Hongkong Etc/Zulu Singapore Asia/Baku Etc/GMT-9
Etc/GMT+1 Etc/GMT+0 Asia/Aden Etc/GMT+2 Etc/GMT+3 Etc/GMT+4 Etc/GMT+5 Etc/GMT+6
Etc/GMT+7 Etc/GMT+8 Etc/GMT+9 Etc/GMT-0 Etc/GMT-1 Universal Asia/Dili Greenwich
Asia/Gaza Etc/GMT-8 Etc/GMT-7 US/Alaska Asia/Oral Etc/GMT-6 Etc/GMT-5 Etc/GMT-4
Asia/Hovd Etc/GMT-3 US/Hawaii Etc/GMT-2 Kwajalein Asia/Omsk Asia/Macao
Etc/GMT-14 Asia/Kabul US/Central Etc/GMT-13 US/Arizona Asia/Macau Asia/Qatar
Asia/Seoul Asia/Tokyo Asia/Dubai US/Pacific Etc/GMT-12 Etc/GMT-11 Etc/GMT-10
Asia/Dhaka Asia/Dacca Asia/Chita Etc/GMT+12 Etc/GMT+10 Asia/Amman Asia/Aqtau
Etc/GMT+11 US/Eastern Asia/Thimbu Asia/Brunei Asia/Tehran Asia/Beirut
Europe/Rome Europe/Riga Brazil/Acre Brazil/East Europe/Oslo Brazil/West
Africa/Lome Asia/Taipei Asia/Saigon Asia/Riyadh Asia/Aqtobe Asia/Anadyr
Europe/Kiev Asia/Almaty Africa/Juba Pacific/Yap US/Aleutian Asia/Muscat
US/Mountain Asia/Harbin Asia/Hebron Asia/Manila Asia/Kuwait Asia/Urumqi
US/Michigan Indian/Mahe SystemV/EST5 Asia/Kashgar Indian/Cocos Asia/Jakarta
Asia/Kolkata Asia/Kuching America/Atka Asia/Irkutsk Pacific/Apia Asia/Magadan
Africa/Dakar America/Lima Pacific/Fiji Pacific/Guam Europe/Vaduz Pacific/Niue
Asia/Nicosia Africa/Ceuta Pacific/Truk America/Adak Pacific/Wake Africa/Tunis
Africa/Cairo Asia/Colombo SystemV/AST4 SystemV/CST6 Asia/Karachi Asia/Rangoon
SystemV/MST7 Asia/Baghdad Europe/Malta Africa/Lagos Europe/Minsk SystemV/PST8
Canada/Yukon Asia/Tbilisi America/Nome Asia/Bahrain Africa/Accra Europe/Paris
Asia/Bangkok Asia/Bishkek Asia/Thimphu SystemV/YST9 Asia/Yerevan Asia/Yakutsk
Europe/Sofia Asia/Ust-Nera Australia/ACT Australia/LHI Europe/Tirane
Asia/Tel_Aviv Australia/NSW Africa/Luanda Asia/Tashkent Africa/Lusaka
Asia/Shanghai Africa/Malabo Asia/Sakhalin Africa/Maputo Africa/Maseru
SystemV/HST10 Africa/Kigali Africa/Niamey Pacific/Samoa America/Sitka
Pacific/Palau Pacific/Nauru Pacific/Efate Asia/Makassar Pacific/Chuuk
Africa/Harare Africa/Douala America/Aruba America/Thule America/Bahia
America/Jujuy America/Belem Asia/Katmandu America/Boise Indian/Comoro
Indian/Chagos Asia/Jayapura Europe/Zurich Asia/Istanbul Europe/Zagreb
Etc/Greenwich Europe/Warsaw Europe/Vienna Etc/Universal Asia/Dushanbe
Europe/Athens Europe/Berlin Africa/Bissau Asia/Damascus Africa/Banjul
Europe/Dublin Africa/Bangui Africa/Bamako Europe/Jersey Africa/Asmera
Europe/Lisbon Africa/Asmara Europe/London Asia/Ashgabat Asia/Calcutta
Europe/Madrid Europe/Monaco Europe/Moscow Europe/Prague Europe/Samara
Europe/Skopje Asia/Khandyga Canada/Pacific Africa/Abidjan America/Manaus
Asia/Chongqing Asia/Chungking Africa/Algiers America/Maceio US/Pacific-New
Africa/Conakry America/La_Paz America/Juneau America/Nassau America/Inuvik
Europe/Andorra Africa/Kampala Asia/Ashkhabad Asia/Hong_Kong America/Havana
Canada/Eastern Europe/Belfast Canada/Central Australia/West Asia/Jerusalem
Africa/Mbabane Asia/Kamchatka America/Virgin America/Guyana Asia/Kathmandu
Mexico/General America/Panama Europe/Nicosia America/Denver Europe/Tallinn
Africa/Nairobi America/Dawson Europe/Vatican Europe/Vilnius America/Cuiaba
Africa/Tripoli Pacific/Wallis Atlantic/Faroe Pacific/Tarawa Pacific/Tahiti
Pacific/Saipan Pacific/Ponape America/Cayman America/Cancun Asia/Pontianak
Asia/Pyongyang Asia/Vientiane Asia/Qyzylorda Pacific/Noumea America/Bogota
Pacific/Midway Pacific/Majuro Asia/Samarkand Indian/Mayotte Pacific/Kosrae
Asia/Singapore Indian/Reunion America/Belize America/Regina America/Recife
Pacific/Easter Mexico/BajaSur America/Merida Pacific/Chatham Pacific/Fakaofo
Pacific/Gambier America/Rosario Asia/Ulan_Bator Indian/Maldives Pacific/Norfolk
America/Antigua Asia/Phnom_Penh America/Phoenix America/Caracas America/Cayenne
Atlantic/Azores Pacific/Pohnpei Atlantic/Canary America/Chicago Atlantic/Faeroe
Africa/Windhoek America/Cordoba America/Creston Africa/Timbuktu America/Curacao
Africa/Sao_Tome Africa/Ndjamena SystemV/AST4ADT Europe/Uzhgorod Europe/Tiraspol
SystemV/CST6CDT Africa/Monrovia America/Detroit Europe/Sarajevo Australia/Eucla
America/Tijuana America/Toronto America/Godthab America/Grenada Europe/Istanbul
America/Ojinaga America/Tortola Australia/Perth Europe/Helsinki Australia/South
Europe/Guernsey SystemV/EST5EDT Europe/Chisinau SystemV/MST7MDT Europe/Busingen
Europe/Budapest Europe/Brussels America/Halifax America/Mendoza America/Noronha
America/Nipigon Canada/Atlantic America/Yakutat SystemV/PST8PDT SystemV/YST9YDT
Canada/Mountain Africa/Kinshasa Africa/Khartoum Africa/Gaborone Africa/Freetown
America/Iqaluit America/Jamaica US/East-Indiana Africa/El_Aaiun America/Knox_IN
Africa/Djibouti Africa/Blantyre America/Moncton America/Managua Asia/Choibalsan
America/Marigot Australia/North Europe/Belgrade America/Resolute
America/Mazatlan Pacific/Funafuti Pacific/Auckland Pacific/Honolulu
Pacific/Johnston America/Miquelon America/Santarem Mexico/BajaNorte
America/Santiago Antarctica/Troll America/Asuncion America/Atikokan
America/Montreal America/Barbados Africa/Bujumbura Pacific/Pitcairn
Asia/Ulaanbaatar Indian/Mauritius America/New_York Antarctica/Syowa
America/Shiprock Indian/Kerguelen Asia/Novosibirsk America/Anguilla
Indian/Christmas Asia/Vladivostok Asia/Ho_Chi_Minh Antarctica/Davis
Atlantic/Bermuda Europe/Amsterdam Antarctica/Casey America/St_Johns
Atlantic/Madeira America/Winnipeg America/St_Kitts Europe/Volgograd
Brazil/DeNoronha Europe/Bucharest Africa/Mogadishu America/St_Lucia
Atlantic/Stanley Europe/Stockholm Australia/Currie Europe/Gibraltar
Australia/Sydney Asia/Krasnoyarsk Australia/Darwin America/Dominica
America/Edmonton America/Eirunepe Europe/Podgorica America/Ensenada
Europe/Ljubljana Australia/Hobart Europe/Mariehamn Africa/Lubumbashi
America/Goose_Bay Europe/Luxembourg America/Menominee America/Glace_Bay
America/Fortaleza Africa/Nouakchott America/Matamoros Pacific/Galapagos
America/Guatemala Pacific/Kwajalein Pacific/Marquesas America/Guayaquil
Asia/Kuala_Lumpur Europe/San_Marino America/Monterrey Europe/Simferopol
America/Araguaina Antarctica/Vostok Europe/Copenhagen America/Catamarca
Pacific/Pago_Pago America/Sao_Paulo America/Boa_Vista America/St_Thomas
Chile/Continental America/Vancouver Africa/Casablanca Europe/Bratislava
Pacific/Enderbury Pacific/Rarotonga Europe/Zaporozhye US/Indiana-Starke
Antarctica/Palmer Asia/Novokuznetsk Africa/Libreville America/Chihuahua
America/Anchorage Pacific/Tongatapu Antarctica/Mawson Africa/Porto-Novo
Asia/Yekaterinburg America/Paramaribo America/Hermosillo Atlantic/Jan_Mayen
Antarctica/McMurdo America/Costa_Rica Antarctica/Rothera America/Grand_Turk
Atlantic/Reykjavik Atlantic/St_Helena Australia/Victoria Chile/EasterIsland
Asia/Ujung_Pandang Australia/Adelaide America/Montserrat America/Porto_Acre
Africa/Brazzaville Australia/Brisbane America/Kralendijk America/Montevideo
America/St_Vincent America/Louisville Australia/Canberra Australia/Tasmania
Europe/Isle_of_Man Europe/Kaliningrad Africa/Ouagadougou America/Rio_Branco
Pacific/Kiritimati Africa/Addis_Ababa America/Metlakatla America/Martinique
Asia/Srednekolymsk America/Guadeloupe America/Fort_Wayne Australia/Lindeman
America/Whitehorse Arctic/Longyearbyen America/Pangnirtung America/Mexico_City
America/Los_Angeles America/Rainy_River Atlantic/Cape_Verde Pacific/Guadalcanal
Indian/Antananarivo America/El_Salvador Australia/Lord_Howe Africa/Johannesburg
America/Tegucigalpa Canada/Saskatchewan America/Thunder_Bay Canada/Newfoundland
America/Puerto_Rico America/Yellowknife Australia/Melbourne America/Porto_Velho
Australia/Queensland Australia/Yancowinna America/Santa_Isabel
America/Blanc-Sablon America/Scoresbysund America/Danmarkshavn
Pacific/Port_Moresby Antarctica/Macquarie America/Buenos_Aires
Africa/Dar_es_Salaam America/Campo_Grande America/Dawson_Creek
America/Indianapolis Pacific/Bougainville America/Rankin_Inlet
America/Indiana/Knox America/Lower_Princes America/Coral_Harbour
America/St_Barthelemy Australia/Broken_Hill America/Cambridge_Bay
America/Indiana/Vevay America/Swift_Current America/Port_of_Spain
Antarctica/South_Pole America/Santo_Domingo Atlantic/South_Georgia
America/Port-au-Prince America/Bahia_Banderas America/Indiana/Winamac
America/Indiana/Marengo America/Argentina/Jujuy America/Argentina/Salta
Canada/East-Saskatchewan America/Indiana/Vincennes America/Argentina/Tucuman
America/Argentina/Ushuaia Antarctica/DumontDUrville America/Indiana/Tell_City
America/Argentina/Mendoza America/Argentina/Cordoba America/Indiana/Petersburg
America/Argentina/San_Luis America/Argentina/San_Juan America/Argentina/La_Rioja
America/North_Dakota/Center America/Kentucky/Monticello
America/North_Dakota/Beulah America/Kentucky/Louisville
America/Argentina/Catamarca America/Indiana/Indianapolis
America/North_Dakota/New_Salem America/Argentina/Rio_Gallegos
America/Argentina/Buenos_Aires America/Argentina/ComodRivadavia
]
TIMEZONEs = TIMEZONES.collect(&:downcase)

##
## http://en.wikipedia.org/wiki/List_of_time_zone_abbreviations
#
#ABBREVIATIONS = %w[
#ACDT ACST ACT ADT AEDT AEST AFT AKDT AKST AMST AMST AMT AMT ART AST AST AWDT
#AWST AZOST AZT BDT BIOT BIT BOT BRT BST BST BTT CAT CCT CDT CDT CEDT CEST CET
#CHADT CHAST CHOT ChST CHUT CIST CIT CKT CLST CLT COST COT CST CST CST CST CST
#CT CVT CWST CXT DAVT DDUT DFT EASST EAST EAT ECT ECT EDT EEDT EEST EET EGST EGT
#EIT EST EST FET FJT FKST FKST FKT FNT GALT GAMT GET GFT GILT GIT GMT GST GST
#GYT HADT HAEC HAST HKT HMT HOVT HST ICT IDT IOT IRDT IRKT IRST IST IST IST JST
#KGT KOST KRAT KST LHST LHST LINT MAGT MART MAWT MDT MET MEST MHT MIST MIT MMT
#MSK MST MST MST MUT MVT MYT NCT NDT NFT NPT NST NT NUT NZDT NZST OMST ORAT PDT
#PET PETT PGT PHOT PKT PMDT PMST PONT PST PST PYST PYT RET ROTT SAKT SAMT SAST
#SBT SCT SGT SLST SRET SRT SST SST SYOT TAHT THA TFT TJT TKT TLT TMT TOT TVT UCT
#ULAT USZ1 UTC UYST UYT UZT VET VLAT VOLT VOST VUT WAKT WAST WAT WEDT WEST WET
#WIT WST YAKT YEKT Z
#].uniq

end

