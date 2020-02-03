##############
# google cloud authentication


# Dependencies
library(googleCloudStorageR)
library(gargle)
library(bigrquery)



#https://gargle.r-lib.org/articles/get-api-credentials.html#service-account-token
#http://code.markedmondson.me/googleCloudStorageR/articles/googleCloudStorageR.html#auto-authentication
gsa_path <- GOOGLE_SERVICE_ACCOUNT_PATH
options(googleAuthR.scopes.selected = "https://www.googleapis.com/auth/cloud-platform")
gcs_auth(gsa_path)

#proof authentication works fine
gc_proj_id <- GOOGLE_CLOUD_PROJECT_ID$V1
buckets <- gcs_list_buckets(gc_proj_id)
buckets$name


#https://cran.r-project.org/web/packages/bigrquery/bigrquery.pdf
bq_auth(path = gsa_path)
bigquery_project_name <- bq_projects()


