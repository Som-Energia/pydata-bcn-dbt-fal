import random

import holidays
import pandas as pd


def model(dbt, session):
    date_range = pd.date_range(start="2000-01-01", end="2030-01-01", freq="D")
    df = pd.DataFrame({"date": date_range})

    # Comunitat Autonoma holidays (ac codes: https://www.iso.org/obp/ui/#iso:code:3166:ES)
    autonomous_communities = {
        "AN": "01",
        "AR": "02",
        "AS": "03",
        "CB": "06",
        "CE": "18",
        "CL": "07",
        "CM": "08",
        "CN": "05",
        "CT": "09",
        "EX": "11",
        "GA": "12",
        "IB": "04",
        "MC": "14",
        "MD": "13",
        "ML": "19",
        "NC": "15",
        "PV": "16",
        "RI": "17",
        "VC": "10",
    }

    spain_holidays = holidays.ES(years=range(2000, 2030, 1))

    df["is_holiday_ES"] = df["date"].isin(spain_holidays)

    for ac, code in autonomous_communities.items():
        ac_holidays = holidays.ES(prov=code, years=range(2000, 2030, 1))
        df[f"is_holiday_{ac}"] = df["date"].isin(ac_holidays)

    df["is_weekend"] = df["date"].dt.dayofweek.isin([5, 6])

    is_holiday_columns = [c for c in df.columns if c.startswith("is_holiday")]
    df["is_holiday"] = df[is_holiday_columns].any(axis=1)

    # I know nothing about sales, so I'm just going to generate some random numbers
    df["sales_k_usd"] = df["is_holiday"].apply(
        lambda x: random.normalvariate(100, 20)
        if x
        else random.normalvariate(50, 10)
    )

    return df[["date", "sales_k_usd", "is_holiday", "is_weekend"]]


if __name__ == "__main__":
    # for debugging purposes
    model(None, None)
