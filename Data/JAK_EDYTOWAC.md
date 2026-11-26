# Jak edytować dialogi i imiona

Wszystko jest w `Data/dialogi.json`. Zmiany działają od następnego uruchomienia nocy.

## Zasady pliku JSON
- Tekst w cudzysłowie `"..."`. Cudzysłów w środku tekstu zastąp pojedynczym `'`.
- Między elementami listy przecinek, po ostatnim **bez** przecinka.
- Jeśli coś się zepsuje, w panelu błędów Godota pojawi się numer linii.

## Części
- `imiona`: `m` i `k`. Dodawaj dowolnie.
- `skladniki`: nazwy używane, gdy klient mówi zamówienie.
- `gracz`: twoje kwestie na przyciskach.
- `domyslne`: teksty dla każdego, kto nie ma własnych. `rozmowy` stąd są wspólne dla wszystkich
  poza właścicielką Pimpka.
- `postacie`: własne teksty nadpisują domyślne o tej samej nazwie.

Gdzie jest lista, gra losuje jeden tekst.

## Nowa postać
Skopiuj dowolną w `postacie`, zmień nazwę i teksty. Wymagane:
- `typ` (wygląd i zachowanie): `regular`, `klientka`, `student`, `babcia`, `sanepid`, `smakosz`, `wlasciciel`,
- `plec`: `m` lub `k` (z tej listy losowane jest imię),
- `tytul`: podpis, dopóki nie znasz imienia.

Wygląd to zdjęcie `Textures/zdjecia/<nazwa postaci>.png`, `.jpg` albo `.webp`. Gra pokazuje je w całości,
jako rozpikselowany prostokąt (`PHOTO_PIXELS` w `Scripts/customer.gd`: mniej = większe piksele).
Zamiana wyglądu = zmiana nazwy pliku. Postać może też wskazać cudze, np. `"wyglad": "gbur"`.
Postać bez zdjęcia pożycza losowe zdjęcie osoby tej samej płci.

## Powitania
Zwykły napis (`"Dobry wieczór."`), gdy nie wymaga odpowiedzi. Jeśli klient o coś pyta albo mówi coś
dziwnego, zapisz powitanie jak rozmowę (niżej), żeby dostać pasujące odpowiedzi.

Klient w rozmowach mówi na przemian swoje i wspólne (`domyslne`), a ta sama rozmowa nie powtarza się
w ciągu jednej nocy. Rozmowy wspólne pisz bez form „byłem/byłam”, bo mówią je i panowie, i panie.

## Rozmowa
`co` to wyjaśnienie, które klient powie po twoim „Co?”. Każdą rozmowę zaczyna przycisk „Co słychać?”,
więc pierwsza kwestia powinna pasować jako odpowiedź na to pytanie.
```json
{
	"klient": "Co mówi klient",
	"co": "Jak to wyjaśnia",
	"odpowiedzi": [
		{"gracz": "Twoja odpowiedź", "klient": "Reakcja", "cierpliwosc": 10, "napiwek": 2},
		{"gracz": "Niemiła odpowiedź", "klient": "Wychodzę!", "wychodzi": true},
		{"gracz": "Dłuższy wątek", "klient": "Słuchaj dalej...", "dalej": [
			{"gracz": "Tak?", "klient": "Koniec."}
		]}
	]
}
```
`cierpliwosc` (sekundy), `napiwek` (zł), `wychodzi` i `dalej` są opcjonalne.

## Wstawki
`{lista}` – składniki, `{imie}` – imię klienta, `{zamowienie}` – całe zamówienie (w `powtorka`).
