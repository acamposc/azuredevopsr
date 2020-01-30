
#Dependencies

library(purrr)
library(httr)
library(jsonlite)


#Environment vars
az_pat <<- Sys.getenv("AZURE_PAT")


##########

orgs <- list(
  org_mi_movistar = 'AtmMiMovistar',
  org_movistar_publica = 'AtmMovistar',
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
str(orgs)

##########
#https://adv-r.hadley.nz/functionals.html
fn <- function(x){
  print(x)
}

chrr<-map_chr(orgs, fn)
##########

# List organization's projects
# https://docs.microsoft.com/en-us/rest/api/azure/devops/core/projects/list?view=azure-devops-rest-5.1


#url <- paste0("https://dev.azure.com/", org,"/_apis/projects?api-version=5.1")

############
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
  if(!require(purrr)){
    stop("purrr not installed")
  } else {
    projs <- rawToChar(az_dev_org_urls[x][[1]]$content)
    projs_json <- fromJSON(projs)
    projs_json_names <- projs_json$value$name
    
  }}
nms <- map(org_count, fn_names)
nms

############
# 



