# Cifra la pagina generata con una password e produce la pagina di sblocco da pubblicare su GitHub Pages.
# HTML -> gzip -> AES-256-GCM con chiave PBKDF2-SHA256 (la stessa catena che il browser inverte con WebCrypto).
# Uso:  $env:PAGINA_PASSWORD = "..." ; pwsh ./cifra.ps1            (crea site/index.html)
param(
    [string]$In = (Join-Path $PSScriptRoot "Varese_Basket.html"),
    [string]$OutDir = (Join-Path $PSScriptRoot "site"),
    [string]$Password = $env:PAGINA_PASSWORD,
    [int]$Iterations = 310000
)
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrEmpty($Password)) { throw "Manca la password: imposta PAGINA_PASSWORD (secret del repository)." }
if (-not (Test-Path $In)) { throw "Non trovo la pagina da cifrare: $In" }

# gzip
$plain = [IO.File]::ReadAllBytes($In)
$ms = [IO.MemoryStream]::new()
$gz = [IO.Compression.GZipStream]::new($ms, [IO.Compression.CompressionLevel]::Optimal)
$gz.Write($plain, 0, $plain.Length); $gz.Dispose()
$packed = $ms.ToArray()

# chiave e cifratura
$salt = [byte[]]::new(16); $iv = [byte[]]::new(12)
[Security.Cryptography.RandomNumberGenerator]::Fill($salt); [Security.Cryptography.RandomNumberGenerator]::Fill($iv)
$key = [Security.Cryptography.Rfc2898DeriveBytes]::Pbkdf2([Text.Encoding]::UTF8.GetBytes($Password), $salt, $Iterations, [Security.Cryptography.HashAlgorithmName]::SHA256, 32)
$cipher = [byte[]]::new($packed.Length); $tag = [byte[]]::new(16)
$aes = [Security.Cryptography.AesGcm]::new($key, 16)
$aes.Encrypt($iv, $packed, $cipher, $tag); $aes.Dispose()
$data = [byte[]]::new($cipher.Length + 16)
[Array]::Copy($cipher, $data, $cipher.Length); [Array]::Copy($tag, 0, $data, $cipher.Length, 16)   # WebCrypto vuole testo||tag

$payload = [ordered]@{
    v = 1; iter = $Iterations
    salt = [Convert]::ToBase64String($salt); iv = [Convert]::ToBase64String($iv)
    data = [Convert]::ToBase64String($data)
    quando = (Get-Date).ToString('dd/MM/yyyy HH:mm')
} | ConvertTo-Json -Compress

$tpl = Get-Content -Raw -Path (Join-Path $PSScriptRoot 'sblocca.template.html') -Encoding utf8
New-Item -ItemType Directory -Force $OutDir | Out-Null
$out = Join-Path $OutDir 'index.html'
$tpl.Replace('/*__PAYLOAD__*/null', $payload) | Set-Content -Path $out -Encoding utf8 -NoNewline
Write-Host ("Pagina cifrata: {0} ({1:N0} KB, originale {2:N0} KB)" -f $out, ((Get-Item $out).Length / 1KB), ($plain.Length / 1KB))
