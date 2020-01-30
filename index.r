#DEPRECATED
#See map.r instead

#https://github.com/acamposc/azuredevopsr

#https://docs.microsoft.com/en-us/rest/api/azure/devops/build/resources/list?view=azure-devops-rest-5.1#uri-parameters
#https://dev.azure.com/AtmMiMovistar/Desktop

#dependencies
library(jsonlite)
library(httr)
library(xml2)
library(usethis)
library(dplyr)
library(stringr)
library(bigQueryR)
#library(gargle)
library(googleCloudStorageR)



#credentials
#https://rstats.wtf/r-startup.html
#https://www.dartistics.com/renviron.html
#https://community.rstudio.com/t/how-to-set-a-variable-in-renviron/5029/2
#usethis::edit_r_environ()

az_pat <- Sys.getenv("AZURE_PAT")

#authentication
#https://rdrr.io/cran/httr/man/authenticate.html
#https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&tabs=preview-page#use-your-personal-access-token

#uri parameters https://docs.microsoft.com/en-us/rest/api/azure/devops/build/resources/list?view=azure-devops-rest-5.1#uri-parameters
org <- c("AtmMiMovistar")
proj <- c("Desktop")

#GET https://dev.azure.com/{organization}/{project}/_apis/git/repositories?api-version=5.1

url <- paste0("https://dev.azure.com/", org, "/", proj,"/_apis/git/repositories?api-version=5.1")
#url

resp <- GET(url, authenticate(user = az_pat, password = az_pat))
#resp

http_type(resp)
#content(resp)


#https://stackoverflow.com/questions/11530217/in-r-extract-part-of-object-from-list
resp_body <- sapply(content(resp), "[[", 1)
resp_body_repo_url <- resp_body$value[3]
resp_body_repo_url <- resp_body_repo_url
#resp_body_repo_url <- resp_body_repo_url[[1]]

repo_resp <- GET(url = paste0(resp_body_repo_url, "/commits"), authenticate(user = az_pat, password = az_pat))
#repo_resp

http_type(repo_resp)
commits <- content(repo_resp)
#str(commits$value)

#https://stackoverflow.com/questions/36454638/how-can-i-convert-json-to-data-frame-in-r
commits <- toJSON(commits$value)
commits <- fromJSON(commits)
#str(commits)


#strsplit(unlist(commits$committer$date[1]), "T")

#   test<-str_split_fixed(commits$committer$date, "T", 2)
#   test
#pending: binding cols from df to list format

##############
#google cloud authentication
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


dataset_id <- bqr_list_datasets(projectId = gc_proj_id)
#create tables pending due to lack of template_data. More info on: ?bqr_create_table
#bqr_create_table(projectId = gc_proj_id, datasetId = dataset_id$id, tableId = paste0(org, "-", proj))

#upload dataframe to google cloud storage as csv
#http://code.markedmondson.me/googleCloudStorageR/reference/gcs_upload.html
gcs_upload(file = commits, bucket = buckets$name)


#create table manually from gcs

bqr_list_datasets(projectId = gc_proj_id)
datasetId = bqr_list_datasets(projectId = gc_proj_id)
bigquery_table <- bqr_list_tables(projectId = gc_proj_id, datasetId = "test_dataset")
bigquery_table$id
