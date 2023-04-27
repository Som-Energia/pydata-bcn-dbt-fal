from decouple import config
from novu.api import EventApi

event_api = EventApi("https://novu-api:3000/api/", config("NOVU_API_KEY"))

event_api.trigger(
    name="on-boarding-notification",
    recipients="6446cda01e1018fd0f5af967",
    payload={"message": "Welcome to Novu!"},
)


event_api.trigger(
    name="on-boarding-notification",
    recipients="on-boarding-subscriber-id-123",
    payload={"message": "Welcome to Novu!"},
)
