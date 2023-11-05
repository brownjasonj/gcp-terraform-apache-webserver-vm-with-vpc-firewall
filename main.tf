locals {
  project_id = "udemy-401715"
  region     = "us-central1"
  zone       = "us-central1-b"
}

provider "google" {
  project = local.project_id
  region  = local.region
  zone    = local.zone
}

# This enables the Compute Engine API for the project. Which is required to be able to create a resources (e.g., VPC, VMs)
resource "google_project_service" "compute_service" {
  project = local.project_id
  service = "compute.googleapis.com"
}

# Create a Virtual Private Network (VPC) to place the VM in
resource "google_compute_network" "vpc_network" {
  name                    = "my-custom-mode-network"
  auto_create_subnetworks = false
  mtu                     = 1460
  depends_on = [
    # In order to be able to create VPC the GoogleAPIs need to have been enabled.
    google_project_service.compute_service
  ]
}

resource "google_compute_subnetwork" "default" {
  name          = "my-custom-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = local.region
  network       = google_compute_network.vpc_network.id
}

# Create a single Compute Engine instance
resource "google_compute_instance" "default" {
  name         = "apache-webserver-vm-modified"
  machine_type = "f1-micro"
  zone         = local.zone
  tags         = ["ssh"]

  boot_disk {
    initialize_params {
      image = "projects/debian-cloud/global/images/debian-11-bullseye-v20231010"
      size  = 10
    }
    mode = "READ_WRITE"
  }

  # Install Flask
  //  metadata_startup_script = "sudo apt-get update; sudo apt-get install -yq build-essential python3-pip rsync; pip install flask"

  metadata_startup_script = "sudo apt-get update; sudo apt-get install -y apache2; echo \"Hello world from $(hostname) $(hostname -I)\" > /var/www/html/index.html"

  network_interface {
    subnetwork = google_compute_subnetwork.default.id

    access_config {
      # Include this section to give the VM an external IP address
    }
  }

  labels = {
    business-unit = "sales"
    environment   = "dev"
    goog-ec-src   = "vm_add-tf"
  }
}

resource "google_compute_firewall" "ssh" {
  name = "allow-ssh"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  direction     = "INGRESS"
  network       = google_compute_network.vpc_network.id
  priority      = 1000
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
}

resource "google_compute_firewall" "http" {
  name    = "http-app-firewall"
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  source_ranges = ["0.0.0.0/0"]
}
