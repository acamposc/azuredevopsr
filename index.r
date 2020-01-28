#https://github.com/acamposc/azuredevopsr

#https://docs.microsoft.com/en-us/rest/api/azure/devops/build/resources/list?view=azure-devops-rest-5.1#uri-parameters
#https://dev.azure.com/AtmMiMovistar/Desktop

#dependencies
library(jsonlite)
library(httr)
library(xml2)
library(usethis)
library(plyr)

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
str(commits$value)

author <- lapply(commits$value, "[", 'author')
is.list(author)
str(author)
author <- lapply(author, '[', 1)
author
