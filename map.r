
#Dependencies

library(purrr)
library(httr)
library(jsonlite)


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
str(commits)



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


