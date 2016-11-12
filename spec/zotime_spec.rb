
#
# Specifying rufus-scheduler
#
# Wed Mar 11 21:17:36 JST 2015, quatre ans...
#

require 'spec_helper'


describe Rufus::Scheduler::ZoTime do

  describe '.new' do

    it 'accepts an integer' do

      zt = Rufus::Scheduler::ZoTime.new(1234567890, 'America/Los_Angeles')

      expect(zt.seconds.to_i).to eq(1234567890)
    end

    it 'accepts a float' do

      zt = Rufus::Scheduler::ZoTime.new(1234567890.1234, 'America/Los_Angeles')

      expect(zt.seconds.to_i).to eq(1234567890)
    end

    it 'accepts a Time instance' do

      zt =
        Rufus::Scheduler::ZoTime.new(
          Time.utc(2007, 11, 1, 15, 25, 0),
          'America/Los_Angeles')

      expect(zt.seconds.to_i).to eq(1193930700)
    end
  end

  #it "flips burgers" do
  #  puts "---"
  #  t0 = ltz('America/New_York', 2004, 10, 31, 0, 30, 0)
  #  t1 = ltz('America/New_York', 2004, 10, 31, 1, 30, 0)
  #  p t0
  #  p t1
  #  puts "---"
  #  zt0 = Rufus::Scheduler::ZoTime.new(t0, 'America/New_York')
  #  zt1 = Rufus::Scheduler::ZoTime.new(t1, 'America/New_York')
  #  p zt0.time
  #  p zt1.time
  #  puts "---"
  #  zt0.add(3600)
  #  p [ zt0.time, zt0.time.zone ]
  #  p [ zt1.time, zt1.time.zone ]
  #  #puts "---"
  #  #zt0.add(3600)
  #  #zt1.add(3600)
  #  #p [ zt0.time, zt0.time.zone ]
  #  #p [ zt1.time, zt1.time.zone ]
  #end

  describe '#time' do

    it 'returns a Time instance in with the right offset' do

      zt = Rufus::Scheduler::ZoTime.new(1193898300, 'America/Los_Angeles')
      t = zt.time

      expect(t.strftime('%Y/%m/%d %H:%M:%S %Z')
        ).to eq('2007/10/31 23:25:00 PDT')
    end

    # New York      EST: UTC-5
    # summer (dst)  EDT: UTC-4

    it 'chooses the DST time when there is ambiguity' do

      t = ltz('America/New_York', 2004, 10, 31, 0, 30, 0)
      zt = Rufus::Scheduler::ZoTime.new(t, 'America/New_York')
      zt.add(3600)
      ztt = zt.time

      expect(ztt.to_i).to eq(1099204200 - 3600)

      expect(ztt.strftime('%Y/%m/%d %H:%M:%S %Z %z %:z %::z')
        ).to eq('2004/10/31 01:30:00 EDT -0400 -04:00 -04:00:00')
    end
  end

  describe '#utc' do

    it 'returns an UTC Time instance' do

      zt = Rufus::Scheduler::ZoTime.new(1193898300, 'America/Los_Angeles')
      t = zt.utc

      expect(t.to_i).to eq(1193898300)

      if ruby18?
        expect(t.strftime('%Y/%m/%d %H:%M:%S %Z %z')
          ).to eq('2007/11/01 06:25:00 GMT +0000')
      else
        expect(t.strftime('%Y/%m/%d %H:%M:%S %Z %z')
          ).to eq('2007/11/01 06:25:00 UTC +0000')
      end
    end
  end

  describe '#add' do

    it 'adds seconds' do

      zt = Rufus::Scheduler::ZoTime.new(1193898300, 'Europe/Paris')
      zt.add(111)

      expect(zt.seconds).to eq(1193898300 + 111)
    end

    it 'goes into DST' do

      zt =
        Rufus::Scheduler::ZoTime.new(
          Time.gm(2015, 3, 8, 9, 59, 59),
          'America/Los_Angeles')

      t0 = zt.time
      zt.add(1)
      t1 = zt.time

      st0 = t0.strftime('%Y/%m/%d %H:%M:%S %Z') + " #{t0.isdst}"
      st1 = t1.strftime('%Y/%m/%d %H:%M:%S %Z') + " #{t1.isdst}"

      expect(t0.to_i).to eq(1425808799)
      expect(t1.to_i).to eq(1425808800)
      expect(st0).to eq('2015/03/08 01:59:59 PST false')
      expect(st1).to eq('2015/03/08 03:00:00 PDT true')
    end

    it 'goes out of DST' do

      zt =
        Rufus::Scheduler::ZoTime.new(
          ltz('Europe/Berlin', 2014, 10, 26, 01, 59, 59),
          'Europe/Berlin')

      t0 = zt.time
      zt.add(1)
      t1 = zt.time
      zt.add(3600)
      t2 = zt.time
      zt.add(1)
      t3 = zt.time

      st0 = t0.strftime('%Y/%m/%d %H:%M:%S %Z') + " #{t0.isdst}"
      st1 = t1.strftime('%Y/%m/%d %H:%M:%S %Z') + " #{t1.isdst}"
      st2 = t2.strftime('%Y/%m/%d %H:%M:%S %Z') + " #{t2.isdst}"
      st3 = t3.strftime('%Y/%m/%d %H:%M:%S %Z') + " #{t3.isdst}"

      expect(t0.to_i).to eq(1414281599)
      expect(t1.to_i).to eq(1414285200 - 3600)
      expect(t2.to_i).to eq(1414285200)
      expect(t3.to_i).to eq(1414285201)

      expect(st0).to eq('2014/10/26 01:59:59 CEST true')
      expect(st1).to eq('2014/10/26 02:00:00 CEST true')
      expect(st2).to eq('2014/10/26 02:00:00 CET false')
      expect(st3).to eq('2014/10/26 02:00:01 CET false')

      expect(t1 - t0).to eq(1)
      expect(t2 - t1).to eq(3600)
      expect(t3 - t2).to eq(1)
    end
  end

  describe '#to_f' do

    it 'returns the @seconds' do

      zt = Rufus::Scheduler::ZoTime.new(1193898300, 'Europe/Paris')

      expect(zt.to_f).to eq(1193898300)
    end
  end

#  describe '.envtzable?' do
#
#    def etza?(s); Rufus::Scheduler::ZoTime.envtzable?(s); end
#
#    it 'matches' do
#
#      expect(etza?('Asia/Tokyo')).to eq(true)
#      expect(etza?('America/Los_Angeles')).to eq(true)
#      expect(etza?('Europe/Paris')).to eq(true)
#      expect(etza?('UTC')).to eq(true)
#
#      expect(etza?('Japan')).to eq(true)
#      expect(etza?('Turkey')).to eq(true)
#    end
#
#    it 'does not match' do
#
#      expect(etza?('14:00')).to eq(false)
#      expect(etza?('14:00:14')).to eq(false)
#      expect(etza?('2014/12/11')).to eq(false)
#      expect(etza?('2014-12-11')).to eq(false)
#      expect(etza?('+25:00')).to eq(false)
#
#      expect(etza?('+09:00')).to eq(false)
#      expect(etza?('-01:30')).to eq(false)
#      expect(etza?('-0200')).to eq(false)
#
#      expect(etza?('Wed')).to eq(false)
#      expect(etza?('Sun')).to eq(false)
#      expect(etza?('Nov')).to eq(false)
#
#      expect(etza?('PST')).to eq(false)
#      expect(etza?('Z')).to eq(false)
#
#      expect(etza?('YTC')).to eq(false)
#      expect(etza?('Asia/Paris')).to eq(false)
#      expect(etza?('Nada/Nada')).to eq(false)
#    end
#
#    #it 'returns true for all entries in the tzinfo list' do
#    #  File.readlines(
#    #    File.join(File.dirname(__FILE__), '../misc/tz_all.txt')
#    #  ).each do |tz|
#    #    tz = tz.strip
#    #    if tz.length > 0 && tz.match(/^[^#]/)
#    #      p tz
#    #      expect(llat?(tz)).to eq(true)
#    #    end
#    #  end
#    #end
#  end

  describe '.is_timezone?' do

    def is_timezone?(o); Rufus::Scheduler::ZoTime.is_timezone?(o); end

    it 'returns true when passed a string describing a timezone' do
    end

    it 'returns false when it cannot make sense of the timezone' do
    end

    #it 'returns true for all entries in the tzinfo list' do
    #  File.readlines(
    #    File.join(File.dirname(__FILE__), '../misc/tz_all.txt')
    #  ).each do |tz|
    #    tz = tz.strip
    #    if tz.length > 0 && tz.match(/^[^#]/)
    #      #p tz
    #      expect(is_timezone?(tz)).to eq(true)
    #    end
    #  end
    #end
  end

  describe '.parse' do

    it 'parses a time string without a timezone' do

      zt =
        in_zone('Europe/Moscow') {
          Rufus::Scheduler::ZoTime.parse('2015/03/08 01:59:59')
        }

      t = zt.time
      u = zt.utc

      expect(t.to_i).to eq(1425769199)
      expect(u.to_i).to eq(1425769199)

      expect(t.strftime('%Y/%m/%d %H:%M:%S %Z %z') + " #{t.isdst}"
        ).to eq('2015/03/08 01:59:59 MSK +0300 false')

      if ruby18?
        expect(u.strftime('%Y/%m/%d %H:%M:%S %Z %z') + " #{u.isdst}"
          ).to eq('2015/03/07 22:59:59 GMT +0000 false')
      else
        expect(u.strftime('%Y/%m/%d %H:%M:%S %Z %z') + " #{u.isdst}"
          ).to eq('2015/03/07 22:59:59 UTC +0000 false')
      end
    end

    it 'parses a time string with a full name timezone' do

      zt =
        Rufus::Scheduler::ZoTime.parse(
          '2015/03/08 01:59:59 America/Los_Angeles')

      t = zt.time
      u = zt.utc

      expect(t.to_i).to eq(1425808799)
      expect(u.to_i).to eq(1425808799)

      expect(t.strftime('%Y/%m/%d %H:%M:%S %Z %z') + " #{t.isdst}"
        ).to eq('2015/03/08 01:59:59 PST -0800 false')

      if ruby18?
        expect(u.strftime('%Y/%m/%d %H:%M:%S %Z %z') + " #{u.isdst}"
          ).to eq('2015/03/08 09:59:59 GMT +0000 false')
      else
        expect(u.strftime('%Y/%m/%d %H:%M:%S %Z %z') + " #{u.isdst}"
          ).to eq('2015/03/08 09:59:59 UTC +0000 false')
      end
    end

    it 'parses a time string with a delta timezone' do

      zt =
        in_zone('Europe/Berlin') {
          Rufus::Scheduler::ZoTime.parse('2015-12-13 12:30 -0200')
        }

      t = zt.time
      u = zt.utc

      expect(t.to_i).to eq(1450017000)
      expect(u.to_i).to eq(1450017000)

      expect(t.strftime('%Y/%m/%d %H:%M:%S %Z %z') + " #{t.isdst}"
        ).to eq('2015/12/13 15:30:00 CET +0100 false')

      if ruby18?
        expect(u.strftime('%Y/%m/%d %H:%M:%S %Z %z') + " #{u.isdst}"
          ).to eq('2015/12/13 14:30:00 GMT +0000 false')
      else
        expect(u.strftime('%Y/%m/%d %H:%M:%S %Z %z') + " #{u.isdst}"
          ).to eq('2015/12/13 14:30:00 UTC +0000 false')
      end
    end

    it 'parses a time string with a delta (:) timezone' do

      zt =
        in_zone('Europe/Berlin') {
          Rufus::Scheduler::ZoTime.parse('2015-12-13 12:30 -02:00')
        }

      t = zt.time
      u = zt.utc

      expect(t.to_i).to eq(1450017000)
      expect(u.to_i).to eq(1450017000)

      expect(t.strftime('%Y/%m/%d %H:%M:%S %Z %z') + " #{t.isdst}"
        ).to eq('2015/12/13 15:30:00 CET +0100 false')

      if ruby18?
        expect(u.strftime('%Y/%m/%d %H:%M:%S %Z %z') + " #{u.isdst}"
          ).to eq('2015/12/13 14:30:00 GMT +0000 false')
      else
        expect(u.strftime('%Y/%m/%d %H:%M:%S %Z %z') + " #{u.isdst}"
          ).to eq('2015/12/13 14:30:00 UTC +0000 false')
      end
    end

    it 'takes the local TZ when it does not know the timezone' do

      in_zone 'Europe/Moscow' do

        zt = Rufus::Scheduler::ZoTime.parse('2015/03/08 01:59:59 Nada/Nada')

        expect(zt.time.zone.name).to eq('Europe/Moscow')
      end
    end
  end

  describe '.get_tzone' do

    def gtz(s); z = Rufus::Scheduler::ZoTime.get_tzone(s); z ? z.name : z; end

    it 'returns a tzone for all the know zone strings' do

      expect(gtz('GB')).to eq('GB')
      expect(gtz('UTC')).to eq('UTC')
      expect(gtz('GMT')).to eq('GMT')
      expect(gtz('Zulu')).to eq('Zulu')
      expect(gtz('Japan')).to eq('Japan')
      expect(gtz('Turkey')).to eq('Turkey')
      expect(gtz('Asia/Tokyo')).to eq('Asia/Tokyo')
      expect(gtz('Europe/Paris')).to eq('Europe/Paris')
      expect(gtz('Europe/Zurich')).to eq('Europe/Zurich')
      expect(gtz('W-SU')).to eq('W-SU')

      expect(gtz('PST')).to eq('America/Dawson')
      expect(gtz('CEST')).to eq('Africa/Ceuta')

      expect(gtz('Z')).to eq('Zulu')

      expect(gtz('+09:00')).to eq('+09:00')
      expect(gtz('-01:30')).to eq('-01:30')

      expect(gtz('+08:00')).to eq('+08:00')
      expect(gtz('+0800')).to eq('+0800') # no normalization to "+08:00"
    end

    it 'returns nil for unknown zone names' do

      expect(gtz('Asia/Paris')).to eq(nil)
      expect(gtz('Nada/Nada')).to eq(nil)
      expect(gtz('7')).to eq(nil)
      expect(gtz('06')).to eq(nil)
      expect(gtz('sun#3')).to eq(nil)
      expect(gtz('Mazda Zoom Zoom Stadium')).to eq(nil)
    end
  end
end

#      %w[
#GB NZ UCT EET CET PRC ROC WET GMT EST ROK UTC MST HST MET Zulu Cuba Iran W-SU
#Eire GMT0 Libya Japan Egypt GMT+0 GMT-0 Israel Poland Navajo Turkey GB-Eire
#Iceland PST8PDT Etc/UCT CST6CDT NZ-CHAT MST7MDT Jamaica EST5EDT Etc/GMT Etc/UTC
#US/Samoa Etc/GMT0 Portugal Hongkong Etc/Zulu Singapore Asia/Baku Etc/GMT-9
#Etc/GMT+1 Etc/GMT+0 Asia/Aden Etc/GMT+2 Etc/GMT+3 Etc/GMT+4 Etc/GMT+5 Etc/GMT+6
#Etc/GMT+7 Etc/GMT+8 Etc/GMT+9 Etc/GMT-0 Etc/GMT-1 Universal Asia/Dili Greenwich
#Asia/Gaza Etc/GMT-8 Etc/GMT-7 US/Alaska Asia/Oral Etc/GMT-6 Etc/GMT-5 Etc/GMT-4
#Asia/Hovd Etc/GMT-3 US/Hawaii Etc/GMT-2 Kwajalein Asia/Omsk Asia/Macao
#Etc/GMT-14 Asia/Kabul US/Central Etc/GMT-13 US/Arizona Asia/Macau Asia/Qatar
#Asia/Seoul Asia/Tokyo Asia/Dubai US/Pacific Etc/GMT-12 Etc/GMT-11 Etc/GMT-10
#Asia/Dhaka Asia/Dacca Asia/Chita Etc/GMT+12 Etc/GMT+10 Asia/Amman Asia/Aqtau
#Etc/GMT+11 US/Eastern Asia/Thimbu Asia/Brunei Asia/Tehran Asia/Beirut
#Europe/Rome Europe/Riga Brazil/Acre Brazil/East Europe/Oslo Brazil/West
#Africa/Lome Asia/Taipei Asia/Saigon Asia/Riyadh Asia/Aqtobe Asia/Anadyr
#Europe/Kiev Asia/Almaty Africa/Juba Pacific/Yap US/Aleutian Asia/Muscat
#US/Mountain Asia/Harbin Asia/Hebron Asia/Manila Asia/Kuwait Asia/Urumqi
#US/Michigan Indian/Mahe SystemV/EST5 Asia/Kashgar Indian/Cocos Asia/Jakarta
#Asia/Kolkata Asia/Kuching America/Atka Asia/Irkutsk Pacific/Apia Asia/Magadan
#Africa/Dakar America/Lima Pacific/Fiji Pacific/Guam Europe/Vaduz Pacific/Niue
#Asia/Nicosia Africa/Ceuta Pacific/Truk America/Adak Pacific/Wake Africa/Tunis
#Africa/Cairo Asia/Colombo SystemV/AST4 SystemV/CST6 Asia/Karachi Asia/Rangoon
#SystemV/MST7 Asia/Baghdad Europe/Malta Africa/Lagos Europe/Minsk SystemV/PST8
#Canada/Yukon Asia/Tbilisi America/Nome Asia/Bahrain Africa/Accra Europe/Paris
#Asia/Bangkok Asia/Bishkek Asia/Thimphu SystemV/YST9 Asia/Yerevan Asia/Yakutsk
#Europe/Sofia Asia/Ust-Nera Australia/ACT Australia/LHI Europe/Tirane
#Asia/Tel_Aviv Australia/NSW Africa/Luanda Asia/Tashkent Africa/Lusaka
#Asia/Shanghai Africa/Malabo Asia/Sakhalin Africa/Maputo Africa/Maseru
#SystemV/HST10 Africa/Kigali Africa/Niamey Pacific/Samoa America/Sitka
#Pacific/Palau Pacific/Nauru Pacific/Efate Asia/Makassar Pacific/Chuuk
#Africa/Harare Africa/Douala America/Aruba America/Thule America/Bahia
#America/Jujuy America/Belem Asia/Katmandu America/Boise Indian/Comoro
#Indian/Chagos Asia/Jayapura Europe/Zurich Asia/Istanbul Europe/Zagreb
#Etc/Greenwich Europe/Warsaw Europe/Vienna Etc/Universal Asia/Dushanbe
#Europe/Athens Europe/Berlin Africa/Bissau Asia/Damascus Africa/Banjul
#Europe/Dublin Africa/Bangui Africa/Bamako Europe/Jersey Africa/Asmera
#Europe/Lisbon Africa/Asmara Europe/London Asia/Ashgabat Asia/Calcutta
#Europe/Madrid Europe/Monaco Europe/Moscow Europe/Prague Europe/Samara
#Europe/Skopje Asia/Khandyga Canada/Pacific Africa/Abidjan America/Manaus
#Asia/Chongqing Asia/Chungking Africa/Algiers America/Maceio US/Pacific-New
#Africa/Conakry America/La_Paz America/Juneau America/Nassau America/Inuvik
#Europe/Andorra Africa/Kampala Asia/Ashkhabad Asia/Hong_Kong America/Havana
#Canada/Eastern Europe/Belfast Canada/Central Australia/West Asia/Jerusalem
#Africa/Mbabane Asia/Kamchatka America/Virgin America/Guyana Asia/Kathmandu
#Mexico/General America/Panama Europe/Nicosia America/Denver Europe/Tallinn
#Africa/Nairobi America/Dawson Europe/Vatican Europe/Vilnius America/Cuiaba
#Africa/Tripoli Pacific/Wallis Atlantic/Faroe Pacific/Tarawa Pacific/Tahiti
#Pacific/Saipan Pacific/Ponape America/Cayman America/Cancun Asia/Pontianak
#Asia/Pyongyang Asia/Vientiane Asia/Qyzylorda Pacific/Noumea America/Bogota
#Pacific/Midway Pacific/Majuro Asia/Samarkand Indian/Mayotte Pacific/Kosrae
#Asia/Singapore Indian/Reunion America/Belize America/Regina America/Recife
#Pacific/Easter Mexico/BajaSur America/Merida Pacific/Chatham Pacific/Fakaofo
#Pacific/Gambier America/Rosario Asia/Ulan_Bator Indian/Maldives Pacific/Norfolk
#America/Antigua Asia/Phnom_Penh America/Phoenix America/Caracas America/Cayenne
#Atlantic/Azores Pacific/Pohnpei Atlantic/Canary America/Chicago Atlantic/Faeroe
#Africa/Windhoek America/Cordoba America/Creston Africa/Timbuktu America/Curacao
#Africa/Sao_Tome Africa/Ndjamena SystemV/AST4ADT Europe/Uzhgorod Europe/Tiraspol
#SystemV/CST6CDT Africa/Monrovia America/Detroit Europe/Sarajevo Australia/Eucla
#America/Tijuana America/Toronto America/Godthab America/Grenada Europe/Istanbul
#America/Ojinaga America/Tortola Australia/Perth Europe/Helsinki Australia/South
#Europe/Guernsey SystemV/EST5EDT Europe/Chisinau SystemV/MST7MDT Europe/Busingen
#Europe/Budapest Europe/Brussels America/Halifax America/Mendoza America/Noronha
#America/Nipigon Canada/Atlantic America/Yakutat SystemV/PST8PDT SystemV/YST9YDT
#Canada/Mountain Africa/Kinshasa Africa/Khartoum Africa/Gaborone Africa/Freetown
#America/Iqaluit America/Jamaica US/East-Indiana Africa/El_Aaiun America/Knox_IN
#Africa/Djibouti Africa/Blantyre America/Moncton America/Managua Asia/Choibalsan
#America/Marigot Australia/North Europe/Belgrade America/Resolute
#America/Mazatlan Pacific/Funafuti Pacific/Auckland Pacific/Honolulu
#Pacific/Johnston America/Miquelon America/Santarem Mexico/BajaNorte
#America/Santiago Antarctica/Troll America/Asuncion America/Atikokan
#America/Montreal America/Barbados Africa/Bujumbura Pacific/Pitcairn
#Asia/Ulaanbaatar Indian/Mauritius America/New_York Antarctica/Syowa
#America/Shiprock Indian/Kerguelen Asia/Novosibirsk America/Anguilla
#Indian/Christmas Asia/Vladivostok Asia/Ho_Chi_Minh Antarctica/Davis
#Atlantic/Bermuda Europe/Amsterdam Antarctica/Casey America/St_Johns
#Atlantic/Madeira America/Winnipeg America/St_Kitts Europe/Volgograd
#Brazil/DeNoronha Europe/Bucharest Africa/Mogadishu America/St_Lucia
#Atlantic/Stanley Europe/Stockholm Australia/Currie Europe/Gibraltar
#Australia/Sydney Asia/Krasnoyarsk Australia/Darwin America/Dominica
#America/Edmonton America/Eirunepe Europe/Podgorica America/Ensenada
#Europe/Ljubljana Australia/Hobart Europe/Mariehamn Africa/Lubumbashi
#America/Goose_Bay Europe/Luxembourg America/Menominee America/Glace_Bay
#America/Fortaleza Africa/Nouakchott America/Matamoros Pacific/Galapagos
#America/Guatemala Pacific/Kwajalein Pacific/Marquesas America/Guayaquil
#Asia/Kuala_Lumpur Europe/San_Marino America/Monterrey Europe/Simferopol
#America/Araguaina Antarctica/Vostok Europe/Copenhagen America/Catamarca
#Pacific/Pago_Pago America/Sao_Paulo America/Boa_Vista America/St_Thomas
#Chile/Continental America/Vancouver Africa/Casablanca Europe/Bratislava
#Pacific/Enderbury Pacific/Rarotonga Europe/Zaporozhye US/Indiana-Starke
#Antarctica/Palmer Asia/Novokuznetsk Africa/Libreville America/Chihuahua
#America/Anchorage Pacific/Tongatapu Antarctica/Mawson Africa/Porto-Novo
#Asia/Yekaterinburg America/Paramaribo America/Hermosillo Atlantic/Jan_Mayen
#Antarctica/McMurdo America/Costa_Rica Antarctica/Rothera America/Grand_Turk
#Atlantic/Reykjavik Atlantic/St_Helena Australia/Victoria Chile/EasterIsland
#Asia/Ujung_Pandang Australia/Adelaide America/Montserrat America/Porto_Acre
#Africa/Brazzaville Australia/Brisbane America/Kralendijk America/Montevideo
#America/St_Vincent America/Louisville Australia/Canberra Australia/Tasmania
#Europe/Isle_of_Man Europe/Kaliningrad Africa/Ouagadougou America/Rio_Branco
#Pacific/Kiritimati Africa/Addis_Ababa America/Metlakatla America/Martinique
#Asia/Srednekolymsk America/Guadeloupe America/Fort_Wayne Australia/Lindeman
#America/Whitehorse Arctic/Longyearbyen America/Pangnirtung America/Mexico_City
#America/Los_Angeles America/Rainy_River Atlantic/Cape_Verde Pacific/Guadalcanal
#Indian/Antananarivo America/El_Salvador Australia/Lord_Howe Africa/Johannesburg
#America/Tegucigalpa Canada/Saskatchewan America/Thunder_Bay Canada/Newfoundland
#America/Puerto_Rico America/Yellowknife Australia/Melbourne America/Porto_Velho
#Australia/Queensland Australia/Yancowinna America/Santa_Isabel
#America/Blanc-Sablon America/Scoresbysund America/Danmarkshavn
#Pacific/Port_Moresby Antarctica/Macquarie America/Buenos_Aires
#Africa/Dar_es_Salaam America/Campo_Grande America/Dawson_Creek
#America/Indianapolis Pacific/Bougainville America/Rankin_Inlet
#America/Indiana/Knox America/Lower_Princes America/Coral_Harbour
#America/St_Barthelemy Australia/Broken_Hill America/Cambridge_Bay
#America/Indiana/Vevay America/Swift_Current America/Port_of_Spain
#Antarctica/South_Pole America/Santo_Domingo Atlantic/South_Georgia
#America/Port-au-Prince America/Bahia_Banderas America/Indiana/Winamac
#America/Indiana/Marengo America/Argentina/Jujuy America/Argentina/Salta
#Canada/East-Saskatchewan America/Indiana/Vincennes America/Argentina/Tucuman
#America/Argentina/Ushuaia Antarctica/DumontDUrville America/Indiana/Tell_City
#America/Argentina/Mendoza America/Argentina/Cordoba America/Indiana/Petersburg
#America/Argentina/San_Luis America/Argentina/San_Juan America/Argentina/La_Rioja
#America/North_Dakota/Center America/Kentucky/Monticello
#America/North_Dakota/Beulah America/Kentucky/Louisville
#America/Argentina/Catamarca America/Indiana/Indianapolis
#America/North_Dakota/New_Salem America/Argentina/Rio_Gallegos
#America/Argentina/Buenos_Aires America/Argentina/ComodRivadavia
#      ]

