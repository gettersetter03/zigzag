# ic
module "ic-service-account" {
  source     = "./modules/iam-service-account"
  project_id = var.project_id
  name       = "ic-service-account"
  iam_project_roles = {
     "${var.project_id}" = [
    "roles/artifactregistry.writer",
    "roles/artifactregistry.reader",
    "roles/run.invoker",
    "roles/storage.objectUser",
    "roles/storage.objectViewer",
    # "roles/storage.objectAdmin",
    # "roles/storage.admin",
    "roles/serviceusage.serviceUsageAdmin",
    "roles/iam.serviceAccountTokenCreator",
    "roles/logging.bucketWriter",
    "roles/logging.logWriter",
    "roles/vpcaccess.serviceAgent",
    "roles/compute.networkUser",
    "roles/vpcaccess.user",
    
    ]
  }
}
module "ic-cr-service-account" {
  source     = "./modules/iam-service-account"
  project_id = var.project_id
  name       = "ic-cr-service-account"
  iam_project_roles = {
     "${var.project_id}" = [
    "roles/eventarc.eventReceiver",
    "roles/pubsub.publisher",
    "roles/run.invoker",
    "roles/storage.objectViewer",
    ]
  }
}

module "ic-cr" {
  source     = "./modules/cloudrun"
  project_id = var.project_id
  name       = "ic-cr-zigzag"
  service_account = module.ic-service-account.email

  containers = {
    "container" = {
      env = {
        INTERCONNECT_BUCKET_NAME = module.ic-bucket.name
      }
      "image" = "${var.region}-docker.pkg.dev/${var.project_id}/ic-artifact-registry/puppeteer:latest",
      "resources" = {
        limits = {
          "memory" = "2Gi"
          "cpu"    = "2"
        }
      }
    }
  }

   # Attach VPC Connector
  revision = {
    vpc_access = {
      connector = one(module.ic-serverless-connector.connector_ids)  # Reference the VPC Connector
      vpc       = "ic-vpc"                 # VPC Network Name
      subnet    = null               # Subnet Name (optional)
      tags      = null         # Optional network tags
    }
  }
  
  eventarc_triggers = {
    gcs_bucket = {      
      "ic-trigger" = {
        type        = "google.cloud.storage.object.v1.finalized"
        bucket_name = module.ic-bucket.name
      },
    }
    service_account_email = module.ic-cr-service-account.email
  }
  
}

module "ic-artifact-registry" {
  source        = "./modules/artifact-registry-fabric"
  project_id    = var.project_id
  location      = var.region
  format        = { docker = { standard = {} } }
  name = "ic-artifact-registry"
}


module "ic-bucket" {
  source     = "./modules/gcs-flash"
  project_id = var.project_id
  name       = "ic-gcs"
  prefix = var.project_id
  location   = var.region
  force_destroy = true
  //storage_users = [module.ic-service-account.iam_email]
  managed_folders = {
    
    codes = {
      force_destroy = true
      iam = {
        "roles/storage.objectUser" = [module.trusted-service-account.iam_email,module.ic-service-account.iam_email]
        # "roles/storage.objectUser" = [module.ic-service-account.iam_email]
      }
    }
    files = {
      force_destroy = true
      iam = {
        "roles/storage.objectUser" = [module.trusted-service-account.iam_email,module.ic-service-account.iam_email]
        # "roles/storage.objectUser" = [module.ic-service-account.iam_email]
      }
    }
  }
}

module "ic-serverless-connector" {
  source     = "./modules/vpc-serverless-connector-beta"
  project_id = var.project_id

  vpc_connectors = [{
    name           = "ic-vpc-connector"
    region         = "me-west1"
    network        = "ic-vpc"
    subnet_name    = null
    ip_cidr_range  = "10.8.0.0/28"
    host_project_id = var.project_id
    machine_type   = "e2-micro"
    min_instances  = 2
    max_instances  = 10
    # max_throughput = 300
  }]
}

# module "gcp-azure-ha-vpn" {
#   source = "./modules/gcp-azure-ha-vpn"
#   gcp_vpc_name   = var.gcp_vpc_name
#   gcp_region = var.gcp_region
#   gcp_project_id = var.project_id
#   gcp_bgp_asn = var.gcp_bgp_asn
#   gcp_router_name = var.gcp_router_name
#   azure_public_ip_1 = var.azure_public_ip_1
#   azure_public_ip_2 = var.azure_public_ip_2
#   shared_secret = 
# }


module "ic-vpc" {
  source       = "./modules/net-vpc"
  name = "ic-vpc"
  project_id   = var.project_id

  subnets = [
    {
      name   = "ic-subnet"
      ip_cidr_range   = "10.71.69.0/24"
      region = var.region
      private_ip_google_access = true
    },
  ]
}

# trusted
module "trusted-service-account" {
  source     = "./modules/iam-service-account"
  project_id = var.project_id_trusted
  name       = "zigzag-trusted-service-account"
  iam_project_roles = {
    "${var.project_id_trusted}" = [
    "roles/artifactregistry.writer",
    "roles/artifactregistry.reader",
    "roles/run.invoker",
    "roles/serviceusage.serviceUsageAdmin",
    "roles/iam.serviceAccountTokenCreator",
    "roles/vpcaccess.serviceAgent",
    "roles/storage.objectUser",
    "roles/compute.networkUser",
    "roles/vpcaccess.user"
  ],
    "${var.project_id}" = [
    "roles/storage.objectUser",
  ]
  }
}
module "trusted-cr-service-account" {
  source     = "./modules/iam-service-account"
  project_id = var.project_id_trusted
  name       = "trusted-cr-service-account"
  iam_project_roles = {
    "${var.project_id_trusted}" = [
      "roles/eventarc.eventReceiver",
      "roles/pubsub.publisher",
      "roles/run.invoker",
      "roles/storage.objectViewer"
  ]
  }
}

# share with 9900
module "trusted-bucket" {
  source     = "./modules/gcs-flash"
  project_id = var.project_id_trusted
  prefix = var.project_id_trusted
  name       = "trusted-gcs"
  location   = var.region
  force_destroy = true
  managed_folders = {
    
    codes = {
      force_destroy = true
      iam = {
        "roles/storage.objectUser" = [module.trusted-service-account.iam_email]
      }
    }
    files = {
      force_destroy = true
      iam = {
        "roles/storage.objectUser" = [module.trusted-service-account.iam_email]
      }
    }
  }
}


module "trusted-cr" {
  source     = "./modules/cloudrun"
  project_id = var.project_id_trusted
  name       = "td-cr-zigzag"
  service_account = module.trusted-service-account.email
  containers = {
    "container" = {
      env = {
        IC_BUCKET_NAME = module.ic-bucket.name
        IC_PROJECT_NAME      = var.project_id
        TRUSTED_PROJECT_NAME = var.project_id_trusted
        TRUSTED_BUCKET = module.trusted-bucket.name
      }
      "image" = "${var.region}-docker.pkg.dev/${var.project_id_trusted}/trusted-artifact-registry/copypasta:latest",
      "resources" = {
        limits = {
          "memory" = "2Gi"
          "cpu"    = "2"
        }
      }
      timeout = "3600s"
    }
  }
  revision = {
    vpc_access = {
      vpc    = "projects/${var.shared_vpc_project}/global/networks/${var.shared_vpc}"
      subnet = "projects/${var.shared_vpc_project}/regions/${var.region}/subnetworks/${var.shared_subnet}"
    }
    max_instance_count = 1
    min_instance_count = 1
  }

  eventarc_triggers = {
    gcs_bucket = {
      "trusted-trigger"= {
        type        = "google.cloud.storage.object.v1.finalized"
        bucket_name = module.trusted-bucket.name
      }
    }
    service_account_email = module.trusted-cr-service-account.email
  }
  
}

module "trusted-artifact-registry" {
  source        = "./modules/artifact-registry-fabric"
  project_id    = var.project_id_trusted
  location      = var.region
  format        = { docker = { standard = {} } }
  name = "trusted-artifact-registry"
}
