# Buckwheat

Offline-first Flutter budget app.

This first pass lays down the app shell and the first two screens:

- Budget setup with a default end date one calendar month ahead.
- Calculator-style transaction entry with cents-based money input.
- Daily budget pacing across the selected date range, including rollover.
- Dynamic budget bubble that shifts color as today's allowance approaches zero.
- Budget bubble tap that switches between calculator entry and newest-to-oldest expenses.
- Expense tags with default categories, floating picker, editor, color wheel, icon customization, and manual ordering.

## Run

Run the app with:

```sh
flutter pub get
flutter run
```

## Checks

```sh
flutter analyze
flutter test
```
