yaml <-
  if(!require(googleCloudRunner)){
    stop("googleCloudRunner not installed")
  } else {
    
    cr_build_yaml(
      steps = c(
        cr_buildstep_decrypt(
          id = "decrypt azure_pat",
          cipher = "AZURE_PAT.txt.enc",
          plain = "/AZURE_PAT.txt",
          keyring = "attach-key-ring",
          key = "azure-devops-commits",
          location = "us-central1"
        ),        
        cr_buildstep_decrypt(
          id = "decrypt gc_proj_id",
          cipher = "GOOGLE_CLOUD_PROJECT_ID.txt.enc",
          plain = "/GOOGLE_CLOUD_PROJECT_ID.txt",
          keyring = "attach-key-ring",
          key = "azure-devops-commits",
          location = "us-central1"
        ),
        cr_buildstep_decrypt(
          id = "decrypt gsa_path",
          cipher = "attach-commits-fa50e59d273d.json.enc",
          plain = "/attach-commits-fa50e59d273d.json",
          keyring = "attach-key-ring",
          key = "azure-devops-commits",
          location = "us-central1"
        ),
        cr_buildstep_decrypt(
          id = "decrypt dataset_name",
          cipher = "GOOGLE_BIGQUERY_DATASET_NAME.TXT.enc",
          plain = "/GOOGLE_BIGQUERY_DATASET_NAME.TXT",
          keyring = "attach-key-ring",
          key = "azure-devops-commits",
          location = "us-central1"
        ),
        cr_buildstep_decrypt(
          id = "decrypt table_name",
          cipher = "GOOGLE_BIGQUERY_TABLE_NAME.txt.enc",
          plain = "/GOOGLE_BIGQUERY_TABLE_NAME.txt",
          keyring = "attach-key-ring",
          key = "azure-devops-commits",
          location = "us-central1"
        ),
        cr_buildstep_r(
          r = "packages.r",
          name = "rocker/verse:3.6.1",
          r_source = c("runtime"),
          #prefix = "rocker/",
          waitFor = c("-")
        ),
        cr_buildstep_r(
          r = "map.r",
          name = "rocker/verse:3.6.1",
          r_source = c("runtime"),
          #prefix = "rocker/",
          waitFor = c("-")
        )
      ), 
      timeout = 900
    )
  }


#cr_build(cr_build_make(yaml), projectId = gc_proj_id)

cr_build_write(x = yaml, file = "cloudbuild.yaml")






