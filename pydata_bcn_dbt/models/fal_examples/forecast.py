import datetime as dt

import pandas as pd
from dbt.fal import ref
from fbprophet import Prophet
from fbprophet.plot import plot_plotly

my_dataframe = ref("my_model_name")


# We start by building a Prophet object and fitting our model DataFrame to it:
m = Prophet()
m.fit(my_dataframe)

# define model parameters
n_future_days = 30
ds = my_dataframe["ds"].max()
future_dates = []
for _ in range(n_future_days):
    ds = ds + dt.datetime.timedelta(days=1)
    future_dates.append(ds)

# Once we have a list of future dates, we create a new DataFrame with it:

df_future = pd.DataFrame({"ds": future_dates})

# and make an actual forecast:

forecast = m.predict(df_future)

# We finish by plotting our forecast data and storing the plot as an image:
fig = plot_plotly(m, forecast, xlabel="Date", ylabel="Agent Wait Time")
fig.write_image("my_forecast_plot.png")
