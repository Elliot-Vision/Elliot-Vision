import unittest
from decimal import Decimal
from validate_reference_data import compare


class ReferenceComparisonTest(unittest.TestCase):
    def test_detects_missing_and_wrong_prices(self):
        key = ("AAPL", "2026-08-03", "EUR")
        ref = {key: {"close": Decimal("100")}}
        self.assertEqual(len(compare({}, ref, Decimal("0.01"))), 1)
        self.assertEqual(len(compare({key: {"close": Decimal("101")}}, ref, Decimal("0.01"))), 1)
        self.assertEqual(compare({key: {"close": Decimal("100.01")}}, ref, Decimal("0.01")), [])

    def test_ohlc_and_invalid_tolerance(self):
        ref = {"key": {"open": Decimal("90"), "close": Decimal("100")}}
        self.assertEqual(len(compare({"key": {"close": Decimal("100")}}, ref, Decimal("0"))), 1)
        with self.assertRaises(ValueError):
            compare({}, {}, Decimal("NaN"))
