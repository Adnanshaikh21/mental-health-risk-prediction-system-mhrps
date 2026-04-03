pr <- plumb("api/test_plumber.R")
logger("Plumber API initialized")
pr$run(host = "0.0.0.0", port = 8001)