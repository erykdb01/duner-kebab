# Jak edytować dialogi i imiona

Wszystko jest w `Data/dialogi.json`. Zmiany działają od następnego uruchomienia nocy.

## Zasady pliku JSON
- Tekst w cudzysłowie `"..."`. Cudzysłów w środku tekstu zapisz jako `„...”`.
- Między elementami listy przecinek, po ostatnim **bez** przecinka.
- Jeśli coś się zepsuje, w panelu błędów Godota pojawi się numer linii.

## Części
- `imiona`: `m` i `k`. Dodawaj dowolnie.
- `skladniki`: nazwy używane, gdy klient mówi zamówienie.
- `gracz`: twoje kwestie na przyciskach (`wypros` – losowe wyproszenie poza rozmową).
- `domyslne`: wspólna pula zwykłych klientów (także sanepidu) i teksty dla każdego, kto nie ma własnych.
  Pisz je bez form zdradzających płeć klienta („byłem/byłam”). Mniej oczywiste klucze:
  `ponaglenia_kolejka` (narzekanie w kolejce), `ostrzezenie` i `zdenerwowany` (nerwy),
  `zamowienie_po_cichu` (prośba o żywego szczura), `mandat` (sanepid).
- `postacie`: klienci charakterystyczni. Ich teksty zastępują domyślne o tej samej nazwie.
  Postać z własnymi `rozmowy` nie korzysta ze wspólnych.

Gdzie jest lista, gra losuje jeden tekst.

## Nowa postać
Skopiuj dowolną w `postacie`, zmień nazwę i teksty. Wymagane:
- `typ`: `charakter` (zwykłe zachowanie), `babcia`, `student`, `smakosz`, `wlasciciel`,
- `plec`: `m` lub `k` (z tej listy losowane jest imię),
- `tytul`: podpis, dopóki nie znasz imienia.

Opcjonalnie `gracz` (twoje własne kwestie do tej postaci, np. na „pani”) i `nerwy`
(po ilu irytacjach wychodzi; domyślnie 3). Irytują: niemiła odpowiedź, powtórne pytanie
o zamówienie lub imię i trzecie „Co słychać?”.

## Zdjęcia
Są przycinane do kwadratu i losowane według płci, nie są przypisane do osób.
- Nowe wrzucaj do `Textures/zdjecia/zwykli/m` lub `zwykli/k` (dowolne nazwy: png, jpg, webp).
- Zdjęcia z głównego folderu są wymienione na liście `PHOTOS` w `Scripts/customer.gd`.
- Zwykłe klientki przychodzą dopiero, gdy w `zwykli/k` jest choć jedno zdjęcie.

## Rozmowa i powitanie
Powitanie to zwykły napis (`"Dobry wieczór."`) albo, gdy klient o coś pyta, taki sam blok jak rozmowa.
Rozmowę zaczyna przycisk „Co słychać?”, więc pierwsza kwestia powinna pasować jako odpowiedź.
```json
{
	"klient": "Co mówi klient",
	"odpowiedzi": [
		{"gracz": "Twoja odpowiedź", "klient": "Reakcja", "cierpliwosc": 10, "napiwek": 2},
		{"gracz": "Niemiła odpowiedź", "klient": "Wychodzę!", "wychodzi": true},
		{"gracz": "Dłuższy wątek", "klient": "Słuchaj dalej...", "dalej": [
			{"gracz": "Tak?", "klient": "Koniec."}
		]}
	],
	"wypros": {"gracz": "Wyproszenie pasujące do tej kwestii", "klient": "Reakcja wyproszonego"}
}
```
`cierpliwosc` (sekundy), `napiwek` (zł), `wychodzi`, `dalej` i `wypros` są opcjonalne.
Bez `wypros` gra losuje je z `gracz`.

## Wstawki
`{lista}` – składniki, `{imie}` – imię klienta, `{zamowienie}` – całe zamówienie (w `powtorka`).
