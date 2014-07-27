require './market_session'

# For debugging with Charles
RestClient.proxy = "http://127.0.0.1:8888"
apps_request = AppsRequest.new
apps_request.query = "birds"
apps_request.startIndex = 0
apps_request.entriesCount = 5
apps_request.withExtendedInfo = true

group = Request::RequestGroup.new
group.appsRequest = apps_request

session = MarketSession.new
session.login("Google Username", "Google Password")
session.execute(group)