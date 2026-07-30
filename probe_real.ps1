$url = 'https://bdappsdigitalapps.com/NADB26066/send_otp.php'
$body = '{"appName":"quiz36","userMobile":"01812345678"}'
try {
    $r = Invoke-WebRequest -Uri $url -Method POST -Headers @{
        'Content-Type' = 'application/json'
        'Accept' = 'application/json'
        'Origin' = 'http://localhost:5173'
    } -Body $body -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop
    Write-Output "STATUS: $($r.StatusCode)"
    Write-Output "BODY: $($r.Content)"
} catch {
    $code = 'unknown'
    if ($_.Exception.Response) { $code = [int]$_.Exception.Response.StatusCode }
    Write-Output "STATUS: $code"
    if ($_.Exception.Response) {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        Write-Output "BODY: $($reader.ReadToEnd())"
    } else {
        Write-Output "ERROR: $($_.Exception.Message)"
    }
}