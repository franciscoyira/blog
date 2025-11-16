---
title: How to validate DataFrame joins in Python
author: Francisco Yirá
date: '2025-11-15'
slug: [validate-dataframe-join-python-polars-pandas]
useRelativeCover: true
cover: "images/validate_joins_cover.png"
categories: [data-science, python, polars]
tags: [english-only-ds, join, data-wrangling, flashcards-ds]
---

Ever spent way too long troubleshooting a data issue, only to realize the problem was simply that your DataFrame join keys weren't unique?

Turns out, the pandas and polars libraries offer a very simple way to fix this annoyance: the `validate` argument in the `.join()` method. This argument detects duplicate keys early in your pipeline and stops execution if the uniqueness constraint isn't met. This can be super handy for preventing silent row duplication that would destroy our data integrity.

The best part is that implementing this requires adding less than one line of code\!

The default value for `validate` is `"m:m"` (many-to-many). This means the method doesn't perform any validation on the keys, but we can enable checks by changing the argument to:

  - `"1:m"` (one-to-many): checks for uniqueness in the left DataFrame's key(s).
  - `"m:1"` (many-to-one): checks for uniqueness in the right DataFrame's key(s).
  - `"1:1"` (one-to-one): checks for uniqueness in both DataFrames.

Again, if there's a problem with the uniqueness constraint, our script's execution will stop (we'll see an `exception.ComputeError` if using the method with polars).

Below we can see an example of how to use this argument with polars:

```python
import polars as pl

catalogue = pl.DataFrame({
    "id_produit": [1, 2, 3],
    "nom_produit": ["Computer", "Mouse", "Keyboard"]
})

# Price table - there is conflicting info for product_id=2
prix = pl.DataFrame({
    "id_produit": [1, 2, 2, 3],
    "prx": [1500, 25, 20, 50]
})

catalogue.join(prix, on="id_produit", how="left", validate="1:1")
```

In this example, the code will generate the following error:

```
polars.exceptions.ComputeError: join keys did not fulfill 1:1 validation
```

If we want to allow the script to continue running, we can wrap the join code in a `try`/`except` block. Even better, this allows us to inspect the keys that violated the uniqueness constraint and log the problem.

```python
try:
    catalogue.join(prix, on="id_produit", how="left", validate="1:1")
except pl.exceptions.ComputeError as e:
    print("❌ Join failed:", e)
    print("\n🔍 Checking for duplicate keys in the right DataFrame:")
    duplicates = prix.group_by("id_produit").len().filter(pl.col("len") > 1)
    print(duplicates)
```

```
❌ Join failed: join keys did not fulfill 1:1 validation

🔍 Checking for duplicate keys in the right DataFrame:
shape: (1, 2)
┌────────────┬─────┐
│ id_produit ┆ len │
│ ---        ┆ --- │
│ i64        ┆ u32 │
╞════════════╪═════╡
│ 2          ┆ 2   │
└────────────┴─────┘
```

If you're using the pandas library instead of polars (sorry\!), the code is almost the same, provided you're using version 1.5.0 or later (and you can still add the check to the `.merge` method):

```python
import pandas as pd

catalogue = pd.DataFrame({
    "id_produit": [1, 2, 3],
    "nom_produit": ["Computer", "Mouse", "Keyboard"]
})

prix = pd.DataFrame({
    "id_produit": [1, 2, 2, 3],
    "prx": [1500, 25, 20, 50]
})

try:
    catalogue.merge(prix, on="id_produit", how="left", validate="one_to_one")
except pd.errors.MergeError as e:
    # (do something here if an error is found)
    duplicates = prix.groupby("id_produit").size().loc[lambda x: x > 1]
    print(duplicates)
```

## References

  - [https://docs.pola.rs/api/python/stable/reference/dataframe/api/polars.DataFrame.join.html](https://docs.pola.rs/api/python/stable/reference/dataframe/api/polars.DataFrame.join.html)
  - [https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.join.html](https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.join.html)
  - [https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.merge.html\#pandas.DataFrame.merge](https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.merge.html#pandas.DataFrame.merge)