#! ruby -Ku
# encoding: utf-8

require 'rubygems'
require 'mechanize'
require 'nkf'
require 'fileutils'
require 'date'
require 'common'


#定数定義

	TargetURL = "http://www.tv-asahi.co.jp/daimei_2017/contents/Broadcast/cur/"

#関数定義開始


def getSchedule()
	agent = Mechanize.new
	page = agent.get(TargetURL)
#	page = NKF.nkf('-wZ0', page)

	elem = Array.new
	elem.push(page.search('//*[@id="contentsarea"]/section[1]/div/h4[1]').inner_text)
	
	elem.push(page.search('//*[@id="contentsarea"]/section[1]/div/h3').inner_text)
	elem.push(page.search('//*[@id="contentsarea"]/section[1]/div/p[1]').inner_text)

	elem.push(page.search('//*[@id="contentsarea"]/section[2]/div/h4[1]').inner_text)
	elem.push(page.search('//*[@id="contentsarea"]/section[2]/div/span[1]').inner_text)
	elem.push(page.search('//*[@id="contentsarea"]/section[2]/div/p[1]').inner_text)

	elem.push(page.search('//*[@id="contentsarea"]/section[2]/div/h4[2]').inner_text)
	elem.push(page.search('//*[@id="contentsarea"]/section[2]/div/span[2]').inner_text)
	elem.push(page.search('//*[@id="contentsarea"]/section[2]/div/p[2]').inner_text)

=begin
	elem.push(page.search('//*[@id="contentsarea"]/section[2]/div/h4[3]').inner_text)
	elem.push(page.search('//*[@id="contentsarea"]/section[2]/div/span[3]').inner_text)
	elem.push(page.search('//*[@id="contentsarea"]/section[2]/div/p[3]').inner_text)
=end
#	p elem
	
	makeICAL(elem)
		
rescue => ex
	p ex
else
end


def makeICAL(elem)

	filehdl = File.open(DATADIR + "ical/UntitledConcert.ics","w+")
	filehdl.puts <<-'EOS'
BEGIN:VCALENDAR
METHOD:PUBLISH
VERSION:2.0
PRODID:-//nyctea.me//Manually//JP
CALSCALE:GREGORIAN
X-WR-TIMEZONE:Asia/Tokyo
X-WR-CALNAME:題名のない音楽会 放送予定
	EOS
	filehdl.puts "X-WR-CALDESC:" + TargetURL + " \\n"
	filehdl.puts " 更新日時:" + TIMESTMP[0..3] + "/" + TIMESTMP[4..5] + "/" + TIMESTMP[6..7] + " " + TIMESTMP[8..9] + ":" + TIMESTMP[10..11] + ":" + TIMESTMP[12..13] + "\\n"

	filehdl.puts <<-'EOS'
BEGIN:VTIMEZONE
TZID:Japan
BEGIN:STANDARD
DTSTART:19390101T000000
TZOFFSETFROM:+0900
TZOFFSETTO:+0900
TZNAME:JST
END:STANDARD
END:VTIMEZONE
	EOS
	
	cnt = 0
	while true do
		break if !elem[cnt]
		filehdl.puts "BEGIN:VEVENT"
		filehdl.puts "UID:"
		filehdl.puts "DTSTAMP:" + TIMESTMP[0..7] + "T" + TIMESTMP[8..13]
		filehdl.puts "SUMMARY:「" + elem[cnt+1].gsub(/「|」/,"") + "」"
		filehdl.puts "DESCRIPTION:" + elem[cnt+2].gsub(/\r\n|\r|\n/,"") + " " + TargetURL
		filehdl.puts "DTSTART;TZID=Japan:" + elem[cnt].gsub(/\./,"") + "T100000;"
		filehdl.puts "DTEND;TZID=Japan:" + elem[cnt].gsub(/\./,"") + "T103000;"
		filehdl.puts "CLASS:PUBLIC"
		filehdl.puts "TRANSP:TRANSPARENT"
		filehdl.puts "STATUS:CONFIRMED"
		filehdl.puts "END:VEVENT"
		
		cnt += 3
	end
	filehdl.puts ("END:VCALENDAR")
	filehdl.close
	
	moveIcsForHost()

rescue => ex
	p ex
else
end

def moveIcsForHost()
	FileUtils.cp(DATADIR + "ical/UntitledConcert.ics", BKUPDIR + "ical/UntitledConcert.ics")
	FileUtils.cp(DATADIR + "ical/UntitledConcert.ics", WWWDIR + "icalendar/UntitledConcert.ics")
rescue => ex
	APPEND_LOGFILE("・ファイル移動異常終了")
	APPEND_LOGFILE(ex)
else
	PARCON_SQL.normal('UntitledConcert.ics', __FILE__.gsub(/^.*\//,'') )
	APPEND_LOGFILE("・ファイル移動正常終了")
end


getSchedule()
