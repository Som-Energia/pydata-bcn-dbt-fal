import datetime as dt

import pandas as pd
from prophet import Prophet
from prophet.plot import plot_plotly


def model(dbt, session):
    df = dbt.ref("sales")

    # prophet expects a dataframe with a column named "ds" and a column named "y"
    df = df.rename(columns={"date": "ds", "sales_k_usd": "y"})

    m = Prophet()
    m.fit(df)

    n_future_days = 90

    ds = df["ds"].max()
    future_dates = []

    for _ in range(n_future_days):
        ds = ds + dt.timedelta(days=1)
        future_dates.append(ds)

    df_future = pd.DataFrame({"ds": future_dates})

    forecast = m.predict(df_future)

    fig = plot_plotly(m, forecast, xlabel="Date", ylabel="Sales")
    fig.write_image("out/forecasts/my_forecast_plot.png")

    return forecast


if __name__ == "__main__":
    dbt = None
    session = None
    model(dbt, session)
