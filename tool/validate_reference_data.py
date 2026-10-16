"""Compare an exported price series against an independently supplied CSV.

No data is fetched and no reference data is invented by this tool.
"""
from __future__ import annotations

import argparse
import csv
from datetime import datetime, timezone
from decimal import Decimal
from pathlib import Path


def read_series(path: Path) -> dict:
    rows = {}
    with path.open(encoding="utf-8-sig", newline="") as stream:
        reader = csv.DictReader(stream)
        if not {"symbol", "timestamp", "currency", "close"} <= set(reader.fieldnames or []):
            raise ValueError("CSV requires symbol,timestamp,currency,close")
        for row in reader:
            if not row.get("symbol") or not row.get("currency") or not row.get("close"):
                raise ValueError("Symbol, currency and close are required in every row")
            stamp = datetime.fromisoformat(row["timestamp"].replace("Z", "+00:00"))
            if stamp.tzinfo is None:
                raise ValueError("Timestamp requires timezone")
            key = (row["symbol"], stamp.astimezone(timezone.utc), row["currency"])
            if key in rows:
                raise ValueError(f"Duplicate observation: {key}")
            values = {field: Decimal(row[field]) for field in ("open", "high", "low", "close") if row.get(field)}
            if any(not value.is_finite() or value <= 0 for value in values.values()):
                raise ValueError("Prices must be finite and positive")
            rows[key] = values
    if not rows:
        raise ValueError("Empty reference or export")
    return rows


def compare(actual: dict, reference: dict, tolerance: Decimal) -> list[str]:
    if not tolerance.is_finite() or tolerance < 0:
        raise ValueError("Tolerance must be finite and nonnegative")
    errors = []
    for key, expected in reference.items():
        if key not in actual:
            errors.append(f"Missing observation: {key}")
            continue
        for field, value in expected.items():
            observed = actual[key].get(field)
            if observed is None or abs(observed - value) > tolerance:
                errors.append(f"Mismatch: {key} {field}: expected {value}, got {observed}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("actual", type=Path)
    parser.add_argument("reference", type=Path)
    parser.add_argument("--tolerance", type=Decimal, default=Decimal("0.01"))
    args = parser.parse_args()
    try:
        errors = compare(read_series(args.actual), read_series(args.reference), args.tolerance)
    except (ValueError, ArithmeticError) as error:
        parser.error(str(error))
    for error in errors:
        print(error)
    print(f"Reference comparison: {len(errors)} mismatches")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
