# Polish Translation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Translate all user-facing English text in the BT Army Creator app to Polish.

**Architecture:** Direct string replacement in views, controllers, and models. Add `config/locales/pl.yml` for Rails-generated messages (validations, date/time). Set default locale to `:pl`. Game system names ("Alpha Strike", "Classic BattleTech"), faction names, chassis names, and variant names remain in English.

**Tech Stack:** Rails 8.1 i18n (locale config only), ERB views, Ruby controllers/models

---

### Task 1: Rails Locale Configuration

**Files:**
- Create: `config/locales/pl.yml`
- Modify: `config/application.rb:19-26`

**Step 1: Create Polish locale file**

Create `config/locales/pl.yml` with ActiveRecord validation messages, date/time formats, and number formatting:

```yaml
pl:
  errors:
    format: "%{attribute} %{message}"
    messages:
      accepted: "musi zostać zaakceptowane"
      blank: "nie może być puste"
      confirmation: "nie zgadza się z potwierdzeniem"
      empty: "nie może być puste"
      equal_to: "musi być równe %{count}"
      even: "musi być parzyste"
      exclusion: "jest zarezerwowane"
      greater_than: "musi być większe od %{count}"
      greater_than_or_equal_to: "musi być większe lub równe %{count}"
      in: "musi być w zakresie %{count}"
      inclusion: "nie znajduje się na liście dopuszczalnych wartości"
      invalid: "jest nieprawidłowe"
      less_than: "musi być mniejsze od %{count}"
      less_than_or_equal_to: "musi być mniejsze lub równe %{count}"
      model_invalid: "Walidacja nie powiodła się: %{errors}"
      not_a_number: "nie jest liczbą"
      not_an_integer: "musi być liczbą całkowitą"
      odd: "musi być nieparzyste"
      other_than: "musi być inne niż %{count}"
      present: "musi być puste"
      required: "musi istnieć"
      taken: "jest już zajęte"
      too_long:
        one: "jest za długie (maksymalnie %{count} znak)"
        few: "jest za długie (maksymalnie %{count} znaki)"
        many: "jest za długie (maksymalnie %{count} znaków)"
        other: "jest za długie (maksymalnie %{count} znaków)"
      too_short:
        one: "jest za krótkie (minimum %{count} znak)"
        few: "jest za krótkie (minimum %{count} znaki)"
        many: "jest za krótkie (minimum %{count} znaków)"
        other: "jest za krótkie (minimum %{count} znaków)"
      wrong_length:
        one: "ma nieprawidłową długość (powinno mieć %{count} znak)"
        few: "ma nieprawidłową długość (powinno mieć %{count} znaki)"
        many: "ma nieprawidłową długość (powinno mieć %{count} znaków)"
        other: "ma nieprawidłową długość (powinno mieć %{count} znaków)"
  activerecord:
    errors:
      messages:
        record_invalid: "Walidacja nie powiodła się: %{errors}"
        restrict_dependent_destroy:
          has_one: "Nie można usunąć rekordu, ponieważ istnieje powiązany %{record}"
          has_many: "Nie można usunąć rekordu, ponieważ istnieją powiązane %{record}"
      models:
        army_list_item:
          attributes:
            variant:
              must_belong_to_chassis: "musi należeć do tego samego chassis co miniatura"
            miniature_id:
              taken: "jest już na tej liście"
    attributes:
      army_list:
        player_name: "Nazwa gracza"
        status: "Status"
      event:
        name: "Nazwa"
        date: "Data"
        game_system: "System gry"
        point_cap: "Limit punktów"
        notes: "Notatki"
        status: "Status"
      chassis:
        name: "Nazwa"
      miniature:
        label: "Etykieta"
        notes: "Notatki"
      user:
        email_address: "Adres e-mail"
        password: "Hasło"
  date:
    abbr_day_names:
      - nie
      - pon
      - wt
      - śr
      - czw
      - pt
      - sob
    abbr_month_names:
      -
      - sty
      - lut
      - mar
      - kwi
      - maj
      - cze
      - lip
      - sie
      - wrz
      - paź
      - lis
      - gru
    day_names:
      - niedziela
      - poniedziałek
      - wtorek
      - środa
      - czwartek
      - piątek
      - sobota
    formats:
      default: "%d.%m.%Y"
      long: "%-d %B %Y"
      short: "%-d %b"
    month_names:
      -
      - stycznia
      - lutego
      - marca
      - kwietnia
      - maja
      - czerwca
      - lipca
      - sierpnia
      - września
      - października
      - listopada
      - grudnia
    order:
      - :day
      - :month
      - :year
  time:
    am: "przed południem"
    formats:
      default: "%d.%m.%Y %H:%M"
      long: "%-d %B %Y %H:%M"
      short: "%-d %b %H:%M"
    pm: "po południu"
  datetime:
    distance_in_words:
      about_x_hours:
        one: "około godziny"
        few: "około %{count} godzin"
        many: "około %{count} godzin"
        other: "około %{count} godzin"
      about_x_months:
        one: "około miesiąca"
        few: "około %{count} miesięcy"
        many: "około %{count} miesięcy"
        other: "około %{count} miesięcy"
      about_x_years:
        one: "około roku"
        few: "około %{count} lat"
        many: "około %{count} lat"
        other: "około %{count} lat"
      almost_x_years:
        one: "prawie rok"
        few: "prawie %{count} lata"
        many: "prawie %{count} lat"
        other: "prawie %{count} lat"
      half_a_minute: "pół minuty"
      less_than_x_minutes:
        one: "mniej niż minutę"
        few: "mniej niż %{count} minuty"
        many: "mniej niż %{count} minut"
        other: "mniej niż %{count} minut"
      less_than_x_seconds:
        one: "mniej niż sekundę"
        few: "mniej niż %{count} sekundy"
        many: "mniej niż %{count} sekund"
        other: "mniej niż %{count} sekund"
      over_x_years:
        one: "ponad rok"
        few: "ponad %{count} lata"
        many: "ponad %{count} lat"
        other: "ponad %{count} lat"
      x_days:
        one: "1 dzień"
        few: "%{count} dni"
        many: "%{count} dni"
        other: "%{count} dni"
      x_minutes:
        one: "1 minuta"
        few: "%{count} minuty"
        many: "%{count} minut"
        other: "%{count} minut"
      x_months:
        one: "1 miesiąc"
        few: "%{count} miesiące"
        many: "%{count} miesięcy"
        other: "%{count} miesięcy"
      x_seconds:
        one: "1 sekunda"
        few: "%{count} sekundy"
        many: "%{count} sekund"
        other: "%{count} sekund"
      x_years:
        one: "1 rok"
        few: "%{count} lata"
        many: "%{count} lat"
        other: "%{count} lat"
  number:
    format:
      delimiter: " "
      precision: 2
      separator: ","
      significant: false
      strip_insignificant_zeros: false
    currency:
      format:
        delimiter: " "
        format: "%n %u"
        precision: 2
        separator: ","
        unit: "zł"
    percentage:
      format:
        delimiter: ""
        format: "%n%"
  support:
    array:
      last_word_connector: " i "
      two_words_connector: " i "
      words_connector: ", "
```

**Step 2: Set default locale to Polish**

In `config/application.rb`, add inside the `Application` class:

```ruby
config.i18n.default_locale = :pl
config.i18n.available_locales = [:pl]
```

**Step 3: Run tests to verify locale loads**

Run: `bin/rails test`
Expected: All existing tests pass (locale file loads without error)

**Step 4: Commit**

```bash
git add config/locales/pl.yml config/application.rb
git commit -m "feat: add Polish locale configuration and set :pl as default"
```

---

### Task 2: Translate Layouts

**Files:**
- Modify: `app/views/layouts/application.html.erb`
- Modify: `app/views/layouts/admin.html.erb`

**Step 1: Translate application layout**

Replace strings in `app/views/layouts/application.html.erb`:
- `"BT Army Creator"` title stays (app name)
- `"Admin"` → `"Admin"` (stays - universal term)
- `"Sign Out"` → `"Wyloguj się"`

**Step 2: Translate admin layout**

Replace strings in `app/views/layouts/admin.html.erb`:
- `"Admin - BT Army Creator"` title stays
- `"Admin Panel"` → `"Panel admina"`
- `"Dashboard"` → `"Pulpit"`
- `"Chassis"` → `"Chassis"` (stays - domain term)
- `"Events"` → `"Wydarzenia"`
- `"Sign Out"` → `"Wyloguj się"`

**Step 3: Commit**

```bash
git add app/views/layouts/
git commit -m "feat: translate layouts to Polish"
```

---

### Task 3: Translate Public Event Views

**Files:**
- Modify: `app/views/events/index.html.erb`
- Modify: `app/views/events/show.html.erb`
- Modify: `app/views/events/_event_card.html.erb`

**Step 1: Translate events index**

Replace in `app/views/events/index.html.erb`:
- `"BattleTech Events"` → `"Wydarzenia BattleTech"`
- `"Pick an event and build your army list from the available miniatures."` → `"Wybierz wydarzenie i stwórz listę armijną z dostępnych miniatur."`
- `"Active Events"` → `"Aktywne wydarzenia"`
- `"Upcoming Events"` → `"Nadchodzące wydarzenia"`
- `"No events scheduled yet. Check back soon!"` → `"Brak zaplanowanych wydarzeń. Sprawdź ponownie wkrótce!"`

**Step 2: Translate events show**

Replace in `app/views/events/show.html.erb`:
- `@event.status.capitalize` → use a helper method or inline map for Polish status names
- `"Eras:"` → `"Ery:"`
- `"Factions:"` → `"Frakcje:"`
- `"Create Army List"` → `"Utwórz listę armijną"`
- `"Submitted Lists"` → `"Zgłoszone listy"`
- `"units"` → replace with Polish: inline `jednostek`
- `"Submitted ... ago"` → `"Zgłoszono ... temu"`
- `cap` label stays contextual with BV/PV

Also add a helper method in `app/models/event.rb` for Polish status labels:

```ruby
def status_label
  case status
  when "upcoming" then "Nadchodzące"
  when "active" then "Aktywne"
  when "completed" then "Zakończone"
  end
end
```

**Step 3: Translate event card partial**

Replace in `app/views/events/_event_card.html.erb`:
- `active ? "Active" : "Upcoming"` → `active ? "Aktywne" : "Nadchodzące"`
- `"lists submitted"` → `"zgłoszonych list"`
- `"Eras:"` → `"Ery:"`
- `"cap"` — keep as context with BV/PV

**Step 4: Run tests**

Run: `bin/rails test`

**Step 5: Commit**

```bash
git add app/views/events/ app/models/event.rb
git commit -m "feat: translate public event views to Polish"
```

---

### Task 4: Translate Army List Views

**Files:**
- Modify: `app/views/army_lists/new.html.erb`
- Modify: `app/views/army_lists/show.html.erb`
- Modify: `app/views/army_lists/_point_total.html.erb`

**Step 1: Translate army list new**

Replace in `app/views/army_lists/new.html.erb`:
- `"Create Army List"` → `"Utwórz listę armijną"`
- `"Your Name"` → `"Twoje imię"`
- `"Enter your name"` → `"Wpisz swoje imię"`
- `"Start Building"` → `"Rozpocznij budowanie"`
- `"Cancel"` → `"Anuluj"`

**Step 2: Translate army list show**

Replace in `app/views/army_lists/show.html.erb`:
- `"'s Army List"` → `" — Lista armijna"` (Polish doesn't use possessive 's)
- `"List submitted on ... Miniatures are locked for this event."` → `"Lista zgłoszona ... Miniatury są zablokowane na to wydarzenie."`
- `"Your Units"` → `"Twoje jednostki"`
- `"No units yet. Add miniatures from the available pool."` → `"Brak jednostek. Dodaj miniatury z dostępnej puli."`
- `"Submit Army List"` → `"Zgłoś listę armijną"`
- `"Submit this list? Your miniatures will be locked for this event."` → `"Zgłosić tę listę? Twoje miniatury zostaną zablokowane na to wydarzenie."`
- `"Available Miniatures"` → `"Dostępne miniatury"`
- `"No miniatures available."` → `"Brak dostępnych miniatur."`

**Step 3: Translate point total partial**

Replace in `app/views/army_lists/_point_total.html.erb`:
- `"Over the point cap!"` → `"Przekroczono limit punktów!"`

**Step 4: Run tests**

Run: `bin/rails test`

**Step 5: Commit**

```bash
git add app/views/army_lists/
git commit -m "feat: translate army list views to Polish"
```

---

### Task 5: Translate Miniature and Army List Item Partials

**Files:**
- Modify: `app/views/miniatures/_available_card.html.erb`
- Modify: `app/views/army_list_items/_item.html.erb`

**Step 1: Translate available miniature card**

Replace in `app/views/miniatures/_available_card.html.erb`:
- `"Select variant..."` → `"Wybierz wariant..."`
- `"Add"` → `"Dodaj"`
- `"No variants available for current restrictions"` → `"Brak wariantów dla obecnych ograniczeń"`

**Step 2: Translate army list item partial**

Replace in `app/views/army_list_items/_item.html.erb`:
- `"Unknown"` → `"Nieznana"` (role)
- `"Remove"` → `"Usuń"`
- `"Remove this unit?"` → `"Usunąć tę jednostkę?"`

**Step 3: Commit**

```bash
git add app/views/miniatures/ app/views/army_list_items/
git commit -m "feat: translate miniature and army list item partials to Polish"
```

---

### Task 6: Translate Admin Session & Dashboard Views

**Files:**
- Modify: `app/views/admin/sessions/new.html.erb`
- Modify: `app/views/admin/dashboard/show.html.erb`

**Step 1: Translate admin login**

Replace in `app/views/admin/sessions/new.html.erb`:
- `"Admin Login"` → `"Logowanie admina"`
- `"Email"` → `"E-mail"`
- `"Password"` → `"Hasło"`
- `"Sign In"` → `"Zaloguj się"`

**Step 2: Translate admin dashboard**

Replace in `app/views/admin/dashboard/show.html.erb`:
- `"Dashboard"` → `"Pulpit"`
- `"Chassis"` → `"Chassis"` (stays)
- `"Miniatures"` → `"Miniatury"`
- `"Upcoming Events"` → `"Nadchodzące wydarzenia"`

**Step 3: Commit**

```bash
git add app/views/admin/sessions/ app/views/admin/dashboard/
git commit -m "feat: translate admin session and dashboard to Polish"
```

---

### Task 7: Translate Admin Chassis Views

**Files:**
- Modify: `app/views/admin/chassis/index.html.erb`
- Modify: `app/views/admin/chassis/new.html.erb`
- Modify: `app/views/admin/chassis/edit.html.erb`
- Modify: `app/views/admin/chassis/_form.html.erb`

**Step 1: Translate chassis index**

Replace in `app/views/admin/chassis/index.html.erb`:
- `"Chassis"` heading → `"Chassis"` (stays)
- `"Add Chassis"` → `"Dodaj chassis"`
- Table headers: `"Name"` → `"Nazwa"`, `"Type"` → `"Typ"`, `"Tonnage"` → `"Tonaż"`, `"Variants"` → `"Warianty"`, `"Minis"` → `"Miniatury"`, `"Last Synced"` → `"Ostatnia synchronizacja"`, `"Actions"` → `"Akcje"`
- `"Never"` → `"Nigdy"`
- `"ago"` suffix → `"temu"` (handled by locale)
- `"Add Mini"` → `"Dodaj miniaturę"`
- `"Sync"` → `"Synchronizuj"`
- `"Edit"` → `"Edytuj"`
- `"Delete"` → `"Usuń"`
- `"Delete #{chassis.name} and all its variants?"` → `"Usunąć #{chassis.name} i wszystkie warianty?"`
- `"Minis:"` → `"Miniatury:"`
- `"edit"` link → `"edytuj"`
- `"No chassis yet. Add one to start building your miniature inventory."` → `"Brak chassis. Dodaj pierwszy, aby rozpocząć budowanie inwentarza miniatur."`

**Step 2: Translate chassis new/edit**

- `"Add Chassis"` → `"Dodaj chassis"`
- `"Edit Chassis"` → `"Edytuj chassis"`

**Step 3: Translate chassis form**

Replace in `app/views/admin/chassis/_form.html.erb`:
- `"Chassis Name"` → `"Nazwa chassis"`
- Placeholder stays (example names are proper nouns)
- `"Enter the chassis name exactly as it appears on masterunitlist.info"` → `"Wpisz nazwę chassis dokładnie tak, jak widnieje na masterunitlist.info"`
- `"Cancel"` → `"Anuluj"`

**Step 4: Run tests**

Run: `bin/rails test`

**Step 5: Commit**

```bash
git add app/views/admin/chassis/
git commit -m "feat: translate admin chassis views to Polish"
```

---

### Task 8: Translate Admin Miniature Views

**Files:**
- Modify: `app/views/admin/miniatures/new.html.erb`
- Modify: `app/views/admin/miniatures/edit.html.erb`
- Modify: `app/views/admin/miniatures/_form.html.erb`

**Step 1: Translate miniature new/edit headings**

- `"Add Miniature for"` → `"Dodaj miniaturę dla"`
- `"Edit Miniature for"` → `"Edytuj miniaturę dla"`

**Step 2: Translate miniature form**

Replace in `app/views/admin/miniatures/_form.html.erb`:
- `"Label (optional)"` → `"Etykieta (opcjonalna)"`
- Placeholder: `"e.g., Atlas #2, painted red, proxy"` → `"np. Atlas #2, czerwony, proxy"`
- `"Optional label to distinguish multiple minis of the same chassis"` → `"Opcjonalna etykieta do rozróżnienia wielu miniatur tego samego chassis"`
- `"Notes (optional)"` → `"Notatki (opcjonalne)"`
- `"Any notes about this miniature..."` → `"Dowolne notatki o tej miniaturze..."`
- `"Cancel"` → `"Anuluj"`

**Step 3: Commit**

```bash
git add app/views/admin/miniatures/
git commit -m "feat: translate admin miniature views to Polish"
```

---

### Task 9: Translate Admin Event Views

**Files:**
- Modify: `app/views/admin/events/index.html.erb`
- Modify: `app/views/admin/events/new.html.erb`
- Modify: `app/views/admin/events/edit.html.erb`
- Modify: `app/views/admin/events/_form.html.erb`
- Modify: `app/views/admin/events/show.html.erb`

**Step 1: Translate events index**

Replace in `app/views/admin/events/index.html.erb`:
- `"Events"` → `"Wydarzenia"`
- `"Create Event"` → `"Utwórz wydarzenie"`
- `event.status.capitalize` → use `event.status_label` (from Task 3)
- `"View"` → `"Zobacz"`
- `"Edit"` → `"Edytuj"`
- `"Delete"` → `"Usuń"`
- `"Delete this event?"` → `"Usunąć to wydarzenie?"`
- `"No events yet. Create one to get started."` → `"Brak wydarzeń. Utwórz pierwsze, aby rozpocząć."`

**Step 2: Translate event new/edit**

- `"Create Event"` → `"Utwórz wydarzenie"`
- `"Edit Event"` → `"Edytuj wydarzenie"`

**Step 3: Translate event form**

Replace in `app/views/admin/events/_form.html.erb`:
- `"Game System"` → `"System gry"`
- `"Point Cap"` → `"Limit punktów"`
- `"Custom Rules / Notes"` → `"Zasady dodatkowe / Notatki"`
- `"Any additional rules or notes for this event..."` → `"Dodatkowe zasady lub notatki do tego wydarzenia..."`
- `"Era Restrictions (leave empty for no restriction)"` → `"Ograniczenia er (zostaw puste, aby nie ograniczać)"`
- `"Faction Restrictions (leave empty for no restriction)"` → `"Ograniczenia frakcji (zostaw puste, aby nie ograniczać)"`
- `"Cancel"` → `"Anuluj"`

Note: The `form.label :name` and `form.label :date` will automatically use the Polish attribute names from `pl.yml`.

**Step 4: Translate event show (admin)**

Replace in `app/views/admin/events/show.html.erb`:
- `event.status.capitalize` → `event.status_label`
- `"Activate"` → `"Aktywuj"`
- `"Complete"` → `"Zakończ"`
- `"Mark this event as completed?"` → `"Oznaczyć wydarzenie jako zakończone?"`
- `"Edit"` → `"Edytuj"`
- `"Restrictions"` → `"Ograniczenia"`
- `"Eras:"` → `"Ery:"`
- `"Factions:"` → `"Frakcje:"`
- `"Notes"` → `"Notatki"`
- `"Army Lists"` → `"Listy armijne"`
- `"units"` → `"jednostek"`
- `list.status.capitalize` → use a helper or inline map for Polish
- `"View"` → `"Zobacz"`
- `"Unlock"` → `"Odblokuj"`
- `"Unlock this list? Miniatures will be released."` → `"Odblokować tę listę? Miniatury zostaną zwolnione."`
- `"Delete"` → `"Usuń"`
- `"Delete this army list?"` → `"Usunąć tę listę armijną?"`
- `"No army lists yet for this event."` → `"Brak list armijnych dla tego wydarzenia."`

**Step 5: Run tests**

Run: `bin/rails test`

**Step 6: Commit**

```bash
git add app/views/admin/events/
git commit -m "feat: translate admin event views to Polish"
```

---

### Task 10: Translate Admin Army List View

**Files:**
- Modify: `app/views/admin/army_lists/show.html.erb`

**Step 1: Translate admin army list show**

Replace in `app/views/admin/army_lists/show.html.erb`:
- `"&larr; Back to"` → `"&larr; Powrót do"`
- `"'s Army List"` → `" — Lista armijna"`
- `@army_list.status.capitalize` → use inline Polish map
- `"Miniature"` table header → `"Miniatura"`
- `"Variant"` table header → `"Wariant"`
- `"Tonnage"` table header → `"Tonaż"`
- `"No units in this list."` → `"Brak jednostek na tej liście."`

**Step 2: Commit**

```bash
git add app/views/admin/army_lists/
git commit -m "feat: translate admin army list view to Polish"
```

---

### Task 11: Translate Auth Views (Public Sessions + Passwords)

**Files:**
- Modify: `app/views/sessions/new.html.erb`
- Modify: `app/views/passwords/new.html.erb`
- Modify: `app/views/passwords/edit.html.erb`

**Step 1: Translate public session login**

Replace in `app/views/sessions/new.html.erb`:
- `"Sign in"` → `"Zaloguj się"`
- `"Enter your email address"` → `"Wpisz swój adres e-mail"`
- `"Enter your password"` → `"Wpisz swoje hasło"`
- `"Sign in"` (button) → `"Zaloguj się"`
- `"Forgot password?"` → `"Nie pamiętasz hasła?"`

**Step 2: Translate password reset request**

Replace in `app/views/passwords/new.html.erb`:
- `"Forgot your password?"` → `"Nie pamiętasz hasła?"`
- `"Enter your email address"` → `"Wpisz swój adres e-mail"`
- `"Email reset instructions"` → `"Wyślij instrukcje resetowania"`

**Step 3: Translate password update form**

Replace in `app/views/passwords/edit.html.erb`:
- `"Update your password"` → `"Zaktualizuj hasło"`
- `"Enter new password"` → `"Wpisz nowe hasło"`
- `"Repeat new password"` → `"Powtórz nowe hasło"`
- `"Save"` → `"Zapisz"`

**Step 4: Commit**

```bash
git add app/views/sessions/ app/views/passwords/
git commit -m "feat: translate auth views to Polish"
```

---

### Task 12: Translate Mailer

**Files:**
- Modify: `app/mailers/passwords_mailer.rb`
- Modify: `app/views/passwords_mailer/reset.html.erb`
- Modify: `app/views/passwords_mailer/reset.text.erb`

**Step 1: Translate mailer subject**

In `app/mailers/passwords_mailer.rb`, change:
- `"Reset your password"` → `"Resetowanie hasła"`

**Step 2: Translate mailer templates**

In both `reset.html.erb` and `reset.text.erb`:
- `"You can reset your password on"` → `"Możesz zresetować hasło na"`
- `"this password reset page"` → `"tej stronie resetowania hasła"`
- `"This link will expire in"` → `"Ten link wygaśnie za"`

**Step 3: Commit**

```bash
git add app/mailers/ app/views/passwords_mailer/
git commit -m "feat: translate password reset mailer to Polish"
```

---

### Task 13: Translate Controller Flash Messages

**Files:**
- Modify: `app/controllers/army_lists_controller.rb:45`
- Modify: `app/controllers/concerns/army_list_ownership.rb:8`
- Modify: `app/controllers/passwords_controller.rb:4,14,23,25,33`
- Modify: `app/controllers/sessions_controller.rb:3,13`
- Modify: `app/controllers/admin/sessions_controller.rb:4,14`
- Modify: `app/controllers/admin/events_controller.rb:23,39,49,54,59`
- Modify: `app/controllers/admin/chassis_controller.rb:17,28,36,44`
- Modify: `app/controllers/admin/miniatures_controller.rb:13,24,32`
- Modify: `app/controllers/admin/army_lists_controller.rb:16,21`

**Step 1: Translate public controller messages**

`army_lists_controller.rb`:
- `"Army list submitted! Your miniatures are locked in."` → `"Lista armijna zgłoszona! Twoje miniatury są zablokowane."`

`army_list_ownership.rb`:
- `"You don't have access to this list."` → `"Nie masz dostępu do tej listy."`

`passwords_controller.rb`:
- `"Try again later."` → `"Spróbuj ponownie później."`
- `"Password reset instructions sent (if user with that email address exists)."` → `"Instrukcje resetowania hasła wysłane (jeśli istnieje użytkownik z tym adresem e-mail)."`
- `"Password has been reset."` → `"Hasło zostało zresetowane."`
- `"Passwords did not match."` → `"Hasła nie są zgodne."`
- `"Password reset link is invalid or has expired."` → `"Link do resetowania hasła jest nieprawidłowy lub wygasł."`

`sessions_controller.rb`:
- `"Try again later."` → `"Spróbuj ponownie później."`
- `"Try another email address or password."` → `"Spróbuj inny adres e-mail lub hasło."`

**Step 2: Translate admin controller messages**

`admin/sessions_controller.rb`:
- `"Try again later."` → `"Spróbuj ponownie później."`
- `"Try another email address or password."` → `"Spróbuj inny adres e-mail lub hasło."`

`admin/events_controller.rb`:
- `"Event created."` → `"Wydarzenie utworzone."`
- `"Event updated."` → `"Wydarzenie zaktualizowane."`
- `"Event deleted."` → `"Wydarzenie usunięte."`
- `"Event is now active."` → `"Wydarzenie jest teraz aktywne."`
- `"Event completed."` → `"Wydarzenie zakończone."`

`admin/chassis_controller.rb`:
- `"#{@chassis.name} added. Syncing variants from MUL..."` → `"#{@chassis.name} dodano. Synchronizacja wariantów z MUL..."`
- `"#{@chassis.name} updated."` → `"#{@chassis.name} zaktualizowano."`
- `"#{@chassis.name} deleted."` → `"#{@chassis.name} usunięto."`
- `"Syncing variants for #{@chassis.name}..."` → `"Synchronizacja wariantów dla #{@chassis.name}..."`

`admin/miniatures_controller.rb`:
- `"Miniature added to #{@chassis.name}."` → `"Miniatura dodana do #{@chassis.name}."`
- `"Miniature updated."` → `"Miniatura zaktualizowana."`
- `"Miniature deleted."` → `"Miniatura usunięta."`

`admin/army_lists_controller.rb`:
- `"Army list deleted."` → `"Lista armijna usunięta."`
- `"Army list unlocked. Miniatures are available again."` → `"Lista armijna odblokowana. Miniatury są ponownie dostępne."`

**Step 3: Run tests**

Run: `bin/rails test`

**Step 4: Commit**

```bash
git add app/controllers/
git commit -m "feat: translate controller flash messages to Polish"
```

---

### Task 14: Translate Model Messages

**Files:**
- Modify: `app/models/army_list.rb:34,49`
- Modify: `app/models/army_list_item.rb:14`

**Step 1: Translate ArmyList model messages**

In `app/models/army_list.rb`:
- `"#{item.miniature.display_name} is no longer available"` → `"#{item.miniature.display_name} nie jest już dostępna"`
- `"One or more miniatures were just claimed by another player. Please review your list."` → `"Jedna lub więcej miniatur została właśnie zajęta przez innego gracza. Sprawdź swoją listę."`

**Step 2: Translate ArmyListItem validation**

In `app/models/army_list_item.rb`:
- `"must belong to the same chassis as the miniature"` → `"musi należeć do tego samego chassis co miniatura"`

Note: This is also defined in `pl.yml` under `activerecord.errors.models.army_list_item.attributes.variant.must_belong_to_chassis`, but since we're doing direct replacement, change it in the model too.

**Step 3: Add `status_label` to ArmyList model**

Add a helper for Polish army list status labels:

```ruby
def status_label
  case status
  when "draft" then "Szkic"
  when "submitted" then "Zgłoszona"
  end
end
```

**Step 4: Run tests**

Run: `bin/rails test`

**Step 5: Commit**

```bash
git add app/models/
git commit -m "feat: translate model messages to Polish"
```

---

### Task 15: Delete en.yml and Final Verification

**Files:**
- Delete: `config/locales/en.yml` (no longer needed)

**Step 1: Remove English locale file**

Delete `config/locales/en.yml` since the app only uses Polish.

**Step 2: Run full test suite**

Run: `bin/rails test`
Expected: All tests pass

**Step 3: Commit**

```bash
git rm config/locales/en.yml
git commit -m "chore: remove unused English locale file"
```

---

### Task 16: Update date formatting in views

**Files:**
- Modify: `app/views/events/show.html.erb` (strftime calls)
- Modify: `app/views/admin/events/index.html.erb` (strftime calls)
- Modify: `app/views/admin/events/show.html.erb` (strftime calls)
- Modify: `app/views/events/_event_card.html.erb` (strftime calls)
- Modify: `app/views/army_lists/show.html.erb` (strftime calls)

**Step 1: Replace strftime with I18n.l**

Replace all `strftime("%B %d, %Y")` calls with `I18n.l(date, format: :long)` to use Polish month names from the locale file.

Replace `@army_list.submitted_at.strftime("%B %d, %Y at %I:%M %p")` with `I18n.l(@army_list.submitted_at, format: :long)`.

Replace `time_ago_in_words(x) + " ago"` with `time_ago_in_words(x) + " temu"` — the `distance_in_words` translations in `pl.yml` handle the Polish words, just need to append "temu".

**Step 2: Run tests**

Run: `bin/rails test`

**Step 3: Commit**

```bash
git add app/views/
git commit -m "feat: use Polish date formatting in all views"
```
