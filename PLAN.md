# Rat Kebab – plan i postęp

Po każdym etapie zaktualizuj ten plik (krótko).

## Postęp
- [x] 0–6: gracz, interakcje, kebab, klienci, szczury i maszynka, noc, menu i pauza
- [x] 7: dźwięk, sprite'y, klienci specjalni, 3 noce, czynsz, finał, 3 niespodzianki
- [x] 8: rozmowy, imiona, notatnik i wołanie; awaria prądu; tekstury, detale, podwórko, otoczenie, menu
- [x] 9: poprawki po testach (dialogi i dymki, czcionka, ustawienia ekranu), porządki i optymalizacja
  (do sprawdzenia w grze)

## Tryby gry (na później – nie zaczynać bez prośby)
Obecne 3 noce to zalążek trybu **Fabuła**. Obok niego powstanie tryb **Endless**. W menu: wybór trybu.
- [ ] 10: wybór trybu w menu; skład nocy, czynsz i trudność zależne od trybu (dziś stałe w `game.gd`)
- [ ] 11: Endless
- [ ] 12: Fabuła (5 nocy)

### Endless
Noce bez końca, każda trudniejsza od poprzedniej. Koniec, gdy nie uzbierasz czynszu.
Propozycja skalowania (do ustalenia): co noc więcej klientów i krótsze przerwy, mniej cierpliwości,
wyższy czynsz (płacony co noc), częstsze awarie, szczury i sanepid, częściej ważna kolejność.
Z limitem, żeby noc dało się jeszcze przejść. Wynik: liczba nocy i zarobek, rekord zapisany na dysku.

### Fabuła (5 nocy)
Pomysł do akceptacji – **„Poprzedni sprzedawca”**. Zaczynasz po Mietku, który zniknął bez wypowiedzenia.
Co noc znajdujesz jego kartkę (w kuchni, przy bezpiecznikach, w altanie).
1. Pierwsza zmiana: nauka kebaba i notatnika. Kartka: „Nie włączaj radia przy maszynce”.
2. Pani od Pimpka wiesza plakat. Pierwsza awaria: kabel przegryziony zbyt równo.
3. Sanepid w przebraniu; sąsiadka Krystyna notuje każdy twój krok. Kartka: „Oni liczą szczury”.
4. Smakosz przyprowadza klub: duże pieniądze za wkładkę, ale Krystyna i sanepid są coraz bliżej.
   Wybór: szybki czynsz albo czyste ręce.
5. Noc kontroli: przychodzą wszyscy naraz i właściciel kamienicy po czynsz. Wychodzi na jaw, że Pimpek
   przewodzi szczurom z podwórka, a Mietek prowadzi teraz „konkurencję” za rogiem.

Finał zależy od czynszu, losu Pimpka, mandatów i podanych szczurów (rozbudowa obecnych zakończeń,
w tym sekretnego).

## Otwarte
- Poziom trudności w ustawieniach (czeka na decyzję; może zastąpi go Endless).

## Stan kodu
- Start: `Scenes/menu.tscn`. Gra: `Scenes/game.tscn`; stan i reguły w `Scripts/game.gd` (stałe na górze:
  skład nocy, czynsz, mandat, nagrody, awaria). Stan między nocami w `static var save` (do wyłączenia gry),
  nowa noc = przeładowanie sceny.
- Kuchnia: x od -3.95 do -2.3; blat x ≈ -1.35; sala: x > -0.9; podwórko: x -7..-1.2, z 5..13.
- Interakcja: warstwa kolizji 2; obiekt ma `get_prompt(player)` i `interact(player)`.
- Gracz: `held`, `hold(item)`, `discard()`, `busy` (rozmowa/notatnik); przedmioty: `Scripts/item.gd`.
- Kebab: `contents` = warstwy od dołu (`meat`, `salad`, `sauce`, `tortilla`, `rat`; max 10).
- Klient: `Scripts/customer.gd` (`ENTERING → WAITING ⇄ WALKING → EATING → FAREWELL → LEAVING`);
  rodzaje, cierpliwość i napiwek w stałej `TYPES`. Max 5 w środku, 3 miejsca przy ladzie + `pickup`, 4 krzesła.
  Zamówień nie ma w HUD ani nad głową – gracz zapisuje je w notatniku.
- Teksty, imiona i postacie: `Data/dialogi.json` (`Scripts/dialogs.gd`, opis `Data/JAK_EDYTOWAC.md`).
  Użytkownik sam edytuje plik – nie nadpisywać jego zmian.
- UI: `dialog_box` (odpowiedzi), `speech.gd` (kwestie nad głową, 2D), `notebook`, `hud`, `overlay`, `settings.gd`.
- Szczur: `Objects/rat.tscn` (strefy `yard`/`kitchen`/`sala`, markery `rat_areas`); max 2, inwazje na salę.
  Maszynka pod blatem uzupełnia `prep_station/source_meat`.
- Awaria: `Objects/fuse_box.tscn` + `fuse_shelf.tscn`; przyczyny: kabel (noce 2–3) albo radio + maszynka.
- Wystrój i otoczenie budowane w kodzie (`@tool`): `build.gd` (klocki, wspólne siatki), `decor.gd`,
  `outdoors.gd`, `backyard.gd`, `dumpster.gd`.
- Obraz: `night.gd` (barwa sprite'ów, awaria), filtr `Scenes/pixel_filter.tscn` (`pixel_size`, `levels`),
  niebo `Materials/night_env.tres`, czcionka `Materials/serif.tres`.
- Generatory grafik i dźwięków (tylko lokalnie): `.godot/claude_test/gen_world.py`, `gen_assets.py`.

## Projekt rozgrywki
Bez autoloadów i managerów; sygnały w górę, wywołania w dół.
Ocena: 20 zł (+5 za podwójne mięso), −8 zł za błąd, bez mięsa 0; napiwek za bezbłędne i szybkie.
**Nie robić:** ekwipunek, rozbudowana ekonomia, zapis w środku nocy.

## Z dawnej listy „Później” – niezrobione
- Skale stołów i krzeseł; mipmapy dla tekstur restauracji.
- Sprawdzanie miejsca nad głową przy wstawaniu z kucek.
- Zaplecze jako kryjówka szczura (stara scena `zapl` usunięta; w razie potrzeby zbudować od nowa).

## Spoilery (niespodzianki)
1. Radio w kuchni (muzyka i wiadomości); muzyka gra też w menu.
2. Złoty szczur od 2. nocy: szybszy, po zmieleniu +50 zł.
3. Sekretny finał „Złoty Kebab”: czynsz, oddany Pimpek, zero mandatów i zero niezamówionych szczurów.
