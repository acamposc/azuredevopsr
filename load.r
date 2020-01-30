##############
# google cloud authentication


# Dependencies
library(googleCloudStorageR)
library(gargle)
library(bigrquery)



#https://gargle.r-lib.org/articles/get-api-credentials.html#service-account-token
#http://code.markedmondson.me/googleCloudStorageR/articles/googleCloudStorageR.html#auto-authentication
gsa_path <- Sys.getenv("GOOGLE_SERVICE_ACCOUNT_PATH")
options(googleAuthR.scopes.selected = "https://www.googleapis.com/auth/cloud-platform")
gcs_auth(gsa_path)

#proof authentication works fine
gc_proj_id <- Sys.getenv("GOOGLE_CLOUD_PROJECT_ID")
buckets <- gcs_list_buckets(gc_proj_id)
buckets$name


#https://cran.r-project.org/web/packages/bigrquery/bigrquery.pdf
bq_auth(path = gsa_path)
bigquery_project_name <- bq_projects()


#bigquery fields
fields <- as_bq_fields(
  list(
    list(name = "commitId", type = "string"),
    list(name = "author_name", type = "string"),
    list(name = "author_email", type = "string"),
    list(name = "author_date", type = "timestamp"),
    list(name = "committer_name", type = "string"),
    list(name = "committer_email", type = "string"),
    list(name = "committer_date", type = "timestamp"),
    list(name = "comment", type = "string"),
    list(name = "commentTruncated", type = "string"),
    list(name = "changeCounts_Add", type = "integer"),
    list(name = "changeCounts_Edit", type = "integer"),
    list(name = "changeCounts_Delete", type = "integer"),
    list(name = "url", type = "string"),
    list(name = "remoteUrl", type = "string")
  )
)


#it is not currently working
#throws: Error: Unsupported type: list
fn_upload_job <- function(x){
  if(!require(bigrquery)){
    stop('bigrquery not installed')
  } else {
    values_json <- toJSON(commits_value[[x]])
    values_list <- fromJSON(values_json)
    values_bind <- cbind(values_list[3], values_list[4])
    values_bind <- toJSON(values_bind)
    values_data_frame <- fromJSON(values_bind)
    
    bigrquery::insert_upload_job( 
      project = gc_proj_id,
      dataset = 'test_dataset',
      table = 'attach-commits.test_dataset.AtmMiMovistarDesktop',
      #fields = fields,
      values = values_data_frame
    )
  }
}
upload_job <- map_dfr(rep(orgs, count_projs), fn_upload_job)



