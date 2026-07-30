# ==========================================================
#  Crew Quiz - minimal statisk webserver (ingen installation)
#  Bruges automatisk af start.bat hvis Python/Node mangler.
# ==========================================================
param([int]$Port = 8080)

$root = $PSScriptRoot
if (-not $root) { $root = (Get-Location).Path }

$types = @{
  '.html' = 'text/html; charset=utf-8'
  '.htm'  = 'text/html; charset=utf-8'
  '.css'  = 'text/css; charset=utf-8'
  '.js'   = 'text/javascript; charset=utf-8'
  '.mjs'  = 'text/javascript; charset=utf-8'
  '.json' = 'application/json; charset=utf-8'
  '.svg'  = 'image/svg+xml'
  '.png'  = 'image/png'
  '.jpg'  = 'image/jpeg'
  '.jpeg' = 'image/jpeg'
  '.gif'  = 'image/gif'
  '.ico'  = 'image/x-icon'
  '.mp3'  = 'audio/mpeg'
  '.m4a'  = 'audio/mp4'
  '.wav'  = 'audio/wav'
  '.woff2'= 'font/woff2'
  '.txt'  = 'text/plain; charset=utf-8'
  '.md'   = 'text/plain; charset=utf-8'
}

try {
  $listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, $Port)
  $listener.Start()
} catch {
  Write-Host ""
  Write-Host "  Kunne ikke starte server paa port $Port." -ForegroundColor Red
  Write-Host "  Porten er sandsynligvis optaget af et andet program."
  Write-Host "  Proev en anden port, f.eks.:  powershell -ExecutionPolicy Bypass -File serve.ps1 -Port 8090"
  Write-Host ""
  Read-Host "Tryk Enter for at lukke"
  exit 1
}

Write-Host ""
Write-Host "  Crew Quiz koerer!" -ForegroundColor Green
Write-Host "  Aabn:  http://127.0.0.1:$Port/" -ForegroundColor Cyan
Write-Host "  Mappe: $root"
Write-Host ""
Write-Host "  Luk dette vindue (eller tryk Ctrl+C) for at stoppe serveren."
Write-Host ""

function Send-Response {
  param($Stream, [int]$Status, [string]$StatusText, [string]$ContentType, [byte[]]$Body)
  $header  = "HTTP/1.1 $Status $StatusText`r`n"
  $header += "Content-Type: $ContentType`r`n"
  $header += "Content-Length: $($Body.Length)`r`n"
  $header += "Cache-Control: no-store`r`n"
  $header += "Connection: close`r`n`r`n"
  $hb = [System.Text.Encoding]::ASCII.GetBytes($header)
  $Stream.Write($hb, 0, $hb.Length)
  if ($Body.Length -gt 0) { $Stream.Write($Body, 0, $Body.Length) }
  $Stream.Flush()
}

while ($true) {
  $client = $null
  try {
    $client = $listener.AcceptTcpClient()
    $client.ReceiveTimeout = 5000
    $client.SendTimeout    = 15000
    $stream = $client.GetStream()

    # --- read request line (raw, so we don't over-buffer) ---
    $sb = New-Object System.Text.StringBuilder
    $buf = New-Object byte[] 1
    while ($sb.Length -lt 4096) {
      $n = $stream.Read($buf, 0, 1)
      if ($n -le 0) { break }
      $c = [char]$buf[0]
      if ($c -eq "`n") { break }
      if ($c -ne "`r") { [void]$sb.Append($c) }
    }
    $requestLine = $sb.ToString()
    if (-not $requestLine) { $client.Close(); continue }

    $parts = $requestLine.Split(' ')
    $method = $parts[0]
    $rawPath = '/'
    if ($parts.Length -gt 1) { $rawPath = $parts[1] }

    # strip query string / fragment, decode %xx
    $rawPath = ($rawPath -split '\?')[0]
    $rawPath = ($rawPath -split '#')[0]
    $rawPath = [System.Uri]::UnescapeDataString($rawPath)
    if ($rawPath -eq '/' -or $rawPath -eq '') { $rawPath = '/index.html' }

    $rel = $rawPath.TrimStart('/').Replace('/', [System.IO.Path]::DirectorySeparatorChar)
    $full = [System.IO.Path]::GetFullPath((Join-Path $root $rel))

    # --- directory-traversal guard ---
    $rootFull = [System.IO.Path]::GetFullPath($root).TrimEnd([System.IO.Path]::DirectorySeparatorChar)
    $inside = $full.StartsWith($rootFull + [System.IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)

    if (($method -ne 'GET' -and $method -ne 'HEAD') -or (-not $inside) -or (-not (Test-Path -LiteralPath $full -PathType Leaf))) {
      $body = [System.Text.Encoding]::UTF8.GetBytes("404 - ikke fundet: $rawPath")
      Send-Response $stream 404 'Not Found' 'text/plain; charset=utf-8' $body
      Write-Host ("  404  " + $rawPath) -ForegroundColor DarkGray
    } else {
      $ext = [System.IO.Path]::GetExtension($full).ToLower()
      $ct = $types[$ext]
      if (-not $ct) { $ct = 'application/octet-stream' }
      $body = [System.IO.File]::ReadAllBytes($full)
      if ($method -eq 'HEAD') { $body = New-Object byte[] 0 }
      Send-Response $stream 200 'OK' $ct $body
      Write-Host ("  200  " + $rawPath) -ForegroundColor DarkGray
    }
  } catch {
    # klient lukkede forbindelsen - ignorer
  } finally {
    if ($client) { try { $client.Close() } catch {} }
  }
}
