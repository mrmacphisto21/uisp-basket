# Scarica risultati, classifiche e tabellini dei campionati UISP Pallacanestro di un comitato
# e genera l'app HTML (dati incorporati) partendo da app.template.html.
# Uso:  pwsh ./scrape.ps1                 (tutti i campionati di Varese)
#       pwsh ./scrape.ps1 -Camp 9,17      (solo alcuni campionati, per id)
# I campionati senza nessuna partita con punteggio (es. minibasket) vengono esclusi.
param(
    [string]$Base = "https://gestionalepallacanestro.uisp.it",
    [string]$Comitato = "Varese",
    [int[]]$Camp = @(),
    [int]$DelayMs = 200,
    [string]$OutName = "Varese_Basket.html",
    [switch]$BuildOnly
)
$ErrorActionPreference = 'Stop'

function Get-Html([string]$path) {
    Start-Sleep -Milliseconds $DelayMs
    for ($i = 1; $i -le 3; $i++) {
        try { return (Invoke-WebRequest -Uri "$Base$path" -UseBasicParsing -TimeoutSec 30).Content }
        catch { if ($i -eq 3) { throw }; Start-Sleep -Seconds 2 }
    }
}
function Strip([string]$s) {
    if ($null -eq $s) { return $null }
    $t = ($s -replace '<[^>]+>', ' ' -replace '\s+', ' ').Trim()
    [System.Net.WebUtility]::HtmlDecode($t)
}
function ToInt($s) { $v = 0; if ([int]::TryParse(("$s").Trim(), [ref]$v)) { $v } else { $null } }

function Get-Campionato([int]$Camp) {
$campPath = "/$Comitato/$Camp"
Write-Host "Campionato $campPath"
$campHtml = Get-Html $campPath
$campName = Strip ([regex]::Match($campHtml, '(?s)<small class="text-light[^"]*">(.*?)</small>').Groups[1].Value)

# Gironi / fasi: link /Comitato/Camp/{id}
$gironi = @()
foreach ($m in [regex]::Matches($campHtml, "(?s)<a[^>]+href=""$campPath/(\d+)""[^>]*>(.*?)</a>")) {
    $gid = [int]$m.Groups[1].Value
    if ($gironi.id -contains $gid) { continue }
    $gironi += [ordered]@{ id = $gid; label = (Strip $m.Groups[2].Value); name = $null; standings = @(); matches = @() }
}

$rxCard  = '(?s)<a class="card card-flush[^"]*" href="' + [regex]::Escape($campPath) + '/(\d+)/(\d+)/(\d+)/(\d+)">(.*?)</a>'
$rxTeam  = '(?s)text-light fw-bolder fs-7 text-uppercase">(.*?)</span>'
$rxScore = '(?s)text-light fw-bolder fs-2">(.*?)</span>'
$rxDate  = '(?s)fw-bold fs-7 text-capitalize">(.*?)</span>\s*<span class="text-gray-500 fs-7">(.*?)</span>'
$rxVenue = '(?s)<span class="text-gray-900 fw-bold fs-7">(.*?)</span>'
$rxStand = '(?s)<td class="fw-bold text-gray-800 border-end text-uppercase">(.*?)</td>\s*<td[^>]*>\s*(-?\d+)\s*</td>\s*<td[^>]*>\s*(\d+)\s*</td>\s*<td[^>]*>\s*(\d+)\s*</td>\s*<td[^>]*>\s*(\d+)\s*</td>\s*<td[^>]*>\s*(\d+)\s*</td>'
$rxBoxRow = '(?s)<tr>\s*<td[^>]*>\s*(\d*)\s*</td>\s*<td class="fw-bold fs-6">(.*?)</td>\s*<td class="text-center">\s*(\d+)\s*</td>\s*<td class="text-center">\s*(\d+)\s*</td>\s*<td class="text-center">\s*(\d+)\s*</td>\s*<td[^>]*>\s*(\d+)\s*</td>'

foreach ($g in $gironi) {
    $gPath = "$campPath/$($g.id)"
    $first = Get-Html "$gPath`?round=1&roundnumber=1"
    $rounds = [regex]::Matches($first, 'round=(\d)&(?:amp;)?roundnumber=(\d+)') |
        ForEach-Object { "$($_.Groups[1].Value)-$($_.Groups[2].Value)" } | Sort-Object -Unique
    Write-Host "Girone $($g.id): $($rounds.Count) giornate"

    # Classifica (uguale su ogni pagina giornata)
    foreach ($s in [regex]::Matches($first, $rxStand)) {
        $g.standings += [ordered]@{
            team = Strip $s.Groups[1].Value; pt = [int]$s.Groups[2].Value
            v = [int]$s.Groups[3].Value; s = [int]$s.Groups[4].Value
            pf = [int]$s.Groups[5].Value; ps = [int]$s.Groups[6].Value
        }
    }

    foreach ($rk in $rounds) {
        $r, $n = $rk.Split('-')
        $html = if ($rk -eq '1-1') { $first } else { Get-Html "$gPath`?round=$r&roundnumber=$n" }
        foreach ($c in [regex]::Matches($html, $rxCard)) {
            if ([int]$c.Groups[1].Value -ne $g.id) { continue }
            $id = [int]$c.Groups[4].Value
            if ($g.matches.id -contains $id) { continue }
            $body = $c.Groups[5].Value
            $teams = [regex]::Matches($body, $rxTeam) | ForEach-Object { Strip $_.Groups[1].Value }
            $sc = [regex]::Matches($body, $rxScore) | ForEach-Object { ToInt (Strip $_.Groups[1].Value) }
            $dm = [regex]::Match($body, $rxDate)
            $match = [ordered]@{
                id = $id; round = [int]$c.Groups[2].Value; num = [int]$c.Groups[3].Value
                home = $teams[0]; away = $teams[1]; hs = $sc[0]; as = $sc[1]
                date = Strip $dm.Groups[1].Value; time = Strip $dm.Groups[2].Value
                venue = Strip ([regex]::Match($body, $rxVenue).Groups[1].Value)
                q = $null; box = $null; coach = $null
            }
            if ($null -ne $match.hs -and $null -ne $match.as) {
                $mh = Get-Html "$gPath/$($c.Groups[2].Value)/$($c.Groups[3].Value)/$id"
                if (-not $g.name) {
                    $g.name = Strip ([regex]::Match($mh, "(?s)href=""$([regex]::Escape($gPath))\?round=[^""]*""[^>]*>(.*?)</a>").Groups[1].Value)
                }
                # Parziali (cumulativi sul sito)
                $pi = $mh.IndexOf('Parziali')
                if ($pi -ge 0) {
                    $pt = $mh.Substring($pi, [Math]::Min(6000, $mh.Length - $pi))
                    $pt = $pt.Substring(0, $pt.IndexOf('</table>'))
                    $qrows = [regex]::Matches($pt, '(?s)<tr>\s*<td class="fw-semibold[^"]*">.*?</td>(.*?)</tr>') | ForEach-Object {
                        , @([regex]::Matches($_.Groups[1].Value, '<td[^>]*>\s*(\d*)\s*</td>') | ForEach-Object { ToInt $_.Groups[1].Value })
                    }
                    if ($qrows.Count -eq 2) { $match.q = @(, $qrows[0]) + @(, $qrows[1]) }
                }
                # Tabellini
                $parts = $mh -split 'Convocati e tabellino'
                $boxes = @(); $coaches = @()
                for ($k = 1; $k -lt $parts.Count; $k++) {
                    $team = Strip (([regex]::Matches($parts[$k - 1], '(?s)card-label fw-bold text-gray-800">(.*?)</span>') | Select-Object -Last 1).Groups[1].Value)
                    $seg = $parts[$k]
                    $end = $seg.IndexOf('</tbody>'); $tbl = if ($end -ge 0) { $seg.Substring(0, $end) } else { $seg }
                    $players = foreach ($p in [regex]::Matches($tbl, $rxBoxRow)) {
                        $cell = $p.Groups[2].Value
                        $role = [regex]::Match($cell, 'title="([^"]+)"').Groups[1].Value
                        $name = Strip ($cell -replace '(?s)<span.*?</span>', '')
                        [ordered]@{ n = (ToInt $p.Groups[1].Value); name = $name; c = $(if ($role -eq 'Capitano') { 'C' } elseif ($role -eq 'Vice Capitano') { 'V' } else { '' })
                            ft = [int]$p.Groups[3].Value; p2 = [int]$p.Groups[4].Value; p3 = [int]$p.Groups[5].Value; pts = [int]$p.Groups[6].Value }
                    }
                    $coach = Strip ([regex]::Match($seg, '(?s)<span class="text-gray-800 fw-bold fs-6[^"]*">([^<]*)</span>\s*</div>\s*<div[^>]*>\s*<span class="badge badge-primary" title="Allenatore"').Groups[1].Value)
                    $boxes += , [ordered]@{ team = $team; players = @($players) }
                    $coaches += $coach
                }
                if ($boxes.Count -ge 2) {
                    $match.box = [ordered]@{ home = $boxes[0].players; away = $boxes[1].players }
                    $match.coach = [ordered]@{ home = $coaches[0]; away = $coaches[1] }
                }
            }
            $g.matches += $match
        }
    }
    if (-not $g.name) { $g.name = $g.label }
    $played = @($g.matches | Where-Object { $null -ne $_.hs })
    $withBox = @($played | Where-Object { $_.box })
    $sumPts = { param($rows) $t = 0; foreach ($r in $rows) { $t += $r['pts'] }; $t }
    $bad = @($withBox | Where-Object { ((& $sumPts $_.box.home) -ne $_.hs) -or ((& $sumPts $_.box.away) -ne $_.as) })
    Write-Host ("  partite: {0}, giocate: {1}, con tabellino: {2}, con parziali: {3}" -f $g.matches.Count, $played.Count, $withBox.Count, @($played | Where-Object { $_.q }).Count)
    foreach ($b in $bad) { Write-Warning "  partita $($b.id): somma tabellino diversa dal punteggio" }
}
$gironi = @($gironi | Where-Object { $_.matches.Count -gt 0 })
return [ordered]@{ id = $Camp; nome = $campName; gironi = $gironi }
}

function Build-App([string]$json) {
    $tpl = Get-Content -Raw -Path (Join-Path $PSScriptRoot 'app.template.html') -Encoding utf8
    $safe = $json.Replace('</', '<\/').Replace('<!--', '<!--')
    # il template viene incorporato anche come stringa: serve al pulsante "Aggiorna" per ripubblicare la pagina intera
    $tplStr = (ConvertTo-Json -InputObject $tpl -Compress).Replace('</', '<\/').Replace('<!--', '<!--')
    $outFile = Join-Path $PSScriptRoot $OutName
    $tpl.Replace('/*__DATA__*/null', $safe).Replace('/*__TPL__*/""', $tplStr) | Set-Content -Path $outFile -Encoding utf8 -NoNewline
    Write-Host "Creato $outFile"
}
# -BuildOnly: rigenera solo l'HTML dal data.json esistente, senza scaricare
if ($BuildOnly) { Build-App (Get-Content -Raw -Path (Join-Path $PSScriptRoot "data.json") -Encoding utf8).Trim(); return }

# Elenco campionati dalla home del comitato
$homeHtml = Get-Html "/$Comitato"
$ids = @([regex]::Matches($homeHtml, "href=""/$Comitato/(\d+)""") | ForEach-Object { [int]$_.Groups[1].Value } | Select-Object -Unique)
if ($Camp.Count) { $ids = @($ids | Where-Object { $Camp -contains $_ }) }
Write-Host "Campionati da scaricare: $($ids -join ', ')"

$campionati = @()
foreach ($cid in $ids) {
    $c = Get-Campionato $cid
    $nPlayed = @($c.gironi | ForEach-Object { $_.matches } | Where-Object { $null -ne $_.hs }).Count
    if ($nPlayed -eq 0) { Write-Host "  -> escluso (nessuna partita con punteggio)"; continue }
    $campionati += $c
}

$data = [ordered]@{
    generated = (Get-Date).ToString('yyyy-MM-dd HH:mm')
    source = "$Base/$Comitato"
    comitato = $Comitato
    campionati = $campionati
}
$json = $data | ConvertTo-Json -Depth 14 -Compress
$json | Set-Content -Path (Join-Path $PSScriptRoot "data.json") -Encoding utf8

Build-App $json
Write-Host "Campionati inclusi: $($campionati.Count)"
