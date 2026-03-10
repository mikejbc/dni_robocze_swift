# Dni Robocze

A Polish work days calculator for iPhone, built with SwiftUI.

## Features

- **Policz dni** — count work days between two dates, excluding weekends and all Polish public holidays
- **Dodaj dni** — add or subtract N work days from a given date
- **Święta** — browse Polish public holidays for any year

## Holidays included

All statutory Polish public holidays are supported, including:

- Fixed dates: Nowy Rok, Trzech Króli, Święto Pracy, Konstytucja 3 Maja, Wniebowzięcie NMP, Wszystkich Świętych, Święto Niepodległości, Boże Narodzenie (2 days)
- Moveable (Easter-based): Wielkanoc, Poniedziałek Wielkanocny, Zielone Świątki, Boże Ciało
- Wigilia Bożego Narodzenia (Dec 24) — added from 2025 onward per the legislative change

## Requirements

- iOS 17+
- Xcode 15+

## Getting started

```bash
git clone https://github.com/mikejbc/dni_robocze_swift.git
open dni_robocze_swift/DniRobocze.xcodeproj
```

Then select a simulator or device and hit Run.

## Based on

Swift port of [dni-robocze-pl](https://github.com/mikejbc/dni_robocze) — the original Python CLI/GUI app.
