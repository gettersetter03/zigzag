# ic

module "ic-service-account" {
  source     = "./modules/service-account"
  project_id = var.project_id
  name       = "ic-service-account"
  project_roles = [
    "roles/artifactregistry.writer",
    "roles/artifactregistry.reader",
    "roles/run.invoker",
    "roles/storage.objectUser",
    "roles/storage.objectViewer",
    "roles/storage.objectAdmin",
    "roles/storage.objectAdmin",
    "roles/storage.admin",
    "roles/serviceusage.serviceUsageAdmin",
    "roles/iam.serviceAccountTokenCreator",
    "roles/logging.bucketWriter",
    "roles/logging.logWriter",
    "roles/vpcaccess.serviceAgent",
  ]
}

module "ic-cr" {
  source     = "./modules/cloudrun"
  project_id = var.project_id
  name       = "ic-cr-zigzag"
  containers = {
    "container" = {
      "image" = "${var.region}-docker.pkg.dev/${var.project_id}/ic-artifact-registry/zigzag:latest",
      "resources" = {
        limits = {
          "memory" = "2Gi"
          "cpu"    = "2"
        }
      }
    }
  }
  revision = {
    name = "hey2"
    vpc_access = {
      vpc    = module.ic-vpc.network_name
      subnet = "ic-subnet"
    }
    max_instance_count = 1
    min_instance_count = 1
  }

  eventarc_triggers = {
    gcs_bucket = {
      module.ic-bucket.names[keys(module.ic-bucket.names)[0]] = {
        type        = "google.cloud.storage.object.v1.finalized"
        bucket_name = module.ic-bucket.names[keys(module.ic-bucket.names)[0]]
      }
    }
    service_account_create = true
  }
  service_account = module.ic-service-account.email
}

module "ic-bucket" {
  source     = "terraform-google-modules/cloud-storage/google"
  project_id = var.project_id
  names      = ["ic-gcs-zigzag"]
  location   = var.region
  storage_admins    = [module.trusted-service-account.iam_email]
  set_admin_roles   = true
}

module "ic-vpc" {
  source       = "terraform-google-modules/network/google"
  project_id   = var.project_id
  network_name = "ic-vpc"
  subnets = [
    {
      subnet_name   = "ic-subnet"
      subnet_ip     = "10.71.69.0/24"
      subnet_region = var.region
    },
  ]
}

module "ic-artifact-registry" {
  source        = "GoogleCloudPlatform/artifact-registry/google"
  project_id    = var.project_id
  location      = var.region
  format        = "DOCKER"
  repository_id = "ic-artifact-registry"
}

# trusted

# share with 9900
module "trusted-bucket" {
  source     = "terraform-google-modules/cloud-storage/google"
  project_id = var.project_id_trusted
  names      = ["trusted-gcs-zigzag"]
  location   = var.region
  folders = {
    "trusted-gcs-zigzag" = ["codes","files"]
  }
}

module "trusted-cr" {
  source     = "./modules/cloudrun"
  project_id = var.project_id_trusted
  name       = "td-cr-zigzag"
  containers = {
    "container" = {
      env = {
        IC_BUCKET_NAME = module.ic-bucket.names[keys(module.ic-bucket.names)[0]]
        IC_PROJECT_NAME      = var.project_id
        TRUSTED_PROJECT_NAME = var.project_id_trusted
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
    name = "hey33"
    vpc_access = {
      vpc    = "projects/${var.shared_vpc_project}/global/networks/${var.shared_vpc}"
      subnet = "projects/${var.shared_vpc_project}/regions/${var.region}/subnetworks/${var.shared_subnet}"
    }
    max_instance_count = 1
    min_instance_count = 1
  }

  eventarc_triggers = {
    gcs_bucket = {
      module.trusted-bucket.names[keys(module.trusted-bucket.names)[0]] = {
        type        = "google.cloud.storage.object.v1.finalized"
        bucket_name = module.trusted-bucket.names[keys(module.trusted-bucket.names)[0]]
      }
    }
    service_account_create = true
  }
  service_account = module.trusted-service-account.email
}

module "trusted-service-account" {
  source     = "./modules/service-account"
  project_id = var.project_id_trusted
  name       = "zigzag-trusted-service-account"
  project_roles = [
    "roles/artifactregistry.writer",
    "roles/artifactregistry.reader",
    "roles/run.invoker",
    "roles/storage.objectUser",
    "roles/serviceusage.serviceUsageAdmin",
    "roles/iam.serviceAccountTokenCreator",
    # "roles/logging.bucketWriter",
    # "roles/logging.logWriter",
    "roles/vpcaccess.serviceAgent",
    "roles/storage.objectCreator",
    "roles/storage.objectCreator",

  ]
}

module "trusted-artifact-registry" {
  source        = "GoogleCloudPlatform/artifact-registry/google"
  project_id    = var.project_id_trusted
  location      = var.region
  format        = "DOCKER"
  repository_id = "trusted-artifact-registry"
}
