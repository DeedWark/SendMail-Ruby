# SendMail-Ruby
Send email in Ruby

## Usage
```bash
ruby SendMail.rb --help
```
```
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
--base64         Encode body in base64
--prompt         Get a prompt to write on your terminal 
```

```bash
ruby SendMail.rb
```
