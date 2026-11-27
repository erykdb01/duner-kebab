# Rat Kebab – plan, historia i stan

Po każdym etapie zaktualizuj ten plik (krótko). Zasady pracy są w `CLAUDE.md` – obowiązują zawsze.

## 1. Start nowej sesji – przeczytaj najpierw
- **Gdzie jesteśmy:** wersja 2 skończona i otagowana `v2.0` (E1–E8, balans i wygląd zaakceptowane).
  Ostatnia zmiana (zdrowie na noc, leczenie kebabem, pasek postępu) weszła do tagu **przed testem
  użytkownika**. Kolejne prace tylko na nową prośbę.
- **Jak pracujemy:** po polsku i krótko; jeden etap naraz, potem stop i test użytkownika; mówić, co
  zrobione i jak to sprawdzić. Własne uwagi zgłaszać zawsze: dlaczego i co zamiast tego.
- **Nie robić bez prośby:** commit/push (użytkownik często commituje sam), uruchamianie gry i testów,
  zrzuty ekranu. Edytować pliki po jednym (bez skryptów nadpisujących).
- **Nigdy nie ruszać** `diagramy/`.
- Żaden agent nie uruchamiał gry w wersji 2 – błędy zgłasza użytkownik (wkleja je z debuggera Godota).
  Sprawdzenie skryptów przez `godot --headless` wymaga jego zgody (zaproponowane, jeszcze bez odpowiedzi).

## 2. Repozytorium
- Gałąź `dev/eryk` (`main` jest stary). Tag `v1.0` (commit `5e4f4c7`, 2026-11-27) = wersja 1 projektu,
  stan sprzed zmian wersji 2. Agent niczego nie wypychał na GitHub.
- `v1.0` zawiera błąd: przypadkowo przesunięty węzeł `rest` w `Scenes/game.tscn` (naprawione w E1).
- Commity po tagu: `e9af65d` (E1, agent), dalsze robił użytkownik (m.in. `kanaly, walka, szczury`);
  tag `v2.0` = wersja 2 (commit agenta, 2026-11-27). Tagów agent nie wypychał.

## 3. Do zrobienia
- [ ] **Test ruchomych zdjęć:** `zwykli/m/mammon_anim.png` (losowe, z GIF-a). Obsługa w
  `customer.gd` (`ANIM_*`, `MUSIC_*`). Oryginalne GIF i MP4 usunięte na prośbę użytkownika.
- [ ] **Test Kaseko:** postać `kaseko` (`Textures/zdjecia/kaseko_anim.png` + `.ogg`), co noc,
  50% szans na drugą wizytę (`game.gd`), gigant 10 składników, 35 zł + 5 za mięso ponad 1,
  cierpliwość 150 s, napiwek 15 zł. Radio cichnie przy jego muzyce (`radio.gd`, `DUCK_*`).
- [ ] **Test dźwięku:** suwaki w ustawieniach (ogólna, muzyka); szyny w `default_bus_layout.tres`.
- [ ] **Test:** zdrowie przez całą noc, leczenie kebabem [G], pasek postępu; najlepiej pełne 3 noce.
- [x] Usunięte za zgodą stare pliki robocze z `.godot/claude_test/` (zostały tylko generatory).
- [ ] Użytkownik ma zgłosić poprawki **kwestii w dialogach** (po grze z nowymi dialogami).
- [ ] Opcjonalnie dorzuci zdjęcia do `Textures/zdjecia/zwykli/m|k` (bez zdjęć w `k` nie ma zwykłych klientek).
- Na później (tylko na prośbę): tryby gry – patrz punkt 8.

## 4. Wersja 2 – co zrobiono (sesja 2026-11-27)
Źródło: lista życzeń użytkownika; drobne poprawki najpierw, potem coraz większe etapy.

- [x] **E1 Drobne poprawki:** dłuższe noce (zegar 480 s); usunięta „wkładka” (dialogi, ekran nad ladą,
  radio); usunięta awaria prądu i bezpieczniki; radio bez wpływu na klientów; szare okna; **tylko deska**
  na niższej części blatu (pojemniki zostają na ladzie – tak chciał); klienci siedzą wyżej; rzadsze
  wejścia szczurów; usunięte wygenerowane rysunki postaci; naprawiony węzeł `rest`.
- [x] **E2 Ulica i radio:** ciemniej na zewnątrz; 2 wolne auta ze światłami; 4 stacje radia i pokrętło;
  na prośbę: ciepłe światło z wnętrza przed wejściem.
- [x] **E3 Dymki i dialogi od zera:** dymki bez tła (tekst z obrysem); nowy `dialogi.json`; bez „Co?”;
  wyproszenie dopasowane do kwestii lub losowe; odpowiedzi gracza przyczepione obok klienta
  (styl dymków, szary gradient) – zaakceptowane.
- [x] **E4 Klienci od zera:** zwykli (losowe imię i zdjęcie, wspólna pula tekstów) i charakterystyczni;
  kwadratowe pikselowe zdjęcia; kolejka wydłuża cierpliwość i wywołuje narzekanie; nerwy → wyjście;
  ukryty sanepid; pytanie o imię dopiero po zamówieniu; zamówienie wymienia tylko to, co ma być.
- [x] **E5 Przygotowania:** start bez mięsa, 4 min do otwarcia, potem tłum (+2 dodatkowych klientów).
- [x] **E6 Kanały i walka:** właz w altanie, tunel, turowa walka, truchła, 1 szczur = 1 porcja.
- [x] **Poprawki po E6:** walka trudniejsza; losowe krzesła; na górze mieszka tylko Pimpek; wstęp przed
  1. nocą z pominięciem.
- [x] **E7 Żywy szczur:** worek (minigra), klawisz [R], ciche zamówienia, zacinająca się maszynka.
- [x] **Po testach E7:** naprawiony błąd startu (`battle.gd` układał ekran przed jego zbudowaniem);
  nowy wygląd walki (poprzedni – narysowana ręka i gładkie GUI – nie pasował do klimatu gry).
  Użytkownik zaakceptował wygląd i balans.
- [x] **Dodatki po akceptacji:** wielki szczur w kanałach (`BIG_CHANCE`, więcej zdrowia, 3 porcje,
  nie mieści się w worku); Pimpek przeniesiony do kanałów (można z nim walczyć albo złapać do worka);
  naprawione znikające napisy plakatu (kolejność rysowania przezroczystości). Zaakceptowane.
- [x] **Przerwy przy kebabie** (`WAIT`, `WRAP_TIME` w `prep_board.gd`): tortilla 1 s, mięso 1,6 s,
  surówka 1,2 s, sos 1 s, szczur 1,6 s, zawijanie 3 s; pasek postępu w podpowiedzi. W tym czasie
  gracz nie może się ruszyć, rozejrzeć ani nic zrobić (`player.work()`), działa tylko pauza.
- [x] **Zdrowie na noc** (przed `v2.0`, nie sprawdzone w grze): `sewer.hp` trwa całą noc, bez leczenia
  po walce; po przegranej `DEFEAT_HP` = 3; leczy tylko zjedzenie [G] kebaba z żywym szczurem
  (`KEBAB_HEAL` = 25, `EAT_TIME` 3 s – wartości dobrane przez agenta). Praca (`player.start_work`)
  ma pikselowy pasek postępu w HUD.
- [x] **E8 Porządki i balans** (zaakceptowane): audyt – wszystkie zasoby, funkcje i teksty w użyciu;
  tunel kanałów rysowany tylko, gdy gracz jest na dole; menu „Sterowanie”, nowy `README.md`,
  `JAK_EDYTOWAC.md`. Balans zaakceptowany przez użytkownika – liczby bez zmian (także 1 szczur = 1 porcja).

## 5. Decyzje użytkownika (trwałe)
- Klimat: pikselowo, ciemno, low-poly – dotyczy też interfejsów minigier.
- Zdjęcia klientów są losowane według płci **także dla postaci charakterystycznych** (gbur może
  wyglądać jak poeta) – **nie zmieniać**.
- Gra jest tylko dla niego – prawami do zdjęć się nie zajmujemy.
- Przygotowania: 4 min realnego czasu. Walka: 1–3 szczury; niezużyte mięso przechodzi na kolejną noc.
- Na górze (podwórko) nie mieszka żaden szczur; Pimpek siedzi w kanałach. Obce szczury pojawiają się
  wyłącznie na czas wejścia na salę (propozycja agenta – bez sprzeciwu); da się je złapać ręką.
- Wielkiego szczura nie da się złapać do worka.
- Zamiast awarii prądu – zacinająca się maszynka (na próbę).
- Sanepid: losowy klient bez żadnych oznak; mandat, gdy szczur jest w lokalu choć przez chwilę lub
  trafi żywy w kebabie. Szczur niesiony w kuchni się nie liczy (decyzja agenta, żeby dało się grać);
  w worku jest niewidoczny.

## 6. Stan kodu
Bez autoloadów i managerów; sygnały w górę, wywołania w dół.

**Sceny i przebieg:** start `Scenes/menu.tscn`, gra `Scenes/game.tscn`. Reguły i stałe: góra
`Scripts/game.gd`. Stan między nocami w `static var save` (noc, kasa, Pimpek, mandaty, mięso, truchła,
worek); nowa noc = przeładowanie sceny. Wstęp: `overlay.show_intro` (tylko noc 1).

**Układ świata:** kuchnia x -3.95..-2.3; lada x ≈ -1.35 (góra), niższa część blatu y 0.827, x ≈ -2.06
(deska, maszynka); sala x > -0.9; podwórko x -7..-1.2, z 5..13; kanały osobno w x = 80.

**Gracz** (`player.gd`): `held`, `hold()`, `discard()`, `busy` (rozmowa, notatnik, walka, minigra),
`carcasses`, `big_carcasses`, `sack` (`""`, `szczur`, `pimpek`), latarka [F], worek [R], notatnik [Tab], wołanie [Q].
Interakcja [E]: warstwa kolizji 2, `get_prompt(player)` i `interact(player)`; miejsca tworzone w kodzie:
`hotspot.gd`.

**Noc** (`game.gd`): przygotowania `PREP_TIME` → tabliczka (`open_sign.gd`) lub samo otwarcie z tłumem
(`RUSH_*`: 5 osób, po 15 s kolejne 3). `NIGHTS`: 11/13/15 klientów. Max 5 w środku; `counter_slots`
5 miejsc (zwykle 3, dalsze tylko w tłoku), `pickup` = indeks 5; 4 krzesła, losowane.

**Klienci** (`customer.gd`): `ENTERING → WAITING ⇄ WALKING → EATING → FAREWELL → LEAVING`; rodzaje w
`TYPES` (regular, sanepid, gourmet, owner). `wants_rat()` = smakosz lub `secret` (`SECRET_CHANCE`).
Kolejka: `queued` ustawia `game._update_queue`. Nerwy: `_annoy` (limit `nerwy`, domyślnie 3).
Zdjęcia: `PHOTOS` + foldery `Textures/zdjecia/zwykli/m|k`, przycinane do kwadratu w locie.

**Teksty:** `Data/dialogi.json` (`dialogs.gd`, opis `Data/JAK_EDYTOWAC.md`). `domyslne` = pula zwykłych
(i sanepidu); `postacie`: babcia, student, gbur, gadula, teoretyk, poeta, smakosz, wlascicielka.
Użytkownik może edytować plik – nie nadpisywać jego zmian. `dialog_box.gd` (odpowiedzi obok klienta),
`speech.gd` (dymki 2D), `notebook.gd`.

**Kanały i walka:** `sewer.gd` (tunel, właz, drabina, 5 gniazd, ręka z nożem; zdrowie `hp` na całą
noc, `DEFEAT_HP`), `battle.gd` (stałe na górze: zdrowie, zamiary `bite/leap/curl`, siły, kontra,
worek; gracz staje przed gniazdem, tłem jest świat 3D), `pixel_ui.gd` (wygląd walki i minigier),
`qte.gd` (sekwencja WASD/strzałki: worek, Pimpek, maszynka). Przegrana: strata połowy truchł z zejścia.
Złoty szczur tylko w kanałach od 2. nocy (+`GOLD_BONUS`).

**Mięso i szczury:** `grinder.gd` (truchła z liczników lub żywy z ręki; 1 porcja, wielki
`BIG_PORTIONS`; `JAM_CHANCE`); `rat.gd` + `Objects/rat.tscn` (żywe szczury na górze: wejścia
`game._invade` co 140–240 s i wyjęte z worka; wypuszczonego Pimpka łapie się minigrą). Wolny Pimpek
trafia na początku nocy do losowego gniazda (`sewer.pimpek_free`); ubity = martwy.
Deska `prep_board.gd` (`contents` od dołu, max 10; żywy szczur = `rat`).

**Wygląd i dźwięk:** otoczenie w kodzie (`build.gd`, `decor.gd`, `outdoors.gd` – auta `ROUTES`,
`backyard.gd`, `dumpster.gd`); `night.gd` (barwa sprite'ów); filtr `Scenes/pixel_filter.tscn` /
`Materials/pixel.gdshader`; `Materials/night_env.tres`; radio `radio.gd` (`STATIONS`) + `radio_knob.gd`.
Generatory grafik i dźwięków tylko lokalnie: `.godot/claude_test/` (`gen_assets.py` generuje dziś tylko
brakujące piosenki radia; istniejących plików nie nadpisuje).

## 7. Zasady rozgrywki
Ocena: 20 zł (+5 za podwójne mięso), −8 zł za błąd, bez mięsa 0; napiwek za bezbłędne i szybkie;
kebab ze szczurem na zamówienie płatny podwójnie. Mandat 40 zł. 3 noce, czynsz 500 zł na koniec.
Ekwipunek tylko jako licznik truchł i worek. Nie robić: rozbudowana ekonomia, zapis w środku nocy.

**Niespodzianki (spoilery):** radio ze stacjami i wiadomościami; złoty szczur; finał „Złoty Kebab”
(czynsz, oddany Pimpek, zero mandatów i niezamówionych szczurów).

## 8. Tryby gry (na później – nie zaczynać bez prośby)
Obecne 3 noce to zalążek trybu **Fabuła**. Obok niego powstanie **Endless**; w menu wybór trybu.
- Endless: noce bez końca, każda trudniejsza (więcej klientów, mniej cierpliwości, wyższy czynsz co noc,
  częstsze szczury i sanepid); koniec, gdy nie uzbierasz czynszu; rekord na dysku.
- Fabuła (5 nocy), pomysł **„Poprzedni sprzedawca”** (do akceptacji): zaczynasz po Mietku, który zniknął;
  co noc znajdujesz jego kartkę (np. „Oni liczą szczury”). Pani od Pimpka, sanepid, klub smakosza
  i wybór: szybki czynsz albo czyste ręce. Finał: Pimpek przewodzi szczurom, Mietek prowadzi konkurencję.

## 9. Wersja 1 (przed tą sesją)
Gracz, kebab, klienci, szczury i maszynka, 3 noce i finał, rozmowy i notatnik, detale, menu, ustawienia.
