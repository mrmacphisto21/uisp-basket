# COMPITO
Costruisci una piccola applicazione per seguire i campionati di basket giovanile UISP del Comitato di Varese.
È composta da due parti:
1. uno SCRIPT che scarica i dati dal sito pubblico e li salva in JSON;
2. un'APP WEB in un unico file HTML autonomo (HTML + CSS + JavaScript, senza librerie esterne né server) che contiene i dati e li mostra.

Rispondi fornendo il codice completo di entrambi i file, più le istruzioni per eseguirli.

# VINCOLI
- Il sito è pubblico, senza login e senza API. Le pagine sono HTML generato dal server.
- Il sito NON permette richieste cross-origin (niente CORS), quindi l'app NON può leggerlo in diretta dal browser: i dati vanno scaricati dallo script e incorporati nell'HTML.
- Linguaggio dello script: PowerShell 7 (preferito, gira su Windows senza installare nulla) oppure Python 3 con requests + BeautifulSoup. Se usi PowerShell, NON chiamare nessuna funzione "Clean": è una parola riservata in PowerShell 7.3+.
- Rispetta il sito: pausa di circa 200 ms tra una richiesta e l'altra, massimo 3 tentativi per errore, scarica le pagine partita solo per le gare già giocate.
- L'app deve funzionare aprendo il file HTML con doppio clic, anche offline.
- Lingua dell'interfaccia: italiano. Formato numeri: virgola decimale (es. 12,5).

# FONTE DATI
Base: https://gestionalepallacanestro.uisp.it

## Gerarchia degli URL
| Livello | URL | Contenuto |
|---|---|---|
| Comitato | /Varese | link ai campionati: /Varese/{idCampionato} |
| Campionato | /Varese/{camp} | nome del campionato + link ai gironi/fasi: /Varese/{camp}/{idGirone} |
| Giornata | /Varese/{camp}/{girone}?round={r}&roundnumber={n} | partite della giornata + classifica del girone + link a tutte le giornate |
| Partita | /Varese/{camp}/{girone}/{r}/{n}/{idPartita} | parziali per quarto + tabellini dei giocatori |

- round = 1 andata, 2 ritorno; roundnumber = numero della giornata.
- Campionati noti (id → nome): 1 First League, 2 Second League, 6 Under 19, 7 Under 18, 8 Under 17, 9 Under 16, 10 Under 15, 11 Under 14, 12 Under 13, 17 Under 16 Femminile, 22 Esordienti, 28 Aquilotti, 30 Scoiattoli. Non fidarti di questo elenco: ricavalo sempre dalla pagina /Varese.
- Aquilotti, Scoiattoli ed Esordienti sono minibasket e potrebbero non avere punteggi né classifiche. Se un campionato non ha nessuna partita con punteggio, escludilo dall'app.

## Pagina campionato (/Varese/{camp})
- Nome del campionato: `<small class="text-light ...">UNDER 16</small>`
- Gironi: `<a href="/Varese/9/106">…testo con il nome del girone…</a>`

## Pagina giornata (/Varese/{camp}/{girone}?round=1&roundnumber=1)
Link alle giornate (nell'HTML il carattere & può comparire come &amp;):
`/Varese/9/106?round=1&roundnumber=1` … `?round=2&roundnumber=9`

Ogni partita è una card così (estratto reale, semplificato):
```html
<a class="card card-flush ..." href="/Varese/9/106/1/1/4177">
  <span class="text-light fw-bolder fs-7 text-uppercase">Varese Basket School</span>   <!-- casa -->
  <span class="text-light fw-bolder fs-2"> 34 </span>                                  <!-- punti casa, "-" se non giocata -->
  <span class="text-light fw-bolder fs-2"> 69 </span>                                  <!-- punti ospite -->
  <span class="text-light fw-bolder fs-7 text-uppercase">BASKET ACADEMY O.S.S.</span>  <!-- ospite -->
  <!-- Information -->
  <span class="text-gray-900 fw-bold fs-7 text-capitalize"> 17 ottobre 2026 (sab) </span>
  <span class="text-gray-500 fs-7"> 15:30 </span>
  <span class="text-gray-900 fw-bold fs-7"> Varese - Via Andrea Appiani, 15 (SCUOLA MEDIA ...) </span>
</a>
```

In fondo alla stessa pagina c'è la CLASSIFICA del girone. È identica su ogni giornata, quindi leggila una volta sola:
```html
<th>Classifica</th><th title="Punti">Pt</th><th>V</th><th>S</th><th title="Punti fatti">PF</th><th title="Punti subiti">PS</th>
...
<tr>
  <td class="ps-3">(logo)</td>
  <td class="fw-bold text-gray-800 border-end text-uppercase">BASKET ACADEMY O.S.S.</td>
  <td class="...">8</td> <td>4</td> <td>0</td> <td>261</td> <td>181</td>
</tr>
```
(Pt, V, S, PF, PS nell'ordine. Le partite giocate sono V+S.)

## Pagina partita (/Varese/9/106/1/1/4177)
Nome del girone nel breadcrumb: `<a href="/Varese/9/106?round=1&roundnumber=1">REGULAR SEASON, EST</a>`. Usa la parte dopo la virgola ("EST") come nome breve.

Tabella "Parziali". ATTENZIONE: i valori sono CUMULATIVI; il punteggio del singolo quarto è la differenza con il precedente. Possono esserci colonne in più per i supplementari.
```html
<h6>Parziali</h6>
<table> <th>1°</th><th>2°</th><th>3°</th><th>4°</th>
  <tr><td class="fw-semibold ...">Varese Basket School</td><td>7</td><td>17</td><td>25</td><td>34</td></tr>
  <tr><td class="fw-semibold ...">BASKET ACADEMY O.S.S.</td><td>19</td><td>35</td><td>55</td><td>69</td></tr>
</table>
```

Due tabellini, prima casa e poi ospite. Il nome della squadra è nello span card-label che precede il testo "Convocati e tabellino":
```html
<span class="card-label fw-bold text-gray-800">Varese Basket School</span>
<span class="...">Convocati e tabellino</span>
<table> <th>#</th><th>Giocatore</th><th>1 PTS</th><th>2 PTS</th><th>3 PTS</th><th>TOT</th>
  <tr>
    <td>24</td>
    <td class="fw-bold fs-6"> COGNOME NOME <span class="badge ..." title="Capitano">C</span> </td>
    <td class="text-center">5</td>   <!-- tiri liberi SEGNATI -->
    <td class="text-center">4</td>   <!-- canestri da 2 SEGNATI -->
    <td class="text-center">0</td>   <!-- canestri da 3 SEGNATI -->
    <td class="... fw-bolder">13</td> <!-- punti -->
  </tr>
</table>
<span class="text-gray-800 fw-bold fs-6">COGNOME NOME</span> <span class="badge badge-primary" title="Allenatore">A</span>
```
- Badge possibili accanto al giocatore: title="Capitano" (C) o title="Vice Capitano" (V).
- Se il titolo è solo "Convocati" (senza "e tabellino") e le colonne punti mancano, il tabellino NON è stato inserito: la partita ha solo il risultato.
- I dati sono CANESTRI SEGNATI. Il sito NON registra tiri tentati, rimbalzi, assist, falli o palle perse: non inventarli e non calcolare percentuali al tiro.

# OUTPUT DELLO SCRIPT
File data.json con questa struttura:
```json
{
  "generated": "2026-11-16 12:30",
  "source": "https://gestionalepallacanestro.uisp.it/Varese",
  "comitato": "Varese",
  "campionati": [{
    "id": 9, "nome": "UNDER 16",
    "gironi": [{
      "id": 106, "name": "REGULAR SEASON, EST", "short": "EST",
      "standings": [{"team":"...","pt":8,"v":4,"s":0,"pf":261,"ps":181}],
      "matches": [{
        "id": 4177, "round": 1, "num": 1,
        "home": "...", "away": "...", "hs": 34, "as": 69,
        "date": "17 ottobre 2026 (sab)", "time": "15:30", "venue": "...",
        "q": [[7,17,25,34],[19,35,55,69]],
        "box": {"home": [{"n":24,"name":"...","c":"C","ft":5,"p2":4,"p3":0,"pts":13}], "away": []},
        "coach": {"home": "...", "away": "..."}
      }]
    }]
  }]
}
```
- Partite non giocate: hs/as = null, q/box/coach = null. Partite senza tabellino: box = null.
- Lo script genera anche l'HTML finale: legge un file template e sostituisce il segnaposto `/*__DATA__*/null` con il JSON (sostituendo "</" con "<\/" per non rompere il tag script).
- A fine esecuzione stampa per ogni girone: partite totali, giocate, con tabellino, con parziali. Segnala come avviso le partite in cui la somma dei punti del tabellino è diversa dal punteggio finale.

# APP WEB (file HTML unico)
## Navigazione
- Header con: selettore del CAMPIONATO, pulsanti per il GIRONE (es. EST / OVEST), schede Classifica · Risultati · Giocatori · Squadre · Confronto.
- La scheda attiva sta nell'hash dell'URL (#classifica, #risultati, …). Campionato e girone scelti si salvano in localStorage, dentro try/catch.

## 1. Classifica
- Tabella ufficiale: pos, squadra, Pt, G (=V+S), V, S, PF, PS, più colonne calcolate: Diff (PF−PS, verde se positiva e rosso se negativa), PF/G, PS/G, Ultime 5 (V/S da risultati ordinati per data).
- 4 riquadri in alto:
  - miglior attacco (PF/G);
  - miglior difesa (PS/G più basso);
  - top scorer per media punti (minimo 2 partite);
  - media punti totali a partita, con numero di gare e scarto massimo.

## 2. Risultati
- Pulsanti per giornata ("Andata 1" … "Ritorno N"). All'apertura è selezionata l'ultima giornata con almeno una partita giocata.
- Card della partita: squadre, punteggio (vincente in grassetto), data, ora, campo, etichetta di stato: "Tabellino", "Solo risultato" o "Da giocare".
- Al click su una partita giocata si apre una finestra con:
  - punteggio;
  - tabella dei quarti con i punti DEL SINGOLO QUARTO (non cumulativi), evidenziando chi ha vinto il quarto;
  - i due tabellini ordinati per punti, con riga dei totali e top scorer evidenziato;
  - allenatori e campo.

## 3. Giocatori
- Un giocatore è identificato da squadra + nome. PG = numero di tabellini in cui compare.
- Colonne ordinabili al click: #, Giocatore, Squadra, PG, Punti, Media, Max (in una partita), TL, 2P, 3P, 3P/G, % punti da 3 (= 3P×3 / punti).
- Filtri: ricerca per nome, squadra, partite minime (1–5), casella "entrambi i gironi".

## 4. Squadre
Menu per scegliere la squadra (cliccare un nome di squadra in qualunque scheda porta qui). Mostra:
- posizione, punti, V-S, PF/G, PS/G, miglior marcatore;
- media punti fatti e subiti per quarto (barre orizzontali affiancate);
- da dove arrivano i punti: barra impilata liberi / da 2 / da 3 in percentuale;
- elenco delle partite (V/S, punteggio, avversario, cliccabile);
- statistiche della rosa.

## 5. Confronto tra squadre
Calcola per ogni squadra queste metriche. La terza colonna dice se il valore è migliore alto, basso o neutro (profilo di gioco):
| Metrica | Calcolo | Meglio |
|---|---|---|
| Punti fatti / G | PF / G | alto |
| Punti subiti / G | PS / G | basso |
| Margine medio | (PF−PS)/G | alto |
| Triple / G | 3P segnati / partite con tabellino | alto |
| Canestri da 2 / G | 2P / partite con tabellino | alto |
| Liberi segnati / G | TL / partite con tabellino | alto |
| % punti da 3 | 3P×3 / punti da tabellino | neutro |
| % punti dai liberi | TL / punti da tabellino | neutro |
| Triple concesse / G | 3P degli avversari / partite con tabellino | basso |
| Liberi concessi / G | TL degli avversari / partite con tabellino (indicatore indiretto dei falli commessi) | basso |
| Punti nel 1° quarto | media | alto |
| Saldo 1° quarto | media (fatti − subiti) | alto |
| Saldo 4° quarto | media (fatti − subiti) | alto |
| Saldo 2° tempo | media (Q3+Q4 fatti − subiti) | alto |
| Marcatori a partita | giocatori con punti > 0, in media | alto |
| Dipendenza dal top scorer | punti del miglior marcatore / punti totali da tabellino | neutro |
| % vittorie punto a punto | vittorie / partite finite con scarto ≤ 10 | alto |

Regole: le metriche di tiro usano solo le partite in cui ENTRAMBE le squadre hanno il tabellino; le metriche dei quarti solo le partite con i parziali. Se non ci sono dati, mostra "–" (mai NaN o undefined).

Tre viste:
1. Classifica per la metrica scelta da un menu: barre orizzontali ordinate dal migliore, con la media del gruppo e la spiegazione della metrica. Le metriche di saldo usano barre divergenti dallo zero (verdi se positive, rosse se negative).
2. Testa a testa: due menu per scegliere le squadre e, per ogni metrica, i valori affiancati con barre speculari, in grassetto il migliore (le metriche neutre non hanno vincitore).
3. Tabella completa ordinabile: squadre in riga, metriche in colonna; cella verde per il migliore e rossa per il peggiore di ogni colonna (non per le metriche neutre).
- Casella "entrambi i gironi" per confrontare tutte le squadre del campionato.

## Note da mostrare nell'app
- "Il sito registra solo i canestri segnati: niente percentuali al tiro, rimbalzi, assist o falli."
- "Con poche partite giocate le medie sono indicative."
- In fondo a ogni pagina: link alla fonte e data/ora di aggiornamento.

## Grafica
- Stile da tabellone sportivo: banda scura in alto, colore d'accento arancione, Barlow Condensed per titoli e numeri, Inter per il testo (Google Fonts, con font di sistema come riserva), cifre allineate in colonna (font-variant-numeric: tabular-nums).
- Tutti i colori come variabili CSS, con tema chiaro e tema scuro (prefers-color-scheme).
- Deve funzionare su telefono (circa 400 px): le tabelle larghe scorrono dentro il proprio riquadro, mai la pagina intera.
- Grafici fatti con HTML/CSS (barre con div), senza librerie.

# CRITERI DI ACCETTAZIONE
1. Lo script gira senza errori e stampa il riepilogo per girone.
2. Per ogni partita con tabellino, la somma dei punti dei giocatori è uguale al punteggio finale (altrimenti compare un avviso).
3. La classifica nell'app è identica a quella del sito.
4. I quarti mostrati sono punti del singolo quarto e la loro somma è uguale al punteggio finale.
5. Nessuna cella mostra NaN, undefined o Infinity.
6. L'HTML si apre offline con doppio clic e funziona su desktop e telefono, in tema chiaro e scuro.
7. Per aggiornare i dati basta rilanciare lo script.

# AVVERTENZA PRIVACY
I tabellini contengono nomi di atleti minorenni (dati già pubblici sul sito UISP). Non pubblicare l'app su siti pubblici indicizzati: condividila solo con squadre e famiglie.
