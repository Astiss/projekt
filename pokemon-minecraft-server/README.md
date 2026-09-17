# Pokemon Minecraft Server (Cobblemon + Fabric)

Serwer Minecraft z modem [Cobblemon](https://modrinth.com/mod/cobblemon) (Pokemony), skonfigurowany
tak, by dzialac **bez konta premium** (kompatybilny z TLauncher / kontami "cracked") dzieki
`online-mode=false` w `server.properties`.

Uzyty mod jest darmowy i open-source, a serwerowy `.jar` Minecrafta pobierany jest oficjalnie
z serwerow Mojanga przez instalator Fabric - to w pelni legalny sposob hostowania serwera.
Ten pakiet **nie zawiera** i nie instaluje zadnego pirackiego/crackowanego klienta Minecrafta -
zakladamy, ze TLauncher juz masz zainstalowany.

## Dlaczego nie mogłem tego uruchomić za Ciebie

Pracuje w izolowanym, tymczasowym kontenerze w chmurze, ktory nie ma dostepu do internetu poza
kilkoma zaufanymi domenami (npm, GitHub itd.) - nie moge stad pobrac plikow z fabricmc.net ani
modrinth.com, wiec nie moge tu postawic i przetestowac serwera. Dlatego przygotowalem gotowe
skrypty, ktore **Ty uruchamiasz lokalnie, na swoim komputerze**, gdzie masz pelny dostep do sieci.

## Wymagania

- **Java 17** (Temurin): https://adoptium.net/temurin/releases/?version=17
- Windows: PowerShell (wbudowany) / Linux, macOS: `bash`, `curl`, `jq`
- Minimum 4 GB wolnego RAM-u dla serwera (Cobblemon jest dosc ciezki)

## Instalacja

### Windows

1. Skopiuj caly folder `pokemon-minecraft-server` na dysk (np. `C:\PokemonServer`).
2. Otworz PowerShell w tym folderze (Shift + prawy klik -> "Otworz okno PowerShell tutaj").
3. Uruchom:
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   .\setup.ps1
   ```
4. Po zakonczeniu uruchamiaj serwer klikajac `start.bat`.

### Linux / macOS

```bash
chmod +x setup.sh
./setup.sh
./start.sh
```

## Pierwsze uruchomienie

Po starcie serwer wygeneruje swiat (moze to potrwac kilka minut przy pierwszym starcie,
Cobblemon generuje dodatkowe struktury). W konsoli zobaczysz `Done!` gdy bedzie gotowy.

## Polaczenie z TLauncher

1. Otworz TLauncher, ustaw wersje Minecrafta na **1.20.1** (Fabric).
2. Jesli grasz na dodatkowe konto bez logowania Microsoft - TLauncher robi to automatycznie,
   a serwer akceptuje takie polaczenia dzieki `online-mode=false`.
3. Dodaj serwer: `Multiplayer -> Add Server -> Server Address: localhost` (jesli grasz na tym
   samym komputerze) albo Twoje IP lokalne (jesli znajomi laczy sie z tej samej sieci).
4. **Klient (TLauncher) tez potrzebuje moda Cobblemon** zeby cokolwiek dzialalo poprawnie -
   zainstaluj Fabric Loader 1.20.1 + wrzuc te same pliki z folderu `mods/` (Cobblemon,
   Fabric API) do folderu `.minecraft/mods` w profilu TLaunchera. Mozesz to zrobic recznie
   albo przez launcher modow (np. w TLauncher jest zakladka "Mods").

## Gra ze znajomymi przez internet

Domyslnie serwer dziala tylko w Twojej sieci lokalnej. Zeby znajomi mogli dolaczyc spoza sieci:

- **Port forwarding**: w ustawieniach routera przekieruj port `25565` (TCP) na komputer,
  na ktorym stoi serwer, a znajomi laczcie sie przez Twoje publiczne IP.
- albo prostsza opcja: usluga tunelujaca typu **playit.gg** (darmowa, bez zmian w routerze) -
  jesli chcesz, moge dopisac konfiguracje pod to.

## Pliki w tym folderze (po instalacji)

- `fabric-server-launch.jar` - launcher serwera Fabric
- `server.jar` - oryginalny jar Minecrafta (Mojang)
- `mods/` - Cobblemon + Fabric API
- `server.properties` - konfiguracja (kluczowe: `online-mode=false`, `enforce-secure-profile=false`, `white-list=false`)
- `eula.txt` - akceptacja EULA Minecrafta
- `start.bat` / `start.sh` - uruchomienie serwera

## Wylaczenie whitelisty / logowania na juz dzialajacym serwerze

Jesli serwer juz stoi i chcesz recznie wylaczyc whiteliste oraz wymog logowania (bez
ponownego uruchamiania `setup.ps1`):

1. W konsoli serwera wpisz `whitelist off` (od razu wylacza bez restartu).
2. Zatrzymaj serwer (`stop`), otworz `server.properties` i ustaw:
   ```
   white-list=false
   online-mode=false
   enforce-secure-profile=false
   ```
3. Uruchom serwer ponownie (`start.bat` / `start.sh`).

Od tej pory kazdy gracz z kontem non-premium (np. TLauncher) moze wejsc bez zapraszania go
na liste.

## Konfiguracja Cobblemon

Po pierwszym uruchomieniu w `config/cobblemon/` pojawia sie pliki konfiguracyjne moda
(spawn rate Pokemonow, trudnosc, itp.) - mozesz je edytowac i zrestartowac serwer, zeby
zmiany zadzialaly.
