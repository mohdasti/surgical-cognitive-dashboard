# One-command deployment to shinyapps.io
# Requires environment variables: SHINYAPPS_ACCOUNT, SHINYAPPS_TOKEN, SHINYAPPS_SECRET

if (!requireNamespace("rsconnect", quietly=TRUE)) install.packages("rsconnect")
library(rsconnect)

# Get credentials from environment variables
acct   <- Sys.getenv("SHINYAPPS_ACCOUNT")
token  <- Sys.getenv("SHINYAPPS_TOKEN")
secret <- Sys.getenv("SHINYAPPS_SECRET")

# Validate credentials
stopifnot(nzchar(acct), nzchar(token), nzchar(secret))

# Set account info
rsconnect::setAccountInfo(name=acct, token=token, secret=secret)

# Deploy the app
cat("Deploying to shinyapps.io...\n")
rsconnect::deployApp(
  appName="surgical-cognitive-dashboard", 
  forceUpdate=TRUE
)

cat("Deployment complete! Check your shinyapps.io dashboard for the URL.\n")
