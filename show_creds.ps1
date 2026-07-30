$lines = Get-Content 'c:\Users\Zubair\Downloads\v1\app_credentials.php' -Encoding UTF8
foreach ($l in $lines) {
    Write-Output $l
}