import datetime as dt
import os

import pandas as pd
from novu.api import EventApi
from prophet import Prophet


def model(dbt, session) -> pd.DataFrame:

    # run dbt to get the latest data
    dbt.config(materialized="table")

    # uncomment this line and comment the one above to enable virtual environment support
    # dbt.config(materialized="table", fal_environment="forecasts")

    df = dbt.ref("demand_ree")

    # prophet expects a dataframe with a column named "ds" and a column named "y"
    df = df.rename(columns={"timestamp": "ds", "ref_demand_2023_mw": "y"})

    m = Prophet()
    m.add_country_holidays(country_name="Spain")
    m.fit(df)

    # create a future datafram
    n_future_days = 90

    ds = df["ds"].max()
    future_dates = []

    for _ in range(n_future_days):
        ds = ds + dt.timedelta(days=1)
        future_dates.append(ds)

    df_future = pd.DataFrame({"ds": future_dates})

    forecast = m.predict(df_future)

    # report the forecast to novu
    event_api = EventApi(
        "http://novu-api:3000",
        os.environ.get("NOVU_API_KEY"),
    )

    yhat_mean = forecast["yhat"].mean().item()

    event_api.trigger(
        name=os.environ.get("NOVU_APP_NAME"),
        recipients=os.environ.get("NOVU_SUBSCRIBER_ID"),
        payload={"results": {"yhat_mean": f"{yhat_mean:0.2f}"}},
    )

    # craft forecasted_at column
    # https://docs.python.org/3.12/library/datetime.html#datetime.datetime.utcnow
    forecast["forecasted_at"] = dt.datetime.now(dt.timezone.utc)

    return forecast


if __name__ == "__main__":
    dbt = None
    session = None
    model(dbt, session)
