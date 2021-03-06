#!/usr/bin/env ruby
require 'optparse'
require 'resolv'
require 'securerandom'

GreenTXT  = "\033[92m"   #Success
CyanTXT   = "\033[96m"   #INFO
YellowTXT = "\033[1;32m" #Others
RedTXT    = "\033[91m"   #ERROR
EndTXT    = "\033[00m"   #Reset color

# HELP #
def usage()
    puts '
  -s  	         Set SMTP/MX server (default "Autodetect with domain")
  -p  	         Set TCP Port (default "25/SMTP")
  -f             Set MAIL FROM (protocolar)
  -t  	         Set RCPT TO (protocolar)
--hfrom          Set Header From (ex "Me <ruby@lang.org>")
--hto            Set Header To (ex "You <ruby@gem.org>")
--subject        Set a subject
--date           Set a custom date (default "current date")
--body           Write content to Body
--attach         Add an attachment/file
--auth           Enable authentication (Gmail, Outlook...)
--x-mailer       Set a custom X-Mailer (default "SendMail-Ruby v1")
--x-priority     Set a custom X-Priority
--charset        Set a custom charset (default "UTF-8")
--html-file      Import a HTML file as body
--text-file      Import a TXT file as body
--boundary       Set a custom boundary (default "------=_MIME_BOUNDARY_RUBY_LANG--")
--content-type   Set a custom Content-Type (default "text/plain")
--encoding       Set an encoding (default "7bit")
--base64         Encode body in base64
--prompt         Get a prompt to write on your terminal
--save           Save email to an EML file
'
end

# FLAGS #
options = {}
OptionParser.new do |parser|
    #########
    # BASIC #
    #########
    parser.on("-s", "--smtp SMTP", "Set SMTP Server") do |optSmtpServ|
        $optSmtpServ = optSmtpServ
    end
    parser.on("-p", "--port PORT", "Set TCP port") do |port|
        $port = port
    end
    parser.on("-f", "--from MAILFROM", "Mail From address (MAIL FROM - Protocolar)") do |mailFrom|
        $mailFrom = mailFrom
    end
    parser.on("-t", "--to RCPT TO", "Recipient To address (RCPT TO - Protocolar)") do |rcptTo|
        $rcptTo = rcptTo
    end
    parser.on("--hfrom FROM", "Set Header From (From:") do |hFrom|
        $hFrom = hFrom
    end
    parser.on("--hto TO", "Set Header To (To:)") do |hTo|
        $hTo = hTo
    end
    parser.on("--subject SUBJECT", "Set a subject") do |subject|
        $subject = subject
    end
    parser.on("--date DATE", "Set a custom date") do |date|
        $date = date
    end
    parser.on("--body CONTENT", "Content in body") do |body|
        $body = body
    end
    parser.on("--attach FILE", "Add an attachment") do |attach|
        $attach = attach
    end
    #parser.on("--auth", "Enable authentication (Gmail/Outlook)") do |auth|
    #    $auth = auth
    #end
    parser.on("-h", "--help", "-help", "Display help") do |help|
        usage()
    end

    ################
    # MORE OPTIONS #
    ################
    parser.on("--x-mailer X-MAILER", "Set a custom X-Mailer") do |xmailer|
        $xmailer = xmailer
    end
    parser.on("--charset CHARSET", "Set a charset format") do |charset|
        $charset = charset
    end
    parser.on("--html-file FILE.html", "Import HTML file as Body") do |htmlFile|
        $htmlFile = htmlFile
    end
    parser.on("--text-file FILE.txt", "Import Text file as Body") do |textFile|
        $txtFile = textFile
    end
    parser.on("--x-priority NUM", "Set a custom X-Priority") do |xprio|
        $xprio = xprio
    end
    parser.on("--boundary BOUNDARY", "Set a custom Boundary") do |boundary|
        $boundary = boundary 
    end
    parser.on("--content-type CONTENT-TYPE", "Set a custom Content-Type") do |ctype|
        $ctype = ctype
    end
    parser.on("--encoding ENCODING", "Set an encoding") do |encoding|
        $encoding = encoding
    end
    parser.on("--base64", "Encode body in base64") do |bs64|
        $bs64 = bs64
    end
    parser.on("--prompt", "Write content with a Prompt (HTML allowed)") do |prompContent|
        $promptContent = prompContent
    end
    parser.on("--save", "Save email to EML file") do |save|
        $save = save
    end
end.parse!

# AUTO MX RESOLVER W/ RCPT TO #
def mxresolver()
    if !$rcptTo
        print "RCPT TO:"
        $rcptTo = STDIN.gets.chomp() #Get keyboard input
    end
    $domain = $rcptTo.split("@")[1] #cut @ and get only domain
    if !$domain.empty?
        Resolv::DNS.open do |lookup|
            ress = lookup.getresources $domain, Resolv::DNS::Resource::IN::MX
            mxlist = ress.map { |r| [r.exchange] }
            $rMx = mxlist[0] #get 1st mx
        end
    end
    if !$rMx
        puts RedTXT+"SMTP server not found!"+EndTXT
        print "SMTP: "
        $smtpServ = STDIN.gets.chomp()
    end
end

if !$port
    $port = 25
end

########
# Date #
########
time = Time.new
$current = time.strftime("%a, %d %b %Y %I:%M:%S %Z")
if !$date
    $date = $current
end

##############
# Message-ID #
##############
random = SecureRandom.hex
$messageid = "<#{random.upcase}@rubylang.this>"

###########
# Charset #
###########
if $charset
   case $charset.downcase
   when "utf-8", "utf8"
    $charset = "\"UTF-8\""
   when "usascii", "us", "us-ascii"
    $charset = "\"US-ASCII\""
   when "iso88591", "iso-88591", "iso8859-1", "iso-8859-1"
    $charset = "\"ISO-8859-1\""
   else
    $charset = "\"UTF-8\""
   end
else
    $charset = "\"UTF-8\""
end

####################
# HTML File Import #
####################
def htmlimport()
    htmlFileRaw = File.read($htmlFile)
    $body = htmlFileRaw
    $ctype = "text/html"
end
if $htmlFile
    htmlimport()
end

####################
# TEXT File Import #
####################
def txtimport()
    txtFileRaw = File.read($txtFile)
    $body = txtFileRaw
    $ctype = "text/plain"
end
if $txtFile
    txtimport()
end

#############################
# Content-Transfer Encoding #
#############################
def base64encode()
    require 'base64'
    if $ctype != "text/html"
        $encoding = "base64"
        $body = Base64.encode64($body)
    else
        $encoding = "7bit"
    end
end


############
# Encoding #
############
if $encoding
    case $encoding.downcase
    when "qp", "quoted", "quoted-printable", "printable"
        $encoding = "quoted-printable"
    else
        $encoding = "7bit"
    end
else
    $encoding = "7bit"
end

##########
# Base64 #
##########
if $bs64
    base64encode() # and set $encoding = base64
end

################
# Content-Type #
################
if $ctype
    case $ctype
    when "text/plain", "plain"
        $ctype = "text/plain"
    when "text/html", "html"
        $ctype = "text/html"
    else
        $ctype = "text/plain"
    end
else $ctype = "text/plain"
end

############
# X-Mailer #
############
if !$xmailer
    $xmailer = "SendMail-Ruby v1.0"
end

##############
# X-Priority #
##############
if $xprio
    case $xprio
    when "1"
        $xprio = "1"
    when "2"
        $xprio = "2"
    when "3"
        $xprio = "3"
    else
        $xprio = "1"
    end
else
    $xprio = "1"
end

##############
# ATTACHMENT #
##############
def attachment()
    fileRaw = File.read($attach)
    $attachFile = fileRaw

    $encodedFile = Base64.encode64($attachFile)
end

if !$boundary
    $boundary = "----=_MIME_BOUNDARY_RUBY_LANG"
end

if $attach
    attachment()
    $addMSG = "Content-Type: multipart/mixed; boundary=\"#{$boundary}\"

--#{$boundary}
Content-Type: #{$ctype}; charset=#{$charset}
Content-Transfer-Encoding: #{$encoding}

#{$body}
--#{$boundary}
Content-Type: application/octet-stream; charset=#{$charset}; name=\"#{$attach}\"
Content-Description: #{$attach}
Content-Disposition: attachment; filename=\"#{$attach}\"
Content-Transfer-Encoding: base64

#{$encodedFile}

--#{$boundary}--
"
else
    $addMSG = "Content-Type: #{$ctype}; charset=#{$charset}
Content-Transfer-Encoding: #{$encoding}
    
#{$body}"
end    

$MSG = "Date: #{$date}
From: #{$hFrom}
To: #{$hTo}
Subject: #{$subject}
Message-ID: #{$messageid}
X-Mailer: #{$xmailer}
X-Priority: #{$xprio}
MIME-Version: 1.0
#{$addMSG}"

#####################
# SAVE EMAIL as EML #
#####################
def saveEmail()
    outputFile = File.open("savedEmail.eml", "w") { |f| f.write $MSG}
end

if $save
    saveEmail()
end

###################
###################
if !$rcptTo
    print "RCPT TO: "
    $rcptTo = STDIN.gets.chomp()
end

##############
# SEND EMAIL #
##############
def sendEmail()
    if !$rcptTo
        print "RCPT TO: "
        $rcptTo = STDIN.gets.chomp()
    end

    require 'net/smtp'
    puts GreenTXT+"---------------Overview---------------"+EndTXT
    puts $MSG
    puts GreenTXT+"-----------------END------------------"+EndTXT
    if !$optSmtpServ
        mxresolver()
        $smtpServ = $rMx.join("") #convert array into string
    else
        $smtpServ = $optSmtpServ
    end

    begin
        Net::SMTP.start($smtpServ, $port) do |smtp|
            smtp.send_message $MSG, $mailFrom, $rcptTo
            puts "\n" + GreenTXT+"Email sent! -> Message-ID: #{$messageid}"+EndTXT
        end
    rescue => smtperror
        puts "\n" + RedTXT+"Cannot connect to SMTP -> #{$smtpServ.to_s}:#{$port}"+EndTXT
        puts smtperror
    end    
end

sendEmail()