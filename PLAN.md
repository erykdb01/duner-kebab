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
- [ ] 5b: zaplecze (patrz niżej)
- [ ] 6: noc, tabliczka „OTWARTE”, podsumowanie, restart, menu i pauza
- [ ] 7: dźwięk, sprite'y, klienci specjalni, 3 noce, finał

## Etap 5b: zaplecze (zgłoszone po etapie 4)
- Śmieci z tyłu (jest `Scenes/smieci.tscn`, tylne drzwi zablokowane): stamtąd gracz bierze szczury.
- Czasem szczur wchodzi na salę; trzeba go złapać, zanim zobaczą klienci (reakcja klientów).
- Maszynka w miejscu niewidocznym dla klientów (ścianka lub zaplecze).
- Reakcja klientów także na szczura wypuszczonego na sali.

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
- `game.gd`: `money`, grupy klientów co 15-28 s (max 5 w środku), przydział `counter_slots` (3) i `seats` (4),
  respawn szczura 20 s po zniknięciu; trasa: `customer_route` (street, door).
- Klient: `Objects/customer.tscn` (`ENTERING → WAITING → TO_SEAT → EATING → REVIEWING → LEAVING`,
  `patience` 75 s), sprite tymczasowy (losowy odcień). `CustomerType` dopiero w etapie 7.
- Szczur: `Objects/rat.tscn` (grupy `rat`, `trashable`; `release(point)`), markery `rat_points`;
  maszynka: `Objects/grinder.tscn`.
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
