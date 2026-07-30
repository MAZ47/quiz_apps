$files = @('send_otp.php','verify_otp.php','check_subscription.php','unsubscribe.php')
foreach ($f in $files) {
    foreach ($path in @("/$f", "/v1/$f")) {
        $url = "https://bdappsdigitalapps.com/NADB26066$path"
        try {
            $r = Invoke-WebRequest -Uri $url -Method OPTIONS -Headers @{
                Origin='http://localhost:5173'
                'Access-Control-Request-Method'='POST'
                'Access-Control-Request-Headers'='content-type'
            } -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
            Write-Output "$url -> $($r.StatusCode)"
        } catch {
            $code = 'unknown'
            if ($_.Exception.Response) { $code = [int]$_.Exception.Response.StatusCode }
            Write-Output "$url -> $code"
        }
    }
}