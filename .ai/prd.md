## Dokument wymagań produktu (PRD) - 10x Cards

### 1. Przegląd produktu

10x Cards to prosta webowa aplikacja do nauki przy użyciu fiszek (flashcards), z naciskiem na minimalny, działający MVP. Głównym celem produktu jest radykalne skrócenie czasu potrzebnego na przygotowanie sensownych fiszek poprzez wykorzystanie generowania przez AI na podstawie wklejonego tekstu.

Produkt umożliwia:

- tworzenie fiszek przez AI na podstawie plain textu (PL/EN),
- ręczne tworzenie fiszek,
- przeglądanie, edycję i usuwanie fiszek,
- korzystanie z prostego systemu kont (e-mail + hasło),
- przygotowanie danych i modeli pod przyszłą integrację z algorytmem spaced repetition (open source), bez projektowania szczegółowego flow powtórek w tej iteracji.

Docelowy użytkownik MVP: dowolna osoba ucząca się z tekstów (notatki, materiały kursowe, artykuły), która chce szybko wygenerować fiszki w webowej aplikacji, bez zaawansowanych funkcji organizacji (talii, tagów, współdzielenia).

Środowisko:

- platforma: wyłącznie web (desktop first, mobile-friendly w miarę możliwości, ale brak osobnych natywnych aplikacji),
- języki treści: polski i angielski (obsługa inputu i generowanych fiszek), UI może być jednojęzyczne (np. PL) na potrzeby MVP,
- dane przechowywane per użytkownik (izolacja danych: każdy użytkownik widzi tylko swoje fiszki).

### 2. Problem użytkownika

Manualne przygotowywanie fiszek o sensownej jakości (krótkie, jednoznaczne, nadające się do powtórek) jest:

- czasochłonne: wymaga ręcznego przeglądania materiału, wyciągania kluczowych informacji i formułowania pytań/odpowiedzi,
- żmudne: wiele osób rezygnuje po krótkim czasie, mimo świadomości, że spaced repetition jest skuteczne,
- nieoptymalne: użytkownicy często kopiują zbyt duże fragmenty lub tworzą zbyt ogólne karty.

Konsekwencje:

- użytkownicy nie budują stabilnej bazy fiszek,
- odpuszczają metodę spaced repetition, bo próg wejścia (czas przygotowania) jest zbyt wysoki,
- istniejące narzędzia (Anki, SuperMemo) nie rozwiązują problemu przygotowania kart, tylko powtórek.

10x Cards ma ten problem zredukować:

- przez generowanie fiszek przez AI na podstawie wklejonego tekstu, tak aby użytkownik mógł jedynie przejrzeć i zaakceptować/edytować gotowe propozycje,
- przy zachowaniu możliwości pełnej ręcznej kontroli (ręczne tworzenie, edycja, odrzucanie kart).

### 3. Wymagania funkcjonalne

#### 3.1. System kont użytkowników i bezpieczeństwo

Zakres MVP:

- rejestracja konta przez e-mail i hasło,
- logowanie i wylogowywanie,
- zmiana hasła po zalogowaniu,
- usunięcie konta (wraz z powiązanymi fiszkami).

Wymagania:

- hasło musi spełniać minimalne kryteria bezpieczeństwa (np. min. długość, podstawowe złożenie – szczegóły mogą zostać doprecyzowane na etapie implementacji),
- dane użytkownika (e-mail, password hash) są przechowywane w bezpieczny sposób (hashowanie haseł),
- RLS / autoryzacja po stronie backendu:
  - użytkownik może odczytywać, tworzyć, edytować i usuwać tylko swoje fiszki,
  - każda operacja na fiszkach jest sprawdzana pod kątem user_id,
- po usunięciu konta wszystkie powiązane fiszki użytkownika są trwale usuwane (hard delete).

#### 3.2. Zarządzanie fiszkami (CRUD)

Lista fiszek:

- widok listy wszystkich fiszek aktualnie zalogowanego użytkownika,
- brak decków / talii / kategorii w MVP – lista jest płaska,
- sortowanie domyślne: najnowsze na górze (sortowanie po created_at malejąco),
- paginacja:
  - prosty model, np. page-based (page, pageSize),
  - wymagana możliwość przejścia do kolejnej/poprzedniej strony,
- wyszukiwarka:
  - tekstowe pole wyszukiwania nad listą,
  - filtruje po froncie fiszki (case-insensitive substring search),
  - back nie jest przeszukiwany w MVP,
  - wyszukiwarka działa w połączeniu z paginacją (filtr dotyczy całego zbioru użytkownika, a następnie wynik jest stronicowany).

Tworzenie fiszek ręcznie:

- z widoku listy dostępny jest przycisk dodawania nowej fiszki (np. "Dodaj fiszkę"),
- po kliknięciu otwiera się modal z formularzem:
  - pole front (textarea lub input), max 200 znaków,
  - pole back (textarea), max 500 znaków,
  - przyciski "Zapisz" i "Anuluj",
- walidacja:
  - front nie może być pusty,
  - back nie może być pusty,
  - przekroczenie limitów znaków musi być sygnalizowane w UI i blokować zapis,
- po poprawnym zapisie:
  - fiszka jest zapisywana w bazie,
  - pole origin = "manual",
  - fiszka pojawia się na górze listy (zgodnie z sortowaniem po created_at).

Edycja fiszek:

- każda fiszka na liście ma akcję "Edytuj",
- po kliknięciu otwiera się modal z tym samym formularzem (front/back) wypełnionym aktualnymi danymi,
- walidacja analogiczna jak przy tworzeniu (front/back niepuste, limity znaków),
- przycisk "Zapisz":
  - aktualizuje fiszkę w bazie (updated_at),
  - pozostawia origin bez zmian,
- przycisk "Anuluj":
  - zamyka modal bez zmian.

Usuwanie fiszek:

- każda fiszka ma akcję "Usuń",
- po kliknięciu pojawia się confirm modal z jasnym komunikatem o trwałym usunięciu,
- po potwierdzeniu:
  - fiszka jest twardo usuwana z bazy (hard delete, brak kosza i undo),
- po anulowaniu:
  - nic się nie dzieje, fiszka pozostaje na liście.

#### 3.3. Generowanie fiszek przez AI

Wejście:

- użytkownik wkleja lub wpisuje plain text w polu tekstowym (obsługa PL/EN),
- minimalna długość inputu: 1000 znaków,
- maksymalna długość inputu: 10000 znaków,
- system waliduje długość przed wywołaniem AI:
  - poniżej 1000 znaków: blokada generowania z komunikatem walidacji,
  - powyżej 10000 znaków: blokada generowania z komunikatem walidacji,
- UI powinien wyraźnie wskazywać, ile znaków została wykorzystane (może być licznik znaków).

Wywołanie AI:

- po kliknięciu przycisku (np. "Generuj fiszki") i przejściu walidacji długości:
  - system wysyła input do modelu AI z ustalonym promptem (projekt promptu poza zakresem tego PRD, ale założenie: prosty i stabilny),
  - oczekiwany wynik: do 10 kandydatów fiszek, każda jako front/back:
    - front maks. 200 znaków,
    - back maks. 500 znaków,
  - twarde ograniczenie: maksymalnie 10 kandydatów na jedno wywołanie (hard cap 10),
  - jest dopuszczalne, że AI zwróci mniej niż 10 sensownych kart (np. 3), wtedy zwracany jest mniejszy zestaw.

Stan kandydatów:

- kandydaci nie są zapisywani w bazie jako fiszki,
- istnieją tylko jako stan sesji przeglądania (np. w pamięci aplikacji lub w efemerycznym storage),
- po odświeżeniu strony lub zakończeniu sesji kandydaci mogą zostać utraceni,
- tylko fiszki zaakceptowane przez użytkownika są zapisywane w bazie jako właściwe fiszki.

Przegląd kandydatów:

- użytkownik przechodzi przez kandydatów jeden po drugim (widok "generator review"):
  - wyświetlany jest front i back aktualnej kandydackiej fiszki,
  - widoczne są kontrolki nawigacji (np. "Następna"/"Poprzednia" lub po prostu sekwencyjne przechodzenie),
- dla każdej karty dostępne są trzy akcje:
  - Accept:
    - zapisuje fiszkę do bazy w aktualnej formie,
    - origin = "ai-full",
    - przypisuje ją do aktualnie zalogowanego użytkownika,
  - Edit + Accept:
    - umożliwia edycję front/back kandydackiej fiszki (z walidacją jak przy ręcznym tworzeniu),
    - po zapisaniu zapisywana jest do bazy jako fiszka z origin = "ai-edited",
  - Reject:
    - kandydat jest odrzucany i nie trafia do bazy,
    - brak persystencji odrzuconej karty (poza ewentualnymi logami agregowanego użycia).

Po zakończeniu przeglądu:

- użytkownik może:
  - przejść do listy fiszek i zobaczyć wszystkie zaakceptowane karty (manualne i AI),
  - potencjalnie ponownie wkleić/zmodyfikować input i wygenerować nowe kandydaty (zależnie od polityki rate limiting).

Obsługa błędów:

- w przypadku błędu po stronie AI (timeout, błąd API) system wyświetla prosty komunikat o błędzie i nie zmienia stanu istniejących fiszek,
- brak częściowego zapisu kandydatów; proces jest atomowy z punktu widzenia stanu fiszek (dopiero Accept/Edytuj + Accept tworzą rekordy w bazie).

#### 3.4. Logowanie działań generowania

MVP wymagania dot. logów:

- każdorazowe wywołanie generowania AI tworzy rekord w tabeli `generations` (bez przechowywania pełnego inputu – tylko hash, długość i statystyki),

Kwestie otwarte (do doprecyzowania później, nie blokują MVP):

- czy pełny tekst wejściowy (input) jest przechowywany:
  - opcja 1: nie przechowujemy pełnego inputu, tylko długość i statystyki (bardziej bezpieczne prywatnościowo),
  - opcja 2: przechowujemy pełny input, ale z ograniczonym retention lub z anonimizacją,
- ewentualne dodatkowe pola typu: model_name, latency_ms, token_usage, rate limiting per user.

#### 3.5. Integracja z algorytmem powtórek (backend hooks)

Na tym etapie wymagane jest tylko:

- żeby model danych fiszek dało się rozszerzyć o pola powtórkowe (np. next_review_at, ease, interval),
- żeby logika CRUD na fiszkach była na tyle prosta i przewidywalna, aby później można było:
  - powiązać fiszkę z algorytmem spaced repetition,
  - dodać endpointy / akcje typu "oznacz odpowiedź jako Again/Good/Hard".

Projekt szczegółowego flow powtórek (UI i logika algorytmu) jest poza zakresem tego PRD i będzie opisany w osobnym dokumencie, gdy zostanie wybrany konkretny algorytm open source.

### 4. Granice produktu

Zakres MVP (in scope):

- generowanie fiszek z plain textu (PL/EN) z limitami 1000–10000 znaków,
- maksymalnie 10 kandydackich fiszek na jedno wywołanie AI,
- prosty interfejs przeglądu kandydatów z akcjami Accept / Edit + Accept / Reject per karta,
- manualne tworzenie fiszek z listy (modal front/back),
- przeglądanie, edycja, usuwanie fiszek (twarde usuwanie),
- prosty system kont (rejestracja, logowanie, zmiana hasła, usuwanie konta),
- logi generowania do analizy wykorzystania AI,
- przygotowanie modelu danych pod przyszłą integrację algorytmu powtórek.

Poza zakresem MVP (out of scope):

- brak własnego, zaawansowanego algorytmu powtórek (korzystamy docelowo z gotowego open source, ale nie integrujemy go w tym PRD),
- brak decków, kategorii, tagów, folderów, współdzielenia talii,
- brak importu innych formatów danych (PDF, DOCX, obrazy itd.) – tylko plain text,
- brak integracji z platformami zewnętrznymi (np. LMS, inne aplikacje edukacyjne),
- brak aplikacji mobilnych (tylko web),
- brak soft delete (kosz, undo) dla fiszek i kont,
- brak rozbudowanego onboarding, turoriali, tooltipów (MVP UI może być minimalistyczne),
- brak szczegółowej analityki w formie dashboardów (dane w logach wystarczą na MVP),
- brak szczegółowego flow powtórek (oddzielne mini-PRD na v2),
- brak szczegółowej polityki RODO/prywatności poza standardowym przechowywaniem danych użytkownika i fiszek (do doprecyzowania, jeśli projekt będzie dalej rozwijany).

Nierozwiązane kwestie (do doprecyzowania później):

- heurystyki generowania kart przez AI (formalny opis promptu, stylu front/back, liczba faktów na kartę),
- wybór konkretnego algorytmu spaced repetition i jego API,
- polityka przechowywania pełnego tekstu wejściowego (czy przechowujemy input, jak długo, czy anonimizujemy),
- dokładny schemat tabeli logów generowania (dodatkowe pola techniczne),
- ewentualny rate limiting generowania per użytkownik/dzień (ważne przy realnych kosztach API).

### 5. Historyjki użytkowników

Każda historyjka ma unikalny identyfikator (US-XXX), jest testowalna i opisuje konkretny scenariusz. Poniżej ujęto scenariusze podstawowe, alternatywne i skrajne, w tym związane z bezpieczeństwem (auth).

#### 5.1. System kont i bezpieczeństwo

US-001

- Tytuł: Rejestracja nowego konta
- Opis: Jako nowy użytkownik chcę założyć konto przy użyciu e-maila i hasła, aby móc przechowywać swoje fiszki w sposób prywatny.
- Kryteria akceptacji:
  - AC1: Użytkownik może wprowadzić e-mail i hasło w formularzu rejestracji.
  - AC2: System waliduje format e-maila i minimalne wymagania hasła; w przypadku błędu pokazuje komunikaty walidacyjne.
  - AC3: Po poprawnym wypełnieniu formularza konto jest tworzone i użytkownik jest automatycznie zalogowany lub przekierowany do ekranu logowania (zależnie od decyzji implementacyjnej).
  - AC4: Hasło jest przechowywane w postaci hasha, nie w plain text.

US-002

- Tytuł: Logowanie do istniejącego konta
- Opis: Jako istniejący użytkownik chcę zalogować się przy użyciu e-maila i hasła, aby uzyskać dostęp do swoich fiszek.
- Kryteria akceptacji:
  - AC1: Użytkownik może wprowadzić e-mail i hasło w formularzu logowania.
  - AC2: W przypadku niepoprawnych danych (zły e-mail lub hasło) system pokazuje jasny, niespecyficzny komunikat o błędzie (bez wskazywania, czy e-mail istnieje).
  - AC3: Po poprawnym zalogowaniu użytkownik zostaje przeniesiony do głównego widoku aplikacji (lista fiszek lub ekran powitalny).
  - AC4: Sesja użytkownika jest utrzymywana (np. cookie/token) zgodnie z przyjętym mechanizmem.

US-003

- Tytuł: Wylogowanie z aplikacji
- Opis: Jako zalogowany użytkownik chcę móc się wylogować, aby nikt inny nie miał dostępu do moich fiszek na tym urządzeniu.
- Kryteria akceptacji:
  - AC1: W interfejsie dostępna jest akcja wylogowania.
  - AC2: Po wylogowaniu token/sesja użytkownika są unieważnione.
  - AC3: Po wylogowaniu użytkownik jest przeniesiony do ekranu logowania lub ekranu startowego bez danych.

US-004

- Tytuł: Zmiana hasła
- Opis: Jako zalogowany użytkownik chcę móc zmienić swoje hasło, aby poprawić bezpieczeństwo konta.
- Kryteria akceptacji:
  - AC1: Użytkownik ma dostęp do formularza zmiany hasła (np. stare hasło, nowe hasło, potwierdzenie nowego).
  - AC2: System weryfikuje poprawność starego hasła i waliduje nowe hasło.
  - AC3: Przy niepoprawnym starym haśle wyświetlany jest komunikat o błędzie, a hasło nie jest zmieniane.
  - AC4: Przy poprawnych danych hasło jest aktualizowane, a użytkownik otrzymuje potwierdzenie zmiany.

US-005

- Tytuł: Usunięcie konta
- Opis: Jako zalogowany użytkownik chcę móc usunąć swoje konto wraz z fiszkami, aby moje dane zostały usunięte z systemu.
- Kryteria akceptacji:
  - AC1: Użytkownik ma dostęp do akcji usunięcia konta (np. w ustawieniach).
  - AC2: Przed usunięciem system wyświetla confirm modal z jasnym ostrzeżeniem o trwałej utracie danych.
  - AC3: Po potwierdzeniu konto użytkownika i wszystkie powiązane fiszki są twardo usuwane z bazy.
  - AC4: Po usunięciu konta użytkownik nie może się na nie ponownie zalogować.

US-006

- Tytuł: Ochrona danych przed nieautoryzowanym dostępem
- Opis: Jako użytkownik oczekuję, że nikt nie zobaczy moich fiszek, jeśli nie jest zalogowany na moje konto.
- Kryteria akceptacji:
  - AC1: Próba dostępu do listy fiszek lub operacji na fiszkach bez ważnej sesji powoduje przekierowanie do logowania lub błąd autoryzacji.
  - AC2: Fiszki w bazie są powiązane z user_id, a warstwa backendu egzekwuje, że użytkownik może odczytywać/edytować/usuwać tylko swoje fiszki.
  - AC3: Testy potwierdzają, że użytkownik A nie może odczytać fiszek użytkownika B.

#### 5.2. Generowanie fiszek przez AI

US-007

- Tytuł: Generowanie fiszek z poprawnego inputu
- Opis: Jako zalogowany użytkownik wklejam tekst (1000–10000 znaków) i chcę wygenerować z niego fiszki przy użyciu AI.
- Kryteria akceptacji:
  - AC1: Formularz generowania pozwala wkleić/plain-text input i pokazuje liczbę znaków.
  - AC2: Przy kliknięciu "Generuj fiszki" system sprawdza długość inputu; jeśli mieści się w przedziale 1000–10000, następuje wywołanie AI.
  - AC3: Po udanym wywołaniu użytkownik otrzymuje do 10 kandydatów fiszek.
  - AC4: Kandydaci nie są od razu zapisywani do bazy.

US-008

- Tytuł: Walidacja zbyt krótkiego inputu
- Opis: Jako użytkownik, który wkleił zbyt krótki tekst (<1000 znaków), chcę otrzymać jasny komunikat walidacji zamiast generowania.
- Kryteria akceptacji:
  - AC1: Przy próbie generowania z inputem krótszym niż 1000 znaków wywołanie AI nie następuje.
  - AC2: System wyświetla komunikat o minimalnej wymaganej długości.
  - AC3: Użytkownik może poprawić tekst i ponownie spróbować generowania.

US-009

- Tytuł: Walidacja zbyt długiego inputu
- Opis: Jako użytkownik, który wkleił zbyt długi tekst (>10000 znaków), chcę otrzymać jasny komunikat walidacji i możliwość skrócenia tekstu.
- Kryteria akceptacji:
  - AC1: Przy próbie generowania z inputem dłuższym niż 10000 znaków wywołanie AI nie następuje.
  - AC2: System wyświetla komunikat o maksymalnej dopuszczalnej długości tekstu.
  - AC3: Użytkownik może edytować tekst i ponownie spróbować generowania.

US-010

- Tytuł: Obsługa błędu generowania AI
- Opis: Jako użytkownik, który próbuje wygenerować fiszki, chcę otrzymać jasny komunikat, jeśli system nie może skontaktować się z AI lub wystąpi inny błąd.
- Kryteria akceptacji:
  - AC1: W przypadku błędu API/AI system nie zmienia istniejącej listy fiszek użytkownika.
  - AC2: Użytkownik widzi czytelny komunikat o błędzie generowania (bez detali technicznych).
  - AC3: W logach generowania zapisuje się rekord ze statusem "ai_error" lub podobnym.

#### 5.3. Przegląd i akceptacja kandydatów

US-011

- Tytuł: Akceptacja kandydackiej fiszki bez edycji
- Opis: Jako użytkownik przeglądający kandydatów chcę jednym kliknięciem zaakceptować daną fiszkę tak, aby trafiła do mojej listy zapisanych fiszek.
- Kryteria akceptacji:
  - AC1: Przy kandydacie dostępny jest przycisk "Akceptuj" (lub równoważny).
  - AC2: Po kliknięciu karta jest zapisywana w bazie jako fiszka z origin = "ai-full" i powiązana z user_id.
  - AC3: Po zakończeniu przeglądu kandydatów zaakceptowane karty są widoczne na liście fiszek, na górze (najnowsze).

US-012

- Tytuł: Edycja kandydackiej fiszki przed akceptacją
- Opis: Jako użytkownik chcę móc edytować front/back kandydata wygenerowanego przez AI przed jego zapisaniem, aby poprawić lub doprecyzować treść.
- Kryteria akceptacji:
  - AC1: Przy kandydacie dostępna jest akcja "Edytuj" lub "Edytuj i zaakceptuj".
  - AC2: Edycja odbywa się w formularzu z walidacją front/back (niepuste, limity znaków 200/500).
  - AC3: Po zapisaniu edycji fiszka jest tworzona w bazie z origin = "ai-edited".
  - AC4: Odrzucenie edycji (Anuluj) nie zapisuje fiszki i wraca do widoku kandydata.

US-013

- Tytuł: Odrzucenie kandydackiej fiszki
- Opis: Jako użytkownik chcę móc odrzucić kandydacką fiszkę, która jest nieprzydatna, tak aby nie trafiała do mojej bazy.
- Kryteria akceptacji:
  - AC1: Przy kandydacie dostępna jest akcja "Odrzuć".
  - AC2: Po odrzuceniu kandydat znika z bieżącego przeglądu i nie jest zapisywany w bazie.
  - AC3: Odrzucone karty nie pojawiają się na liście fiszek ani jako osobna sekcja.

US-014

- Tytuł: Przejście przez wszystkie wygenerowane karty
- Opis: Jako użytkownik chcę móc kolejno przejść przez wszystkie wygenerowane kandydaty, aby każdej karcie nadać status (Accept/Edit/Reject).
- Kryteria akceptacji:
  - AC1: System umożliwia nawigację pomiędzy kandydatami (np. "Następna"/"Poprzednia" lub sekwencyjnie).
  - AC2: Po podjęciu decyzji dla ostatniego kandydata system wyświetla informację o zakończeniu przeglądu i umożliwia powrót do listy fiszek.
  - AC3: Po zakończeniu przeglądu wszystkie fiszki oznaczone Accept/Edytuj + Accept są dostępne na liście, a odrzucone nie są przechowywane.

#### 5.4. Manualne tworzenie, przeglądanie i edycja fiszek

US-015

- Tytuł: Ręczne dodanie fiszki
- Opis: Jako zalogowany użytkownik, będąc na liście fiszek, chcę dodać własną fiszkę (front/back) bez użycia AI.
- Kryteria akceptacji:
  - AC1: Na liście fiszek dostępny jest przycisk "Dodaj fiszkę".
  - AC2: Po kliknięciu otwiera się modal z polami front i back oraz przyciskami "Zapisz" i "Anuluj".
  - AC3: Przy pustych polach lub przekroczonych limitach znaków system blokuje zapis i wyświetla komunikaty walidacyjne.
  - AC4: Po poprawnym zapisie fiszka jest widoczna na górze listy i ma origin = "manual".

US-016

- Tytuł: Przeglądanie listy fiszek
- Opis: Jako zalogowany użytkownik chcę móc przeglądać listę wszystkich moich fiszek z najnowszymi na górze.
- Kryteria akceptacji:
  - AC1: Widok listy prezentuje co najmniej front każdej fiszki (back może być skracany lub ukryty do rozwinięcia).
  - AC2: Fiszki są domyślnie posortowane po created_at malejąco.
  - AC3: Lista prezentuje tylko fiszki zalogowanego użytkownika.
  - AC4: Przy większej liczbie fiszek działa paginacja (możliwość przejścia między stronami).

US-017

- Tytuł: Wyszukiwanie fiszek po froncie
- Opis: Jako użytkownik chcę wyszukiwać fiszki po tekście na froncie, aby szybko znaleźć konkretną kartę.
- Kryteria akceptacji:
  - AC1: Nad listą dostępne jest pole wyszukiwania tekstowego.
  - AC2: Wpisanie frazy filtruje fiszki tak, aby pozostały tylko te, których front zawiera tę frazę (case-insensitive).
  - AC3: Wyszukiwanie działa razem z paginacją (użytkownik widzi wyniki paginowane).
  - AC4: Wyczyśczenie pola wyszukiwania przywraca pełną listę fiszek.

US-018

- Tytuł: Edycja istniejącej fiszki
- Opis: Jako użytkownik chcę edytować treść istniejącej fiszki, aby poprawić błędy lub ulepszyć sformułowanie.
- Kryteria akceptacji:
  - AC1: Przy każdej fiszce na liście dostępna jest akcja "Edytuj".
  - AC2: Kliknięcie "Edytuj" otwiera modal z aktualną treścią front/back.
  - AC3: Walidacja front/back jest taka sama jak przy tworzeniu (niepuste, limity znaków).
  - AC4: Po zapisaniu zmiany są widoczne na liście; origin fiszki nie ulega zmianie.

US-019

- Tytuł: Usuwanie fiszki z potwierdzeniem
- Opis: Jako użytkownik chcę móc usunąć fiszkę, której już nie potrzebuję, z potwierdzeniem, aby uniknąć przypadkowego usunięcia.
- Kryteria akceptacji:
  - AC1: Przy każdej fiszce na liście dostępna jest akcja "Usuń".
  - AC2: Po kliknięciu pojawia się confirm modal z informacją o trwałym usunięciu bez możliwości cofnięcia.
  - AC3: Potwierdzenie usuwa fiszkę z bazy i listy (hard delete).
  - AC4: Anulowanie pozostawia fiszkę bez zmian.

#### 5.5. Logowanie generowania i metryki

US-020

- Tytuł: Logowanie zdarzenia generowania
- Opis: Jako właściciel produktu chcę, aby każde wywołanie generowania AI było logowane, aby móc analizować użycie i jakość generowania.
- Kryteria akceptacji:
  - AC1: Każde rozpoczęte wywołanie generowania AI tworzy rekord w tabeli `generations` z user_id, długością inputu (source_text_length), hashem tekstu (source_text_hash), nazwą modelu i znacznikiem czasu.
  - AC2: Po zakończeniu przeglądu kandydatów rekord w `generations` jest uzupełniany o generated_count, accepted_unedited_count, accepted_edited_count oraz czas generowania (generation_duration).
  - AC3: W przypadku błędu generowania tworzony jest rekord w tabeli `generation_error_logs` z user_id, długością inputu, hashem tekstu, nazwą modelu, error_code i error_message.
  - AC4: Logi można później wykorzystać do wyliczenia wskaźników (np. acceptance rate).

### 6. Metryki sukcesu

Metryki produktowe (z perspektywy wartości dla użytkownika):

- co najmniej 75 procent fiszek wygenerowanych przez AI jest akceptowanych przez użytkowników (średnio, w dłuższym okresie),
- co najmniej 75 procent nowo tworzonych fiszek pochodzi z generowania AI (origin = "ai-full" lub "ai-edited") w stosunku do manualnych (origin = "manual").

Metryki operacyjne (możliwe do wyliczenia z logów i modeli danych):

- liczba wywołań generowania AI per użytkownik i globalnie,
- liczba kandydatów wygenerowanych per wywołanie (generated_count),
- liczba zaakceptowanych fiszek per wywołanie (accepted_total = accepted_unedited_count + accepted_edited_count),
- wskaźnik acceptance rate:
  - accepted_count / generated_count na poziomie:
    - pojedynczego wywołania,
    - użytkownika,
    - globalnym,
- udział fiszek AI vs manualnych:
  - liczba fiszek z origin = "ai" / liczba wszystkich fiszek,
  - liczba fiszek z origin = "manual" / liczba wszystkich fiszek.

Warunki techniczne dla mierzalności:

- tabela logów generowania zawiera co najmniej: user_id, input_length, generated_count, accepted_count, status, created_at,
- model fiszki zawiera pole origin (ai/ai-edited/manual),
- dane są na tyle kompletne, aby po stronie analizy (SQL/BI) można było odtworzyć powyższe wskaźniki.

Kryteria sukcesu MVP (kursowe):

- system jest stabilny i pozwala bezbłędnie:
  - zarejestrować się, zalogować i pracować z własnymi fiszkami,
  - generować fiszki przez AI z poprawną walidacją zakresu inputu,
  - przeglądać, akceptować, edytować i odrzucać kandydatów,
  - ręcznie dodawać, edytować, usuwać fiszki,
- logi generowania i pole origin na fiszkach pozwalają obliczyć podstawowe metryki po stronie bazy.
