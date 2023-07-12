
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.51.0"
    }
  }
}


provider "google" {
  credentials = file(var.credentials_file)
  project     = var.project
  region      = var.region
  zone        = var.zone
}

resource "google_compute_network" "vpc_network" {
  name                    = "${var.project}-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.project}-subnet"
  ip_cidr_range = var.subnet_cidr
  network       = google_compute_network.vpc_network.name
  region        = var.region
}


resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance"
  machine_type = "e2-micro"
  tags         = ["ecommerce","test"]
  lifecycle {
    ignore_changes = [attached_disk]
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

    {
    subnetwork = google_compute_subnetwork.subnet.self_link
    access_config {
    }
  }

}

resource "google_compute_firewall" "firewall_all" {
  name    = "firewall-ssh-http"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22","80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["firwall-ssh-https"]
}

resource "google_compute_disk" "data_disk" {
  name = "datadisk"
  size = "30"
  type = "pd-standard"
  zone = var.zone
}

resource "google_compute_attached_disk" "vm_attached_disk" {
  disk     = google_compute_disk.data_disk.id
  instance = google_compute_instance.vm_instance.id
}

resource "google_storage_bucket" "my_bucket" {
  name          = "my-gcs-bucket"
  location      = var.region
  project       = var.project
  storage_class = "COLDLINE" # Remplacez par le type de bucket souhaité (STANDARD, NEARLINE, COLDLINE, MULTI_REGIONAL, REGIONAL)
}
