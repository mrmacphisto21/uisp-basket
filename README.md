# Basket UISP Varese

App a pagina singola con risultati, classifiche, tabellini e confronti tra squadre di tutti i campionati
UISP Pallacanestro del comitato di Varese (dati da https://gestionalepallacanestro.uisp.it/Varese).

## Esecuzione automatica (GitHub Actions + Telegram)

Il workflow `.github/workflows/aggiorna.yml` gira **lunedì e giovedì alle 7:00** (ora italiana d'inverno):
scarica tutti i campionati → genera `Varese_Basket.html` → se ci sono risultati o tabellini nuovi la manda
su Telegram come file, con l'elenco delle novità nella didascalia. Se qualcosa va storto arriva
"❌ aggiornamento fallito". Si può lanciare a mano da **Actions → Basket UISP Varese → Run workflow**
(anche dal telefono, app GitHub o browser).

**Incrementale:** ogni giro riparte dai dati del giro precedente. Le giornate con tutte le partite dopo la fine
del mese corrente non vengono scaricate; per le partite già giocate si riscarica il tabellino solo se il punteggio
sul sito è cambiato o se il tabellino mancava (partite degli ultimi 60 giorni). Le pagine delle giornate del mese
si rileggono sempre, così risultati corretti o spostamenti di data vengono presi. Per riscaricare tutto da zero:
Run workflow con "Riscarica tutto da zero".

I campionati da scaricare si scelgono con la variabile del repo `CAMPIONATI` (id separati da virgola, es.
`1,6,9,10,12`; vuota = tutti): Settings → Secrets and variables → Actions → Variables.

I dati non vengono salvati nel repository: restano solo nella cache del workflow (per riconoscere le novità)
e nella pagina allegata in Actions per 30 giorni.

### Pagina con password (per aprirla da telefono, anche iPhone)
Ogni giro pubblica anche una versione **cifrata** della pagina su GitHub Pages
(`https://mrmacphisto21.github.io/uisp-basket/`), e il link arriva nel messaggio Telegram.
`cifra.ps1` comprime la pagina e la cifra con AES-256-GCM (chiave PBKDF2-SHA256 dalla password);
`sblocca.template.html` è la pagina che chiede la password e la decifra nel browser (WebCrypto).
Senza password chi apre il link vede solo il campo password. Il repository può essere pubblico:
contiene solo codice, mai dati.

Configurazione: secret `PAGINA_PASSWORD` + Settings → Pages → Source: **GitHub Actions**.
Per cambiare password basta aggiornare il secret: vale dal giro successivo (sul telefono va reinserita).

### Configurazione (una volta)
1. Su GitHub crea il repository `uisp-basket` (vuoto, senza README) e fai il primo push. Pubblico se vuoi
   il link con password su Pages (con l'account gratuito Pages funziona solo su repo pubblici).
2. **Settings → Secrets and variables → Actions → New repository secret**:
   - `TELEGRAM_BOT_TOKEN`: lo stesso bot dei segnali ETF va benissimo.
   - `TELEGRAM_CHAT_ID`: la chat dove mandare la pagina. Per mandarla anche al coach crea un gruppo
     Telegram con lui e il bot, scrivi un messaggio nel gruppo e usa l'id del gruppo (numero negativo).
3. **Actions → Basket UISP Varese → Run workflow** per la prima prova.

## In locale (Windows, PowerShell 7)
```
pwsh ./scrape.ps1                 # tutti i campionati, incrementale rispetto a data.json
pwsh ./scrape.ps1 -Full           # riscarica tutto da zero (~9 minuti)
pwsh ./scrape.ps1 -Camp 9,17      # solo alcuni campionati, per id
pwsh ./scrape.ps1 -BuildOnly      # rigenera la pagina da data.json senza scaricare
```

## File
- `scrape.ps1`: scarica i dati e genera la pagina partendo da `app.template.html`.
- `app.template.html`: l'app (HTML/CSS/JS, nessuna dipendenza oltre ai Google Fonts).
- `ISTRUZIONI_APP_UISP.md`: specifica completa per ricostruire l'app con un'altra AI.

## Privacy
La pagina contiene nomi e punteggi di giocatori, anche minorenni (già pubblici sul sito UISP).
I dati non sono mai nel repository; la pagina pubblicata è cifrata e va condivisa (link + password)
solo con chi serve. I log di Actions di un repo pubblico sono visibili: contengono nomi di squadre e
conteggi, non giocatori.
