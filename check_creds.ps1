$urls = @(
    'https://bdappsdigitalapps.com/NADB26066/app_credentials.php',
    'https://bdappsdigitalapps.com/NADB26066/app_auth.php'
)
foreach ($u in $urls) {
    try {
        $r = Invoke-WebRequest -Uri $u -Method GET -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
        Write-Output "URL: $u"
        Write-Output "STATUS: $($r.StatusCode)"
        Write-Output "BODY (first 300 chars):"
        $body = if ($r.Content.Length -gt 300) { $r.Content.Substring(0,300) + '...' } else { $r.Content }
        Write-Output $body
        Write-Output "---"
    } catch {
        $code = 'unknown'
        if ($_.Exception.Response) { $code = [int]$_.Exception.Response.StatusCode }
        Write-Output "URL: $u -> STATUS: $code"
        Write-Output "---"
    }
}