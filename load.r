##############
# google cloud authentication


# Dependencies
library(googleCloudStorageR)
library(bigQueryR)



#https://gargle.r-lib.org/articles/get-api-credentials.html#service-account-token
#http://code.markedmondson.me/googleCloudStorageR/articles/googleCloudStorageR.html#auto-authentication
gsa_path <- Sys.getenv("GOOGLE_SERVICE_ACCOUNT_PATH")
options(googleAuthR.scopes.selected = "https://www.googleapis.com/auth/cloud-platform")
gcs_auth(gsa_path)

#proof authentication works fine
gc_proj_id <- Sys.getenv("GOOGLE_CLOUD_PROJECT_ID")
buckets <- gcs_list_buckets(gc_proj_id)
buckets$name

#proof access to bigquery
#https://code.markedmondson.me/bigQueryR/
bqr_list_projects()
