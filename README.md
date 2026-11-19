# Basket UISP Varese

App a pagina singola con risultati, classifiche, tabellini e confronti tra squadre di tutti i campionati
UISP Pallacanestro del comitato di Varese (dati da https://gestionalepallacanestro.uisp.it/Varese).

## Esecuzione automatica (GitHub Actions + Telegram)

Il workflow `.github/workflows/aggiorna.yml` gira **lunedì e giovedì alle 7:00** (ora italiana d'inverno):
scarica tutti i campionati → genera `Varese_Basket.html` → se ci sono risultati o tabellini nuovi la manda
su Telegram come file, con l'elenco delle novità nella didascalia. Se qualcosa va storto arriva
"❌ aggiornamento fallito". Si può lanciare a mano da **Actions → Basket UISP Varese → Run workflow**
(anche dal telefono, app GitHub o browser).

I dati non vengono salvati nel repository: restano solo nella cache del workflow (per riconoscere le novità)
e nella pagina allegata in Actions per 30 giorni.

### Configurazione (una volta)
1. Su GitHub crea il repository **privato** `uisp-basket` (vuoto, senza README) e fai il primo push.
2. **Settings → Secrets and variables → Actions → New repository secret**:
   - `TELEGRAM_BOT_TOKEN`: lo stesso bot dei segnali ETF va benissimo.
   - `TELEGRAM_CHAT_ID`: la chat dove mandare la pagina. Per mandarla anche al coach crea un gruppo
     Telegram con lui e il bot, scrivi un messaggio nel gruppo e usa l'id del gruppo (numero negativo).
3. **Actions → Basket UISP Varese → Run workflow** per la prima prova.

## In locale (Windows, PowerShell 7)
```
pwsh ./scrape.ps1                 # tutti i campionati (~9 minuti)
pwsh ./scrape.ps1 -Camp 9,17      # solo alcuni campionati, per id
pwsh ./scrape.ps1 -BuildOnly      # rigenera la pagina da data.json senza scaricare
```

## File
- `scrape.ps1`: scarica i dati e genera la pagina partendo da `app.template.html`.
- `app.template.html`: l'app (HTML/CSS/JS, nessuna dipendenza oltre ai Google Fonts).
- `ISTRUZIONI_APP_UISP.md`: specifica completa per ricostruire l'app con un'altra AI.

## Privacy
La pagina contiene nomi e punteggi di giocatori, anche minorenni (già pubblici sul sito UISP).
Repository privato, e la pagina va condivisa solo con chi serve.
