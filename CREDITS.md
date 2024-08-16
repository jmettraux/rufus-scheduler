
# CREDITS.md


## Contributors

* Geremia Taglialatela, https://github.com/tagliala, mfa opt-in gh-347
* Austin Arbor https://github.com/austinarbor gh-342 first_at_error
* Bence Monus https://github.com/cromega gh-337 on_error and friends
* Talia Wong https://github.com/blowfishpro gh-335 on_error and friends
* Konstantin https://github.com/fa11enangel gh-334 nodejitsu link
* Olle Jonsson https://github.com/olleolleolle gh-333
* Sol Ackerman https://github.com/solarckerman gh-332
* John Bachir https://github.com/jjb gh-310 gh-327
* Daniel Berger https://github.com/djberg96 gh-300
* Ceyhun Onur https://github.com/ceyonur parse_cron no_error: true
* Darwin Wu https://github.com/dwaxe Rails initializer vs tests change
* Mike Karolow https://github.com/mike-yesware update Travis target Rubies
* Jack-Nie https://github.com/jack-nie gh-285 fix broken comment link
* Yechiel Kalmenson (https://github.com/achasveachas) README link fix
* Alex Coomans (https://github.com/drcapulet) gh-276 freq check pref improvement
* Vais Salikhov (https://github.com/vais) many document clarifications
* Wes McNamee (https://github.com/ghostsquad) let #schedule accept a CronLine
* Joe Rafaniello (https://github.com/jrafanie) Travis Ruby 2.4.1
* Benjamin Fleischer (https://github.com/bf4) ZoTime#subtract
* Sam Rowe (https://github.com/riddley) gh-240 timezone for Debian
* Daniel Rodgers-Pryor (https://github.com/djrodgerspryor), gh-238 fix ZooKeeper example
* Cody Cutrer (https://github.com/ccutrer) gh-232 is_a?(Fixnum) replacement
* Dominik Sander (https://github.com/dsander), gh-225, gh-226
* Piavka (https://github.com/piavka) Job#trigger_off_schedule, gh-214
* Paulo Delgado (https://github.com/paulodelgado) counter ActiveRecord, gh-210
* Anjali Sharma (https://github.com/anjali-sharma) enhance job#last_time example
* Kyle Simukka (https://github.com/simook) raise on `"*/0 * * * *"`
* Ryan McGeary (https://github.com/rmm5t) svg badges for the readme
* Balasankar C (https://github.com/balasankarc) fix CronJob spec vs December
* Matthieu Rosinski (https://github.com/Korrigan) prevent "every" shifts
* vivitar (https://github.com/vivitar) silenced a set of Ruby warnings
* Jon McPherson (https://github.com/JonMcPherson) `:first_in => 0` back
* Calinoiu Alexandru Nicolae (https://github.com/alexandru-calinoiu) CronLine#prev_second fix
* Alyssa Pohahau (https://github.com/alyssa) out of DST transition specs
* Claude Vessaz (https://github.com/claudeatsafe) ack #unscheduled_at in #scheduled?
* 김성식 (https://github.com/kssminus) job id uniqueness effort
* Jesse Willet (https://github.com/jhw-at-prosperworks-com) cron vs `"*/10"`
* Pascal Ouellet (https://github.com/pouellet) Scheduler#timeline loop fix
* Ryan Biesemeyer (https://github.com/yaauie) ZoTime.is_timezone? on OSX
* Ketan Padegaonkar (https://github.com/ketan) .brute_frequency improvement
* Gabriel Gilder (https://github.com/ggilder) LA DST specs
* Sterling Paramore (https://github.com/gnilrets) underscore TZ fix
* ecin (https://github.com/ecin) new lock mecha
* Adam Jonas (https://github.com/adamjonas) migrate specs to "expect"
* Yassen Bantchev (https://github.com/yassenb) CronLine#previous_time rewrite
* Eric Lindvall (https://github.com/eric) Zookeeper locked example
* Ted Pennings (https://github.com/tedpennings) typo in post_install_message
* Tobias Kraze (https://github.com/kratob) timeout vs mutex fix
* Patrick Farrell (https://github.com/pfarrell) pointing at deprecated start_new
* Thomas Sevestre (https://github.com/thomassevestre) :exception option
* Matteo Cerutti - last_time / previous_time idea (and initial implementation)
* Aimee Rose (https://github.com/AimeeRose) cronline and &gt; 24
* Lucy Fu (https://github.com/lfu) arg error on `<= 0 "every" freq`
* Rainux Luo (https://github.com/rainux) multiple mutexes
* Andrew Davey (https://github.com/asdavey) "L" in cron lines
* Stig Kleppe-Jørgensen (https://github.com/stigkj)
* Danny "northox" Fullerton (https://github.com/northox) negative time strings
* Marcus Brito (https://github.com/pazustep) CronLine proofing
* André Luis Leal Cardoso Junior (https://github.com/andrehjr) 1.9.3 patch
* Anthony Lewis (https://github.com/anthonylewis) cron lines and 09 issue
* concept47 (https://github.com/concept47) every and :discard_past
* Chris Kampemeier (https://github.com/chrisk) rspec 2.0 refinements
* Tanzeeb Khalili (https://github.com/tanzeeb) cron and timezones
* Adam Davies (https://github.com/adz) `:allow_overlapping => false`
* Klaas Jan Wierenga (https://github.com/kjwierenga) at/every/in stress tests (1.0 and 2.0)
* TobyH (https://github.com/tobyh) faster and cleaner `CronLine#next_time`


## Feedback

* jasonwbarnett (https://github.com/jaswonwbarnett) past time jobs, gh-339
* aphel (https://github.com/itsaphel) #shutdown vs current thread, gh-304
* aesyondu (https://github.com/aesyondu) Rails console 4.2.x, gh-186
* Sasha Hoellger (https://github.com/mitnal) parse_cron and readme, gh-270
* Gian (https://github.com/snmgian) cron vs :first clarification, gh-266
* Vito Laurenza (https://github.com/veetow) help debugging tz issues, gh-240
* Yoshimi Keiji (https://github.com/walf443) v.3.3.3 mislabelling
* Alexander Deeb (https://github.com/adeeb1) gh-230
* Sofia Bravo (http://stackoverflow.com/users/1123850/sofia-bravo) gh-231
* zzjin (https://github.com/zzjin) 3.3.x vs CST abbreviated timezone, gh-228
* lovingyu (https://github.com/lovingyu) fallback to `ENV['TZ']`, gh-222
* Ramon Tayag (https://github.com/ramontayag) prevent day 0 in cronlines
* Akinori Musha (https://github.com/knu) `ENV['TZ']` setting is harmful
* Nicolás Satragno (https://twitter.com/nsatragno) parse_to_time vs Date
* d-m-u duhlmann (https://github.com/d-m-u) job opt hash preservation
* Anjali Sharma (https://github.com/anjali-sharma) fix typographical error
* Jonathan Campos (https://github.com/jonbcampos) negative cron day idea
* Andrey Morskov (https://github.com/accessd) fix typographical error
* Eduardo Maia (https://github.com/emaiax) rufus and the Rails console
* Suisea (https://github.com/suisea) readme rewording
* Radek (http://stackoverflow.com/users/250422) gh-166
* Patrik Ragnarsson (https://github.com/dentarg) timeout vs nil, gh-156
* Adefila (https://twitter.com/adefilaedward1) typo in readme
* Michael Guymon (https://github.com/mguymon) #next_time vs :first_at
* junhanamaki (https://github.com/junhanamaki) #next_time and dst ambiguities
* kreynolds (tossrock) - inspiration for #occurrences
* Matteo (https://github.com/m4ce) dst and cron issue
* Tobias Bielohlawek (https://github.com/rngtng) missing assertion
* Joe Taylor and Agis Anastasopoulos (http://stackoverflow.com/questions/21280870) `:first => :now` and `Job#call`
* Gatis Tomsons (https://github.io/gacha) heavy work threads and lock errors
* Joast (https://github.com/joast) missing .to_time_string alias (code and doc)
* Tamir Duberstein (https://github.com/tamird) rdoc inaccuracies
* Kevin Bouwkamp (https://github.com/bmxpert1) first_at issues
* Daniel Beauchamp (https://github.com/pushmatrix) pre/post trigger callbacks
* Arthur Maltson (https://github.com/amaltson) readme fixes
* skrd (https://github.com/skrd) `"/10 * * * *"` cron issue
* Hongli Lai - `Scheduler#stop(:terminate => true)` request
* Tero Tilus - raises on unsupported/unknown options
* Louis Coilliot - Scheduler#running_jobs
* Henrique G. Testa - pause/resume concept
* Sam Gibson (https://github.com/samfoo) exception handling hardening
* sha1dy (https://github.com/sha1dy) every and overlapping exception issue
* Defusal - unschedule_by_tag
* pickerel (https://github.com/pickerel)
* Gonzalo Suarez - parse_time_string(s) issue
* Tony Day (https://github.com/tonyday) every and overlapping timeout issue
* Nate Wiger (Schedulable call/trigger issue)
* Aldric (readme errors)
* Kenneth Kalmer (daemon-kit)
* Chris Evans, :timeout tests on JRuby
* Tim Uckun, :timeout concept
* K Liu, for the note about CronLine#next_time
* Xianhang Zhang, find_jobs(tag=nil) patch
* Yi Wen, for lib/rufus-scheduler.rb
* Adam Green and Rael Dornfest for the Taskr breaking issue feedback
* Sean Liu, unschedule_every issue
* Manfred Usselman (no cronjobs on sundays bug)
* Michael Goth, tests with precision &gt; 1s

* many people gave feedback previously, see
  http://openwferu.rubyforge.org/svn/trunk/openwfe-ruby/CREDITS.txt (dead)


## and finally

* Many thanks to the contributors of fugit (https://github.com/floraison/fugit) and et-orbi (https://github.com/floraison/et-orbi)
* Many thanks to the author and contributors of the tzinfo gem (http://tzinfo.github.io/)
* Many thanks to the EventMachine team (especially Aman Gupta)

