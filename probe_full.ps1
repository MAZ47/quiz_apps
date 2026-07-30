$url = 'https://bdappsdigitalapps.com/NADB26066/send_otp.php'
$body = '{"appName":"quiz36","userMobile":"01700000000"}'
$r = Invoke-WebRequest -Uri $url -Method POST -Headers @{
    'Content-Type' = 'application/json'
    'Accept' = 'application/json'
    'Origin' = 'http://localhost:5173'
} -Body $body -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop
$resp = $r.Content | ConvertFrom-Json
Write-Output "STATUS: $($r.StatusCode)"
Write-Output "FULL RESPONSE:"
$r.Content
Write-Output ""
Write-Output "PARSED FIELDS:"
Write-Output "  success: $($resp.success)"
Write-Output "  referenceNo: $($resp.referenceNo)"
Write-Output "  statusCode: $($resp.statusCode)"
Write-Output "  statusDetail: $($resp.statusDetail)"
Write-Output "  message: $($resp.message)"
if ($resp.data) {
    Write-Output "  data: $($resp.data)"
}