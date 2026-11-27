# Rat Kebab

Mała, humorystyczna gra z widokiem z pierwszej osoby (Godot 4.7): prowadzisz nocną budkę z kebabem,
a mięso zdobywasz w kanałach pod altaną śmietnikową. Świat jest low-poly, postacie to pikselowe obrazki.

## Jak grać
1. **Przygotowania (4 minuty).** Zejdź włazem do kanałów, pokonaj szczury w turowej walce i zmiel
   truchła w maszynce. Otwórz lokal tabliczką przy drzwiach – inaczej otworzy się sam i wpadnie tłum.
2. **Obsługa.** Zapytaj klienta o zamówienie i imię, zapisz je w notatniku, złóż kebaba i zanieś go
   albo zawołaj klienta po imieniu. Klienci czekają dłużej w kolejce, ale łatwo ich zdenerwować.
3. **Uważaj.** Szczur w lokalu płoszy gości, a sanepid niczym się nie wyróżnia. Niektórzy po cichu
   proszą o żywego szczura. Pani od Pimpka szuka swojego pupila.
4. **Cel.** Trzy noce i czynsz do zapłacenia na koniec. Finałów jest kilka.

## Sterowanie
| Klawisz | Działanie |
|---|---|
| WASD, Ctrl | chodzenie, kucanie |
| E / lewy przycisk myszy | użyj, weź, porozmawiaj |
| Tab | notatnik |
| Q | zawołaj po imieniu |
| R | wyjmij lub schowaj szczura z worka |
| G | zjedz kebaba z żywym szczurem |
| F | latarka |
| 1–5 | odpowiedzi w rozmowie i akcje w walce |
| WASD / strzałki | minigry na refleks |
| Esc | pauza i ustawienia |

## Walka w kanałach
Szczur zapowiada ruch: przed skokiem się zasłoń, skulonego przebij pchnięciem. Pchnięcie kosztuje siły,
które odzyskujesz cięciem i zasłoną. Wielki szczur daje trzy porcje, ale nie mieści się w worku.

Zdrowie masz jedno na całą noc i samo nie wraca. Po pogryzieniu zostaje go ledwie odrobina. Leczy tylko
kebab z żywym szczurem, zjedzony przez ciebie.

## Dla autorów
- Uruchomienie: otwórz `project.godot` w Godot 4.7.
- Dialogi i imiona: `Data/dialogi.json`, opis w `Data/JAK_EDYTOWAC.md`.
- Zdjęcia klientów: `Textures/zdjecia/`.
- Stan prac i opis kodu: `PLAN.md`.
