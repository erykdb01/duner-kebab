# Rat Kebab – plan i postęp

Po każdym etapie zaktualizuj ten plik (krótko). Wersja 1 projektu: tag `v1.0` (2026-11-27).

## Postęp (do wersji 1)
- [x] 0–9: gracz, kebab, klienci, szczury i maszynka, 3 noce i finał, rozmowy i notatnik, detale, menu, ustawienia

## Wersja 2 – etapy (po każdym stop i test użytkownika)
- [x] **E1 Drobne poprawki** (sprawdzone w grze; potem deska przeniesiona sama na dół): dłuższe noce (480 s, 11/13/15 klientów, czynsz 500);
  bez „wkładki”; usunięta awaria prądu i bezpieczniki; radio bez wpływu na klientów; szare okna; deska
  na niższej części blatu (pojemniki na górze); klienci siedzą wyżej; rzadsze wejścia szczurów (co 140–240 s);
  usunięte rysunki `Textures/postacie`; naprawione przypadkowe przesunięcie węzła `rest` w `game.tscn`.
- [x] **E2 Ulica i radio** (do sprawdzenia w grze): ciemniej na zewnątrz (`night_env`, latarnie,
  materiały w `outdoors.gd`); 2 auta na trasach `ROUTES` w `outdoors.gd` (zaparkowane usunięte);
  radio: 4 stacje (`STATIONS` w `radio.gd`) i pokrętło `radio_knob.gd`.
- [x] **E3 Dymki i dialogi od zera** (do sprawdzenia w grze): sam tekst z obrysem (`speech.gd`); nowy
  `dialogi.json` (wspólna pula w `domyslne`, charakterystyczni: babcia, student, gbur, gaduła,
  teoretyk, poeta, smakosz, pani od Pimpka); usunięte „Co?”; wyproszenie dopasowane do kwestii
  (`wypros`) lub losowe; odpowiedzi gracza obok klienta (`dialog_box.gd`, styl jak dymki, szary
  gradient); światło z wejścia (dodatek do E2). Użytkownik po teście zgłosi poprawki kwestii.
- [x] **E4 Klienci od zera** (do sprawdzenia w grze; pytanie o imię dopiero po zamówieniu): ok. 20 zwykłych (wspólna pula dialogów, losowe zdjęcia) i kilku
  charakterystycznych (np. babcia) z własnymi kwestiami; zdjęcia użytkownika z `Textures/zdjecia/`,
  przycinane do kwadratu i lekko pikselizowane (mogą się powtarzać). Zdjęcia zostają losowane według
  płci także dla postaci charakterystycznych (np. gbur może wyglądać jak poeta) – **nie zmieniać**; dłuższa cierpliwość w kolejce,
  narzekanie przy długim czekaniu; po zbyt wielu pytaniach lub utracie cierpliwości wychodzą.
  **Sanepid:** losowy zwykły klient bez żadnych oznak; mandat, gdy będąc w lokalu zobaczy szczura
  (choćby na chwilę) albo dostanie żywego szczura w kebabie.
- [x] **E5 Przygotowanie przed otwarciem** (do sprawdzenia w grze): start bez mięsa (resztki
  przechodzą na kolejną noc), odliczanie `PREP_TIME` 4 min; tabliczka otwiera wcześniej, po czasie
  lokal otwiera się sam i wchodzą 2 grupy po 3 osoby (`RUSH_*`). Zamówienia wymieniają tylko to,
  co ma być w środku.
- [x] **E6 Kanały i walka** (do sprawdzenia w grze): właz w altanie (`sewer.gd`, tunel w x=80),
  nóż, turowa walka (`battle.gd`, stałe na górze); truchła w liczniku gracza, maszynka 1 szczur =
  1 porcja; złoty szczur tylko w kanałach. Po tłoku: +2 klientów (`RUSH_EXTRA`, miejsca c3, c4).
  Na podwórku zostają Pimpek i 1 żywy szczur (odnawia się po 90 s) – do decyzji w E7.
  **Przypomnij użytkownikowi o ocenie tempa** (ok. 20 szczurów na noc).
- [ ] **E7 Żywy szczur:** minigra QTE (sekwencja klawiszy), trudniejsza od walki; worek; Pimpek;
  klient po cichu prosi o żywego szczura w kebabie.
- [ ] **E8 Porządki i balans:** audyt nieużywanych plików, optymalizacja, czynsz i liczby po testach,
  aktualizacja menu „Sterowanie”, `README.md`, `Data/JAK_EDYTOWAC.md`.

## Ustalone (2026-11-27)
- E5: na przygotowanie 4 min realnego czasu (stała w kodzie).
- E6: walka 10–20 s, w jednej walce 1–3 szczury, niezużyte mięso przechodzi na następną noc.
  **Przypomnij użytkownikowi po teście E6**, że to wersja próbna: ocenić tempo (ok. 20 szczurów na noc
  przy 11–15 klientach) i ewentualnie zmienić.
- E6/E7: szczury nadal rzadko wchodzą na salę i da się je złapać ręką.
- E7: zamiast awarii prądu maszynka czasem się zacina i trzeba ją odetkać krótkim QTE (na próbę).
- Gra jest tylko dla użytkownika – prawami do zdjęć się nie zajmujemy.
- `diagramy/` – nigdy nie ruszać.

## Tryby gry (na później – nie zaczynać bez prośby)
Obecne 3 noce to zalążek trybu **Fabuła**. Obok niego powstanie **Endless**; w menu wybór trybu.
- Endless: noce bez końca, każda trudniejsza (więcej klientów, mniej cierpliwości, wyższy czynsz co noc,
  częstsze szczury i sanepid); koniec, gdy nie uzbierasz czynszu; rekord na dysku.
- Fabuła (5 nocy), pomysł **„Poprzedni sprzedawca”** (do akceptacji): zaczynasz po Mietku, który zniknął;
  co noc znajdujesz jego kartkę (np. „Oni liczą szczury”). Pani od Pimpka, sanepid, klub smakosza
  i wybór: szybki czynsz albo czyste ręce. Finał: Pimpek przewodzi szczurom, Mietek prowadzi konkurencję.

## Stan kodu
- Start: `Scenes/menu.tscn`. Gra: `Scenes/game.tscn`; stan i reguły w `Scripts/game.gd` (stałe na górze).
  Stan między nocami w `static var save`, nowa noc = przeładowanie sceny.
- Kuchnia: x od -3.95 do -2.3; blat: góra (lada) x ≈ -1.35, niższa część y 0.827, x ≈ -2.06
  (deska `prep_station`, maszynka); sala: x > -0.9; podwórko: x -7..-1.2, z 5..13.
- Interakcja: warstwa kolizji 2; `get_prompt(player)` i `interact(player)`.
- Gracz: `held`, `hold(item)`, `discard()`, `busy`; latarka [F].
- Kebab: `contents` = warstwy od dołu (`meat`, `salad`, `sauce`, `tortilla`, `rat`; max 10).
- Klient: `Scripts/customer.gd` (`ENTERING → WAITING ⇄ WALKING → EATING → FAREWELL → LEAVING`), stała
  `TYPES`. Max 5 w środku, 3 miejsca przy ladzie + `pickup`, 4 krzesła. Zamówienia gracz zapisuje sam.
- Zdjęcia: kwadraty, losowane według płci (`PHOTOS` w `customer.gd` i foldery
  `Textures/zdjecia/zwykli/m|k`); zwykłe klientki tylko, gdy są zdjęcia w `zwykli/k`.
  Zwykli klienci (losowe imię i zdjęcie) i sanepid nie mają postaci w `dialogi.json`.
- Kolejka (`_update_queue`) spowalnia utratę cierpliwości; irytacje (`_annoy`, `nerwy`) wyganiają.
- Teksty: `Data/dialogi.json` (`Scripts/dialogs.gd`).
- Żywy szczur: `Objects/rat.tscn`; max 2 na górze, wejścia na salę. Mięso: kanały i maszynka.
- Miejsca w kodzie pod [E]: `hotspot.gd`.
- Wystrój i otoczenie w kodzie (`@tool`): `build.gd`, `decor.gd`, `outdoors.gd`, `backyard.gd`.
- Obraz: `night.gd` (barwa sprite'ów), `Scenes/pixel_filter.tscn`, `Materials/night_env.tres`.
- Generatory grafik i dźwięków (tylko lokalnie): `.godot/claude_test/gen_world.py`, `gen_assets.py`.

## Zasady rozgrywki
Bez autoloadów i managerów; sygnały w górę, wywołania w dół.
Ocena: 20 zł (+5 za podwójne mięso), −8 zł za błąd, bez mięsa 0; napiwek za bezbłędne i szybkie.
Ekwipunek tylko jako licznik truchł i worek (E6–E7). Nie robić: rozbudowana ekonomia, zapis w środku nocy.

## Niespodzianki (spoilery)
1. Radio w kuchni (stacje, muzyka i wiadomości). 2. Złoty szczur w kanałach od 2. nocy: +50 zł.
3. Finał „Złoty Kebab”: czynsz, oddany Pimpek, zero mandatów i niezamówionych szczurów.
