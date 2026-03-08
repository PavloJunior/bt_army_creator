# Polish Translation Design

## Goal

Translate all user-facing English text to Polish. Only Polish users will use this app.

## Approach

Direct string replacement in views, controllers, and models. No i18n abstraction layer since only one language is needed.

## Scope

### Translated

- All view text (headings, labels, descriptions, buttons, empty states, confirmations)
- All flash messages in controllers (~19 messages)
- Custom model validation messages
- Navigation and layout text
- Mailer templates (password reset)
- Rails default validation/date/time messages via `config/locales/pl.yml`

### Kept in English

- Faction names, chassis names, variant names (MUL domain data)
- Game system names: "Alpha Strike", "Classic BattleTech" (proper nouns)

## Rails Locale Configuration

- Set `config.i18n.default_locale = :pl`
- Add `config/locales/pl.yml` for ActiveRecord validations, date/time formats, number formatting
- Polish pluralization rules

## Key Translation Choices

| English | Polish |
|---------|--------|
| Upcoming | Nadchodzące |
| Active | Aktywne |
| Completed | Zakończone |
| Draft | Szkic |
| Submitted | Zgłoszona |
| Sign In | Zaloguj się |
| Sign Out | Wyloguj się |
| Create | Utwórz |
| Edit | Edytuj |
| Delete | Usuń |
| Cancel | Anuluj |
| Save | Zapisz |
| Submit | Zgłoś |
