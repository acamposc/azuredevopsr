
install.packages(
  c("googleCloudStorageR",
    "gargle",
    "bigrquery",
    "purrr",
    "httr",
    "jsonlite",
    "dplyr",
    "RJSONIO",
    "data.table",
    "data.tree",
    "devtools",
    "readr"
  )
) 


#Dependencies

library(purrr)
library(httr)
library(jsonlite)
library(dplyr)
library(RJSONIO)
library(data.table)
library(data.tree)
library(readr)


source('map_ks.r')
source('load.r')

#Environment vars
az_pat <<- AZURE_PAT


##########

orgs <- list(
  org_mi_movistar = 'AtmMiMovistar',
  #org_movistar_publica = 'AtmMovistar',
  org_banco_falabella = 'AtmBancoFalabella',
  org_esan= 'AtmESAN',
  org_estilos = 'AtmEstilosPE',
  org_incarail = 'AtmIncaRail',
  #org_mapfre_peru = 'AtmMapfre',
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
fn_names <- function(x,y){
  if(!require(jsonlite)){
    stop("jsonlite not installed")
  } else {
    projs <- rawToChar(az_dev_org_urls[x][[1]]$content)
    projs_json <- jsonlite::fromJSON(projs)
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
    body <- jsonlite::fromJSON(body)
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
    commits <- jsonlite::fromJSON(commits)
    commits 
  }
}
commits <- map(length_az_repos_urls, fn_commits)
#str(commits)



# commits holds the values meant to be loaded in bigquery.
############

############
#fn_commits_dataframe creates a list of dataframes

fn_commits_dataframe <- function(x){
  commits <- commits[[x]]$value

}
commits_value <- map(length_az_repos_urls, fn_commits_dataframe)

##############
# select columns and bind rows in order to have one big tibble.
# https://stackoverflow.com/questions/5234117/how-to-drop-columns-by-name-in-a-data-frame
# https://stackoverflow.com/questions/15059285/row-binding-a-set-of-data-sets

desired_cols <- c("commitId", "author", "committer", "comment", "changeCounts", "url", "remoteUrl")
fn_select_cols <- function(x){
  selected_cols <- commits_value[[x]][,desired_cols]
}
commits_value <- map(length_az_repos_urls,fn_select_cols)


# manipulate json
# https://gist.github.com/gluc/5f780246d57897b57c6b

fn_jsn_tbl <- function(x){
  if(!require(data.tree)){
    stop("data.tree not installed")
  } else {
    repos <- jsonlite::toJSON(commits_value)
    repos <- jsonlite::fromJSON(repos, simplifyDataFrame = FALSE)
    
    repos <- as.Node(repos)
    #print(repos, 'commitId', 'date')

    reposdf <- data.tree::ToDataFrameTable(x = repos,
                                           'commitId',
                                           'email',
                                           'comment',
                                           'Add', 'Edit', 'Delete',
                                           'url', 'remoteUrl', 'date')
    
    # deduplicate, summarise rows and remove NAs.
    # https://stackoverflow.com/questions/40820120/merging-two-rows-with-some-having-missing-values-in-r
    
    if(!require(dplyr)){
      stop('dplyr not installed')
    } else {
      
      reposdf <<- 
        reposdf %>%
        group_by(commitId, comment, url, remoteUrl) %>%
        summarise(
          email = max(email, na.rm = TRUE),
          date = max(date, na.rm = TRUE),
          Add = max(Add, na.rm = TRUE),
          Edit = max(Edit, na.rm = TRUE),
          Delete = max(Delete, na.rm = TRUE)
        )
    }
    
    #write.csv(reposdf, file = 'reposdf.csv')
  }
}
#jsn_tbl <- map(length_az_repos_urls, fn_jsn_tbl)
fn_jsn_tbl()

fn_repos_org_proj <- function(){
  if(!require(data.table)){
    stop("data.table not installed")
  } else {
    remote_sep <- read.table(text = reposdf$remoteUrl, sep = "/", colClasses = "character")
    az_org <- remote_sep$V4
    az_proj <- remote_sep$V5
    
    reposdf$org <- az_org
    reposdf$proj <- az_proj
    op <- options(digits.secs = 6)
    reposdf$timestamp <- Sys.time()
    
    reposdf <<- reposdf
  }
}

fn_repos_org_proj()
###########
# upload data to bigquery
# https://rdrr.io/cran/bigrquery/man/api-perform.html


# bigquery fields

fields <- 
  
  list(
    list(name = "commitId", type = "string",     description = "Azure Repos commit id"),
    list(name = "email", type = "string",        description = "Committer email"),
    list(name = "comment", type = "string",      description = "Comment"),
    list(name = "Add", type = "integer",         description = "Commiter adds"),
    list(name = "Edit", type = "integer",        description = "Committer edits"),
    list(name = "Delete", type = "integer",      description = "Committer deletes"),
    list(name = "url", type = "string",          description = "Repo API url"),
    list(name = "remoteUrl", type = "string",    description = "Remote url"),
    list(name = "date", type = "timestamp",      description = "Declares when a change has been made"),
    list(name = "org", type = "string",          description = "Azure Repos organization id"),
    list(name = "proj", type = "string",         description = "Azure Repos project id within a organization"),
    list(name = "timestamp", type = "timestamp",  description = "Upload time, may be of use to max() this value to avoid duplicates")
    #list(name = "commentTruncated", type = "string"),
  )


##############
#create table, works like a charm.

bq_proj_name <- gc_proj_id
bq_dataset_name <- GOOGLE_BIGQUERY_DATASET_NAME
bq_tbl <- GOOGLE_BIGQUERY_TABLE_NAME
bq_table_name <- paste0(
  bq_proj_name,
  ".",
  bq_dataset_name,
  ".",
  bq_tbl
)




fn_bq_table_create <- function(x){
  if(bq_table_exists(x)){
    stop("bigquery table already exists")
  } else {
  
  bq_table_create(
    x = x,
    fields = as_bq_fields(fields)
  )
}}
fn_bq_table_create(bq_table_name)
##############


fn_bq_tbl_upload <- function(){
  if(!require(bigrquery)){
    stop("bigrquery not installed")
  } else {
    tb <- bq_table(
      project = bq_proj_name,
      dataset = bq_dataset_name,
      table = bq_tbl
    )
    
    dfr <- reposdf
    
    bq_table_upload(tb, dfr)
    
  }
  
}
tbl_upload <-  fn_bq_tbl_upload()

##
# next steps: review data in bigquery.
