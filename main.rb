require './market_session'

# For debugging with Charles
# RestClient.proxy = "http://127.0.0.1:8888"
session = MarketSession.new
session.login("Google User", "Google Password")
apps_request = AppsRequest.new
apps_request.query = "birds"
apps_request.startIndex = 0
apps_request.entriesCount = 10
apps_request.withExtendedInfo = true
session.append(apps_request)
session.flush
