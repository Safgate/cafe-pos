# ☕ Café POS

An offline-first point of sale for cafés and small restaurants, built with
Flutter for **Android**. Tap-to-order from your menu, keep a full order history
you can edit and void, log what you spend, and read revenue / expenses / profit
by day, week and month.

Adapted from [Dinesh-Sowndar/flutter_billing_app](https://github.com/Dinesh-Sowndar/flutter_billing_app),
which was a barcode-driven retail till. The clean architecture, Hive storage and
ESC/POS printing came from there; ordering, order history, staff, expenses,
reporting and the activity log are new.

## What it does

**Take orders.** A grid of your menu grouped by category. Tap an item to add it;
items with sizes (Small / Medium / Large) ask which one. Sizes are optional — a
croissant has none, a latte has three.

**Keep every sale.** Orders are stored with a daily ticket number and the name of
whoever rang them up. History is grouped by day and searchable back through the
whole record.

**Edit and void, safely.** An owner can reopen a past order and change it, or
void it with a reason. Voided orders are *kept* — greyed out in history,
excluded from every revenue figure, and reported as a separate count. Nothing
financial is ever destroyed.

**Log expenses.** Stock, rent, wages, utilities. Back-date entries when the money
went out earlier than you got round to typing it in.

**See where you stand.** Day / week / month dashboard with revenue, expenses and
profit; a bar chart per day; top sellers; a per-staff split. Tap any figure to
see the orders or expenses behind it. Print an end-of-day summary on the thermal
printer, or export a PDF.

**Know who did what.** Every action — order taken, order edited, order voided,
menu price changed, expense deleted, sign-in, failed sign-in — is recorded with
a name and a timestamp. The log is append-only and cannot be edited from the
app. That is what makes editing past orders safe to allow.

## Three rules the code holds to

1. **Order lines snapshot the item name and price at the time of sale.** They
   never point at the live menu. Raise a coffee's price next month and last
   month's revenue does not move.
2. **Staff names are copied onto orders and log entries.** Deactivating someone
   never blanks out who rang up last week's sales — which is also why staff are
   deactivated, not deleted.
3. **Reports bucket by when the sale happened, never by when it was last
   edited.** Correcting a Tuesday order on Friday changes *Tuesday's* takings.
   That is correct, and it is why the activity log exists.

Whether a sale counts as money taken is defined in exactly one place —
`OrderIterableX.counted` in `lib/features/orders/domain/entities/order.dart` —
so the dashboard, the drill-downs, the thermal summary and the PDF cannot drift
apart and start disagreeing.

## Roles

| | Cashier | Owner |
|---|:---:|:---:|
| Take orders, reprint receipts | ✓ | ✓ |
| Log expenses | ✓ | ✓ |
| View order history | ✓ | ✓ |
| Edit / void an order | | ✓ |
| Manage the menu | | ✓ |
| Reports and dashboard | | ✓ |
| Manage staff, read the activity log | | ✓ |

Each staff member has a 4-digit PIN. **Be clear about what that buys:** PINs are
salted and hashed, so nobody can read them out of the database, and every action
gets a name against it. But four digits is brute-forceable by anyone holding the
phone. Lock the device — that is the real security boundary.

## Getting started

### Prerequisites

- Flutter SDK 3.1.0 or newer — https://docs.flutter.dev/get-started/install/windows
- Android Studio (for the Android SDK and platform tools)
- A physical Android phone for testing. Bluetooth thermal printing cannot be
  exercised on an emulator.

```bash
flutter doctor -v
```

### Run it

```bash
flutter pub get
```

```bash
dart run build_runner build --delete-conflicting-outputs
```

```bash
flutter run
```

Re-run `build_runner` after **any** change to a `@HiveType` model. A stale
`.g.dart` fails at runtime, not at compile time.

### First launch

1. Create the owner account and PIN.
2. **More → Shop Details** — set your name, address, and **currency symbol**.
   The symbol is used everywhere money appears.
3. **Menu** — a sample café menu is seeded on first launch. Edit or delete it;
   it is not re-seeded once you have made it yours.
4. **More → Printer** — pair a Bluetooth thermal printer if you have one.
   Orders save whether or not a printer is connected.

## Project layout

```
lib/
├── config/routes/          go_router shell, tabs, auth gate
├── core/
│   ├── data/               Hive setup, sample menu seed
│   ├── services/           activity logger
│   ├── session/            who is signed in
│   ├── theme/ widgets/     shared UI
│   └── utils/              currency, date ranges, PIN hashing, ESC/POS
└── features/
    ├── activity/           append-only action log
    ├── billing/            the cart and checkout
    ├── expenses/           money going out
    ├── orders/             persisted sales: history, edit, void
    ├── product/            menu items and sizes
    ├── reports/            dashboard, Z-report, PDF
    ├── settings/           printer, More hub
    ├── shop/               shop details and currency
    └── staff/              accounts, PIN login, permissions
```

Each feature splits into `domain` (entities, repository interfaces, use cases),
`data` (Hive models and repository implementations) and `presentation` (blocs
and pages).

### Hive type IDs

Permanent — never renumber:

`0` Product · `1` Shop · `2` ProductVariant · `3` Order · `4` OrderLine ·
`5` Expense · `6` Staff · `7` ActivityLog

Field index `2` on `ProductModel` previously held `barcode` and is retired.

## Tests

```bash
flutter test
```

Covers the parts with real logic and real risk: date-range boundaries (local
midnight, Monday week start, month and leap-year rollover), the report
arithmetic including voided-order exclusion and top-item ranking, PIN salting
and verification, and the invariants an order edit must preserve.

## Known limitations

- **PDF currency symbols.** The PDF uses the standard PDF fonts, which cover
  Latin-1. `$`, `£` and `€` render; `₹` and other non-Latin symbols will not.
  Read those figures on screen or print the thermal summary instead.
- **No tax or service charge.** Prices are what the customer pays.
- **No order type or payment method.** Dine-in vs takeaway and cash vs card are
  not recorded.
- **No modifiers.** Sizes are supported; extras like "oat milk, extra shot" are
  not.
- **Single device.** Data lives in Hive on the phone. There is no sync, no cloud
  backup, and no multi-till support.

## Stack

Flutter · `flutter_bloc` · `get_it` · `go_router` · `hive` · `fpdart` ·
`print_bluetooth_thermal` · `pdf` + `printing` · `crypto`
