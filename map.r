
#Dependencies

library(purrr)
library(httr)
library(jsonlite)
library(dplyr)
library(DBI)



source('load.r')

#Environment vars
az_pat <<- Sys.getenv("AZURE_PAT")


##########

orgs <- list(
  org_mi_movistar = 'AtmMiMovistar',
  #org_movistar_publica = 'AtmMovistar',
  org_banco_falabella = 'AtmBancoFalabella',
  org_esan= 'AtmESAN',
  org_estilos = 'AtmEstilosPE',
  org_incarail = 'AtmIncaRail',
  org_mapfre_peru = 'AtmMapfre',
  org_royal = 'AtmRoyal',
  org_tls = 'AtmToulouse',
  org_ucal = 'AtmUCAL',
  org_attach = 'Attach'
  
)


##########
#https://adv-r.hadley.nz/functionals.html


##########

# List organization's projects
# https://docs.microsoft.com/en-us/rest/api/azure/devops/core/projects/list?view=azure-devops-rest-5.1


#Fetch all projects within organizations
fn <- function(x){
  if(!require(httr)){
    stop("httr not installed")
  } else {
  
  GET(
    paste0(
      "https://dev.azure.com/",
      x,
      "/_apis/projects?api-version=5.1"
    ),
    authenticate(user = az_pat, password = az_pat)
  )
  }
}
az_dev_org_urls<-map(orgs, fn)

#returned a list of responses
#str(az_dev_org_urls)
############



############
# Set up content names
org_count <- 1:length(az_dev_org_urls)
fn_names <- function(x){
  if(!require(jsonlite)){
    stop("jsonlite not installed")
  } else {
    projs <- rawToChar(az_dev_org_urls[x][[1]]$content)
    projs_json <- fromJSON(projs)
    projs_json_names <- projs_json$value$name
    
  }}
nms <- map(org_count, fn_names)


############
# List project names
org_count <- length(nms)

fn_repo_projs <- function(x){
   nms[1:x]

}
repo_projs_list <- map(org_count, fn_repo_projs)
#repo_projs_list <- repo_projs_list[[1]]
#repo_projs_list[[2]]


############
#Count projects from project list
#It is really unnecessary, use "org_count" instead.
fn_count_projs <- function(x){
  length(repo_projs_list[[1]][[x]])
}
count_projs <- map(1:org_count, fn_count_projs)
#str(count_projs)

############

#Request all repo content.
#GET https://dev.azure.com/{organization}/{project}/_apis/git/repositories?api-version=5.1
fn_repos <- function(x, y){
  if(!require(httr)){
    stop('httr not installed')
  } else {
    
    GET(
     paste0(
        "https://dev.azure.com/",
        x,
        "/",
        y,
        "/_apis/git/repositories?api-version=5.1"
      ),
      authenticate(user = az_pat, password = az_pat)
    )
  }
}

#https://purrr.tidyverse.org/reference/map2.html
#gsub() used to replace url whitespaces for the requests.
az_dev_repos_urls <- map2(.x = rep(orgs, count_projs) , .y = gsub(" ", "%20", unlist(repo_projs_list[[1]])), .f = fn_repos)

#typeof(az_dev_repos_urls)
#str(az_dev_repos_urls)


############
#extract repo id and request for the commits data

length_az_repos_urls <- 1:length(az_dev_repos_urls)
extract_repo_id <- function(x){
  if(!require(jsonlite)){
    stop("jsonlite not installed")
  } else {
    body <- rawToChar(az_dev_repos_urls[x][[1]]$content)
    body <- fromJSON(body)
    body <- body$value$url
    
  } 
}

proj_urls <- map(length_az_repos_urls, extract_repo_id)

############

# Retrieve commits and place them in memory.

fn_retrieve_commits <- function(x){
  if(!require(httr)){
    stop("httr not installed")
  } else {
    GET(
      paste0(
        proj_urls[x], 
        "/commits"
      ),
      authenticate(
        user = az_pat,
        password = az_pat
      )
    )
  }
}
retrieve_commits <- map(length_az_repos_urls, fn_retrieve_commits)

fn_commits <- function(x){
  if(!require(jsonlite)){
    stop("jsonlite not installed")
  } else {
    commits <- rawToChar(retrieve_commits[x][[1]]$content)
    commits <- fromJSON(commits)
    #commits <- commits[[x]]$value
    #commits <- toJSON(commits)
    #commits <- fromJSON(commits)
  }
}
commits <- map(length_az_repos_urls, fn_commits)
#str(commits)



# commits holds the values meant to be loaded in bigquery.
############

# Write a json object file in working directory.
# Function has been disabled.

fn_export_json <- function(){
  if(!require(jsonlite)){
    stop("jsonlite not installed")
  } else {
    export_json <- toJSON(commits)
    write(export_json, "commits.json")
    
  }
}

# fn_export_json()

############
#fn_commits_dataframe creates a list of dataframes

fn_commits_dataframe <- function(x){
  commits <- commits[[x]]$value
  commits <- toJSON(commits)
  commits <- fromJSON(commits)
}
commits_value <- map(length_az_repos_urls, fn_commits_dataframe)


##############
# creating dataframes
# bigquery::insert_upload_job only accepts dataframes

# generate a list
fn_df_commits_list <- function(x){
  if(!is.list(commits_value)){
    stop('commits_value is not a list!!!')
  } else {
    commits_json <- toJSON(commits_value[[x]])
    commits_list <- fromJSON(commits_json)
    
  }
}
commits_list <- map(length_az_repos_urls,fn_df_commits_list)
is.list(commits_list)
length(commits_list)

# reduce data
fn_df_commits_dataframe <- function(x){
  if(!require(dplyr)){
    stop("dplyr not installed")
  } else {
    json_list1 <- toJSON(commits_list[[x]][3])
    json_list1 <- fromJSON(commits_list[[x]][3])
    json_list2 <- toJSON(commits_list[[x]][4])
    json_list2 <- fromJSON(commits_list[[x]][4])
    
    commits_bind <- bind_cols(!!!
        commits_list1[[x]][3],
        commits_list2[[x]][4]
      )
    #commits_bind <- toJSON(commits_bind)
    commits_comm <- commits_bind
  
  }
}
commits_comm <- map(length_az_repos_urls,fn_df_commits_dataframe)


###########
# set column names to the list
fn_column_names <- function(x, y){
  column_names <- c("commiter_name", "commiter_email", "commiter_date", "comment")
  colnames(commits_comm[x]) <- column_names
}
column_names <- map( , fn_column_names)

###########
# upload data to bigquery
# https://rdrr.io/cran/bigrquery/man/api-perform.html


# bigquery fields
# not using this yet.
fields <- 
  #bq_fields(
  list(
    #list(name = "commitId", type = "string"),
    #list(name = "author_name", type = "string"),
    #list(name = "author_email", type = "string"),
    #list(name = "author_date", type = "timestamp"),
    list(name = "committer_name", type = "string"),
    list(name = "committer_email", type = "string"),
    list(name = "committer_date", type = "timestamp"),
    list(name = "comment", type = "string")
    #list(name = "commentTruncated", type = "string"),
    #list(name = "changeCounts_Add", type = "integer"),
    #list(name = "changeCounts_Edit", type = "integer"),
    #list(name = "changeCounts_Delete", type = "integer"),
    #list(name = "url", type = "string"),
    #list(name = "remoteUrl", type = "string")
  )
#)



fn_upload_job <- function(x){
  if(!require(bigrquery)){
    stop('bigrquery not installed')
  } else {

    
    bq_perform_upload(
      x = "attach-commits.test_dataset.atmCommitsTest",
      values = commits_comm[[x]],
      fields = fields,
      create_disposition = "CREATE_IF_NEEDED",
      write_disposition = "WRITE_APPEND",
      billing = gc_proj_id
    )
  }
}
# upload_job <- map_dfr(rep(orgs, count_projs), fn_upload_job)
upload_job <- map(22, fn_upload_job)
# creates an empty table in bigquery. 
# :(


####dbi

# connection: https://rdrr.io/cran/bigrquery/man/bigquery.html
# upload data: https://rdrr.io/cran/DBI/man/dbAppendTable.html 
# connection: https://db.rstudio.com/databases/big-query/

# DBI - Bigquery connection:

fn_connect_to_bigquery <-function(){
  con <<- DBI::dbConnect(
    bigrquery::bigquery(),
    project = gc_proj_id,
    dataset = 'test_dataset',
    billing = gc_proj_id
  )
}
fn_connect_to_bigquery()
# only once


fn_dbi_upload_job <- function(x){
  if(!require(DBI)){
    stop('DBI not installed')
  } else {
    bq_tbl <-  DBI::dbListTables(conn = con)  
    
    DBI::dbWriteTable(
     conn = con,
     name = c(bq_tbl[-1]),
     value = commits_comm[[22]],
     overwrite = TRUE,
     row.names = FALSE
   )
  }
}
#upload_job <- map_dfr(rep(orgs, count_projs), fn_upload_job)
upload_dbi_job <- map(22, fn_dbi_upload_job)

