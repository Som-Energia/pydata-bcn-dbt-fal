from pathlib import Path

import pandas as pd


def model(dbt, session):
    file_path = (
        Path.cwd().parent
        / "assets"
        / "datasets"
        / "raw"
        / "Perfiles_iniciales_de_consumo_y_demanda_de_referencia_2023.csv"
    )

    df = pd.read_csv(
        file_path,
        sep=";",
        decimal=".",
        thousands=",",
        index_col=0,
    )
    # reset index
    df = df.reset_index()

    # rename columns
    col_mapping = {
        "Mes": "month",
        "Día": "day",
        "Hora": "hour",
        "P2.0TD,0m,d,h": "p20td",
        "P3.0TD,0m,d,h": "p30td",
        "P3.0TDVE,0m,d,h": "p30tdve",
        "Demanda de Referencia 2023 (MW)": "ref_demand_2023_mw",
    }

    # rename columns
    df = df.rename(columns=col_mapping)

    # build datetime column
    df["_timestamp"] = df[["month", "day", "hour"]].apply(
        lambda x: f"2023-{x[0]:02d}-{x[1]:02d} 00:00:00", axis=1
    )

    # convert to datetime
    df["timestamp"] = pd.to_datetime(
        df["_timestamp"], format="%Y-%m-%d %H:%M:%S"
    )

    # add number of hours column
    df["timestamp"] = df["timestamp"] + pd.to_timedelta(df["hour"], unit="h")

    # drop columns
    df = df.drop(columns=["_timestamp", "month", "day", "hour"])

    return df


if __name__ == "__main__":
    model(None, None)
