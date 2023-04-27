from decouple import config
from novu.api import EventApi

event_api = EventApi("http://novu-api:3000", config("NOVU_API_KEY"))


event_api.trigger(
    name="on-boarding-notification",
    recipients="6446cda01e1018fd0f5af967",
    payload={"message": "Hello, pydata!"},
)
