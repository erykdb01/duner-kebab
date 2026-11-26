# Rat Kebab – plan i postęp

Po każdym etapie zaktualizuj ten plik (krótko).

## Postęp
- [x] 0: gracz, Input Map, blokady drzwi (celowe), nocne światło
- [x] 1: celowanie, podpowiedź HUD, branie i odkładanie
- [x] 2: składniki, deska, kebab, kosz (wygląd do sprawdzenia przez użytkownika)
- [x] 3: klient przy ladzie, zamówienie, ocena, kasa (mięso bez limitu; do sprawdzenia w grze)
- [x] 4: szczur i maszynka (do sprawdzenia w grze)
- [x] 5: kolejka klientów (pary, kolejni mimo nieobsłużonych), krzesła (max 4), jedzenie, opinia, wyjście;
  dowolne warstwy w kebabie, zamówienia z ilością i kolejnością, swoboda ze szczurem (do sprawdzenia w grze)
- [x] 5b: śmietnik za kuchnią, szczury zakradające się na salę, maszynka pod blatem, czas zamówień w HUD
  (do sprawdzenia w grze)
- [x] 6: noc, tabliczka „OTWARTE”, podsumowanie, restart, menu i pauza; długi kontener na podwórku
  ze szczurami i słabym światłem pod spodem (do sprawdzenia w grze)
- [x] 7a: klienci specjalni (sanepid, smakosz, właścicielka Pimpka, student, babcia), opinie w podsumowaniu,
  czynsz, awaria prądu, 3 noce i finał (do sprawdzenia w grze)
- [x] 7b: dźwięk, wygenerowane efekty w `Sounds/` (do sprawdzenia w grze)
- [x] 7c: nowe sprite'y klientów i szczurów (do sprawdzenia w grze)
- [x] niespodzianki (3) – opis w sekcji „Spoilery” na końcu pliku

## Etap 8 (lista użytkownika po teście etapu 7)
- [x] 8a: przyjmowanie zamówień w rozmowie, imiona, notatnik (Tab), wołanie po imieniu (Q), wybór odpowiedzi,
  różni klienci, dużo dialogów w `Data/dialogi.json`, pauza przed wyjściem (do sprawdzenia w grze)
- [x] 8b: awaria prądu: ciemno (latarka F), grill i maszynka stoją, mięso się psuje, cierpliwość x2;
  naprawa: bezpiecznik z kuchni do skrzynki na podwórku. Przyczyny: kabel (noce 2-3) albo radio + maszynka.
  Radio uspokaja klientów (x0,7). (do sprawdzenia w grze)
- [x] 8c: nowe tekstury 128 px, 18 wyglądów klientów, nowe szczury, sos, filtr pikselowy (do sprawdzenia)
- [x] 8d: detale restauracji, wyposażony blat, ekrany z menu, okna; kosz w kuchni i kontener w kątach
  (do sprawdzenia)
- [x] 8e: altana i podwórko od nowa, brama z widokiem na ulicę, otoczenie lokalu, niebo (do sprawdzenia)
- [x] 8f: nowe menu z widokiem na lokal (do sprawdzenia)

## Uwagi po teście etapu 3
- Sos w kebabie: poprawiony (do sprawdzenia).
- Kilku klientów naraz: etap 5; limit osób w lokalu, osobne zamówienie i cierpliwość każdego.
- Sprite klienta nie pasuje do klimatu: etap 7 (styl postaci i szczura ustalić wtedy, szukać inspiracji).

## Stan kodu
- `Scenes/game.tscn`: restauracja, gracz, `prep_station` (x = -1.35, y = 1.095), kosz, HUD.
- Kuchnia: x od -3.95 do -2.3; blat x ≈ -1.35; sala: x > -0.9.
- Interakcja: warstwa kolizji 2; obiekt ma `get_prompt(player)` i `interact(player)`.
- Gracz: `held`, `hold(item)`, `discard()`; podnoszone przedmioty używają `Scripts/item.gd`.
- Kebab: `contents` = warstwy od dołu (`meat`, `salad`, `sauce`, `tortilla`, `rat`; max 10); grupa `trashable`.
- `game.gd`: `money`, noc = 9 klientów (grupy co 22-38 s, max 5 w środku), przydział `counter_slots` (3)
  i `seats` (4); trasa klientów: `customer_route` (street, door); lista zamówień z czasem w HUD.
  Noc startuje z `open_sign` (przy drzwiach frontowych); inwazje szczurów dopiero po otwarciu.
- Start gry: `Scenes/menu.tscn`. `Scenes/overlay.tscn` (w `game.tscn`): pauza (Esc) i podsumowanie nocy.
- Kontener: `Objects/dumpster.tscn` (prześwit ok. 0,5 m; szczura głębiej pod spodem łatwiej złapać w kucki).
- Szczury: max 2, nowy po 20 s; co 45-90 s jeden idzie `invasion_route` na salę (12 s na złapanie,
  wypuszczony na sali: 2 s), potem klienci wychodzą.
- Podwórko: `Objects/backyard.tscn` (płot, worki, światła), drzwi z kuchni `wallBack/doorKitchen` (x ≈ -3.1);
  stare tylne drzwi na sali nadal zablokowane.
- Klient: `Objects/customer.tscn` (`ENTERING → WAITING → TO_SEAT → EATING → REVIEWING → LEAVING`);
  rodzaj w `Customers/*.tres` (`Scripts/customer_type.gd`: kind, sprite'y, cierpliwość, napiwek).
- Teksty, imiona i postacie: `Data/dialogi.json` (czyta `Scripts/dialogs.gd`). UI: `Scenes/dialog_box.tscn`,
  `Scenes/notebook.tscn`; `player.busy` blokuje ruch. Zamówień nie ma w HUD ani w dymkach.
- Noce: skład kolejki, czynsz, mandat, nagrody i awaria jako stałe na górze `game.gd`; stan między nocami
  w `static var save` (znika po wyłączeniu gry), nowa noc = przeładowanie sceny.
- Nowe obiekty: `fuse_box` (podwórko, przy drzwiach z kuchni), `poster` (ściana frontowa), `radio`.
- Dźwięk: `Scripts/sfx.gd`. Sprite'y i dźwięki robi `.godot/claude_test/gen_assets.py`
  (tylko lokalnie; nie nadpisuje istniejących plików).
- Wystrój i otoczenie budowane w kodzie (`@tool`): `Scripts/build.gd` (klocki), `decor.gd`, `outdoors.gd`,
  `backyard.gd`, `dumpster.gd`. Tekstury: `Textures/swiat`, `postacie`, `szczury` (generator
  `.godot/claude_test/gen_world.py`).
- `Scripts/night.gd`: stan awarii i barwa sprite'ów. Filtr pikseli: `Scenes/pixel_filter.tscn`
  (`pixel_size`, `levels`). Niebo i mgła: `Materials/night_env.tres`.
- Nieużywane (do usunięcia po akceptacji): w `Textures/` pliki `customer.png`, `rat.png`, `npc_*`,
  `food_*`, `szczur_*`, `pimpek_*`, `zloty_*`, `plakat_pimpek.png`.
- Szczur: `Objects/rat.tscn` (grupy `rat`, `trashable`; strefy `yard`/`kitchen`/`sala`, markery `rat_areas`);
  maszynka: `Objects/grinder.tscn` na dolnej półce blatu.
- Mięso: `stock` na `prep_station/source_meat` (start 3), uzupełnia `game.gd` po zmieleniu.
- Materiały w `Materials/`, tekstury jedzenia 16×16 (ok. 64 px/m, filtr nearest).

## Projekt rozgrywki (etapy 3–7)
Bez autoloadów i managerów; stan gry w `game.gd`; sygnały w górę, wywołania w dół.

**Klient:** `Node3D` + `Sprite3D` (billboard Y, nearest), ruch `move_toward` po `Marker3D`.
Stany: `ENTERING → WAITING → TO_SEAT → EATING → REVIEWING → LEAVING`.
Przy ladzie jeden naraz, max 4 miejsca. Cierpliwość ok. 60 s, w połowie narzeka, po czasie wychodzi bez płacenia.
Typy w `CustomerType` (`.tres`: sprite, cierpliwość, napiwek, teksty). Dymek: `Label3D`; zamówienie także w HUD.

**Ocena:** baza 20 zł, −40% bazy za każdy zły lub brakujący dodatek; bez mięsa lub pusty = 0 zł;
napiwek +5 zł za bezbłędny przy > 50% cierpliwości. HUD: „+X zł” i stan kasy.

**Szczur:** `WANDER → FLEE` (gracz < 2 m) `→ HELD`; markery, bez navmesha; ok. 3 m/s z przerwami.
Maszynka daje 3 porcje mięsa, komicznie, bez gore; nowy szczur po ok. 20 s.

**Noc:** lista ok. 6 klientów (4–5 min), zegar 22:00–04:00 dekoracyjny, podsumowanie. Potem 3 noce i finał.

**Później:** wspólne materiały restauracji (filtr Nearest Mipmap), skale stołów i krzeseł, okna i otoczenie,
migocząca świetlówka, zaplecze `zapl` jako kryjówka szczura (kucanie ok. 0,9 m + sprawdzanie miejsca).

**Pomysły:** Sanepid, podanie żywego szczura, absurdalni klienci, plakat „Zaginął szczur”, radio.
**Nie robić:** ekwipunek, ekonomia, psucie składników, drzewka dialogowe, zapis w środku nocy.

## Spoilery (niespodzianki dodane w etapie 7)
1. Radio w kuchni (muzyka i wiadomości); muzyka gra też w menu.
2. Złoty szczur od 2. nocy: szybszy, po zmieleniu +50 zł.
3. Sekretny finał „Złoty Kebab”: czynsz, oddany Pimpek, zero mandatów i zero niezamówionych szczurów.

## Do poprawy później
- Poprawki po teście etapu 8 zrobione (do sprawdzenia): dialogi z pasującymi odpowiedziami, „Co?” i
  wyproszenie; kwestie klienta nad głową (`Scripts/speech.gd`, 2D), w oknie tylko odpowiedzi gracza;
  słabszy filtr; czcionka szeryfowa z systemu (`Materials/serif.tres`); bez tylnych drzwi sali
  i tabliczki na bramie.
- Ustawienia (rozdzielczość, pełny ekran) w menu i pauzie: `Scripts/settings.gd` (do sprawdzenia).
- Dialogi przepisane na bardziej życiowe i rozbudowane (ok. 130 rozmów); rozmowy własne i wspólne na
  przemian, bez powtórek w nocy (do oceny w grze). Użytkownik sam edytuje `Data/dialogi.json` – nie
  nadpisywać jego zmian.
- Czeka na decyzję: poziom trudności.
