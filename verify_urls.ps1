$content = Get-Content 'g:\quiz_apps\lib\services\bdapps_service.dart' -Raw
$matches = [regex]::Matches($content, '(gatewayBaseUrl|apiVersion|sendOtpPath|verifyOtpPath|statusPath|unsubscribePath|_base)\s*[=:][^,;\n}]+')
foreach ($m in $matches) {
    Write-Output $m.Value
}