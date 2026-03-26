# 1. Problem Description

**Context:** Biomass energy, derived from organic waste such as agricultural residues (e.g., sugarcane bagasse, corn stover), represents a massive but underutilized renewable energy source in Mexico. Efficient biomass power generation relies heavily on logistics: power plants must be geographically close to the raw material sources to be profitable and sustainable. 

**The Problem:** Currently, there is a significant data gap for renewable energy investors and policymakers in Mexico. The information required to identify optimal locations for new biomass plants is highly fragmented across different government entities. 
1. Agricultural production data (raw material potential) is isolated in the SIAP (Agri-Food and Fisheries Information Service) databases.
2. Installed clean energy capacity data is buried in historical archives from SEMARNAT/INEL, as primary energy portals often aggregate biomass alongside fossil fuels under generic "thermoelectric" labels.

Because these datasets live in silos, use different geographical naming conventions, and lack a unified architecture, it is nearly impossible to visualize the "untapped potential"—the states that generate millions of tons of agricultural waste but have zero installed biomass energy capacity.

**The Solution:** This project builds an automated, cloud-based batch data pipeline to solve this fragmentation. The pipeline extracts raw agricultural data and installed energy capacity data from their respective public sources, cleans and standardizes the geographical dimensions, and loads them into a centralized Data Warehouse. 

The final deliverable is an analytical dashboard that contrasts **Installed Biomass Capacity vs. Raw Material Potential** by state. This provides a clear, data-driven map of the untapped geographical potential for new biomass power plants in Mexico.

# 2. Cloud & Infrastructure as Code (IaC)

This project is fully developed in the cloud. The infrastructure, consisting of a Data Lake and a Data Warehouse, is hosted on **Google Cloud Platform (GCP)**. To ensure reproducibility and follow best practices, the infrastructure was provisioned using **Terraform** as our Infrastructure as Code (IaC) tool.

The deployment process was executed through the following 5 steps:

## Step 1: Verification

First, we verified that Terraform was correctly installed on the local machine (macOS) to execute the provisioning commands:

```bash
terraform -version
```

## Step 2: Authentication

To allow Terraform to interact securely with GCP, we granted temporary access to the local terminal using Google's Application Default Credentials (ADC):

```bash
gcloud auth application-default login
```

## Step 3: Defining Variables (`variables.tf`)

To avoid hardcoding and keep the project dynamic, we declared our project ID, region, and resource names in a variables file. 

*(Note: Sensitive information, such as the specific GCP Project ID, has been replaced with the placeholder `YOUR_PROJECT_ID` in this public repository).*

```hcl
variable "project" {
  description = "GCP Project ID"
  default     = "YOUR_PROJECT_ID"
  type        = string
}

variable "region" {
  description = "Region for the resources"
  default     = "us-central1"
  type        = string
}

variable "location" {
  description = "General geographic location for BigQuery and Cloud Storage"
  default     = "US"
  type        = string
}

variable "bq_dataset_name" {
  description = "BigQuery Dataset Name"
  default     = "biomass_analytics_dataset"
  type        = string
}

variable "gcs_bucket_name" {
  description = "Cloud Storage Bucket Name"
  default     = "data-lake-biomass-YOUR_PROJECT_ID"
  type        = string
}
```

## Step 4: Resource Creation (`main.tf`)

We wrote the declarative code to provision the required architecture:

1. **Data Lake:** A Google Cloud Storage (GCS) Bucket to hold the raw agricultural and energy data. We enforced `uniform_bucket_level_access` to comply with GCP security constraints.
2. **Data Warehouse:** A Google BigQuery dataset where the analytical transformations will take place.

```hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.6.0"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
}

# Data Lake Creation (Google Cloud Storage)
resource "google_storage_bucket" "data-lake-bucket" {
  name                        = var.gcs_bucket_name
  location                    = var.location
  force_destroy               = true
  uniform_bucket_level_access = true 

  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }
}

# Data Warehouse Creation (Google BigQuery)
resource "google_bigquery_dataset" "dataset" {
  dataset_id = var.bq_dataset_name
  location   = var.location
}
```

## Step 5: Deployment

Finally, the infrastructure was brought to life in the cloud by executing the standard Terraform workflow in the terminal:

1. `terraform init`: Initialized the working directory and downloaded the Google Cloud provider plugins.
2. `terraform plan`: Generated an execution plan, showing the 2 resources to be created.
3. `terraform apply`: Confirmed and executed the plan, successfully provisioning the Data Lake and Data Warehouse in GCP.
