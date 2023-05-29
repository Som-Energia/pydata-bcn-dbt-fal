from diagrams import Cluster, Diagram
from diagrams.onprem.analytics import Dbt, Metabase
from diagrams.onprem.client import Client
from diagrams.onprem.container import Docker
from diagrams.onprem.database import MongoDB, PostgreSQL
from diagrams.onprem.inmemory import Redis
from diagrams.programming.language import Python


def generate_diagram():

    with Diagram("Pydata architecture", show=False):

        with Cluster("Development environment"):
            dbt = Dbt("data")
            python = Python("poetry")
            prophet = Python("forecasts")

            python - dbt
            python - prophet

        with Cluster("Metabase"):
            metabase_data = PostgreSQL("data")
            metabase_app = Metabase("charts")
            metabase_app >> metabase_data

        with Cluster("Databases"):
            dev = PostgreSQL("dev")
            prod = PostgreSQL("prod")
            pgadmin = Client("pgAdmin")
            dev >> pgadmin
            prod >> pgadmin

            dbt >> dev
            dbt >> prod
            dev << metabase_app
            prod << metabase_app

        with Cluster("novu"):
            api = Docker("api")
            embed = Docker("embed")
            mongodb = MongoDB("mongodb")
            redis = Redis("redis")
            web = Docker("web")
            widget = Docker("widget")
            worker = Docker("worker")
            ws = Docker("ws")

            embed >> widget >> api
            widget >> api >> mongodb
            widget >> web >> worker >> redis
            worker >> mongodb
            ws >> redis
            ws >> mongodb
            api >> redis

            dbt >> api


if __name__ == "__main__":
    generate_diagram()
