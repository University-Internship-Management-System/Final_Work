$ErrorActionPreference = 'Stop'
$url='https://localhost:44360/ContactUs/ContactPage/Contact'
function Get-Form($html) {
 $data=@{}
 foreach($match in [regex]::Matches($html,'<input\b[^>]*type="hidden"[^>]*>')) {
  $name=[regex]::Match($match.Value,'name="([^"]+)"').Groups[1].Value
  $value=[regex]::Match($match.Value,'value="([^"]*)"').Groups[1].Value
  $data[$name]=[System.Net.WebUtility]::HtmlDecode($value)
 }
 $data['ctl00$MainContent$Send']='Send Message'
 return $data
}
$first=Invoke-WebRequest -Uri $url -SessionVariable session -UseBasicParsing
if ($first.StatusCode -ne 200 -or $first.Content -notmatch 'disabled="disabled"') {throw 'Page did not fail closed'}
$form=Get-Form $first.Content
foreach($key in @('FullName','Email','Subject','Message')) {$form['ctl00$MainContent$'+$key]=''}
$empty=Invoke-WebRequest -Uri $url -WebSession $session -Method Post -Body $form -UseBasicParsing
if($empty.Content -notmatch 'Full name is required' -or $empty.Content -notmatch 'Message is required') {throw 'Empty server validation missing'}
$form=Get-Form $empty.Content
$form['ctl00$MainContent$FullName']='Test Student'
$form['ctl00$MainContent$Email']='invalid-email'
$form['ctl00$MainContent$Subject']='Question'
$form['ctl00$MainContent$Message']='<script>alert(1)</script>'
$invalid=Invoke-WebRequest -Uri $url -WebSession $session -Method Post -Body $form -UseBasicParsing
if($invalid.Content -notmatch 'Enter a valid email' -or $invalid.Content -notmatch 'without HTML' -or $invalid.Content -match '<script>alert\(1\)</script>') {throw 'Unsafe invalid input response'}
$form=Get-Form $invalid.Content
$form['ctl00$MainContent$FullName']='Test Student'
$form['ctl00$MainContent$Email']='test@example.com'
$form['ctl00$MainContent$Subject']='Question'
$form['ctl00$MainContent$Message']='Offline integration test; persistence must remain disabled.'
$blocked=Invoke-WebRequest -Uri $url -WebSession $session -Method Post -Body $form -UseBasicParsing
if($blocked.Content -notmatch 'Secure message sending is not configured' -or $blocked.Content -match 'saved successfully') {throw 'Unavailable backend falsely succeeded'}
$again=Invoke-WebRequest -Uri $url -WebSession $session -Method Post -Body $form -UseBasicParsing
if($again.Content -match 'saved successfully') {throw 'Duplicate disabled submission succeeded'}
$form['ctl00$MainContent$Csrf']='invalid'
$csrf=Invoke-WebRequest -Uri $url -WebSession $session -Method Post -Body $form -UseBasicParsing
if($csrf.Content -notmatch 'expired or was already submitted') {throw 'CSRF rejection missing'}
Write-Output 'PASS: 6 local HTTPS Web Forms integration checks: load/disabled backend, empty validation, invalid email and encoded script, blocked valid submission, repeated blocked submission, CSRF rejection. No Firebase credentials configured or live persistence attempted.'
