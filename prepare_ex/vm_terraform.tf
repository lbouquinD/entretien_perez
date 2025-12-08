# -----------------------------------------------------------
# VARIABLES (Simplifiées)
# -----------------------------------------------------------
variable "project_id" {
  description = "L'ID du projet GCP"
  type        = string
  default     = "playground-s-11-87bb59e8"  # Remplacez par votre projet si nécessaire
}

# -----------------------------------------------------------
# SCRIPT D'INSTALLATION DE TERRAFORM
# -----------------------------------------------------------
locals {
  # Définir la version de Terraform comme une variable locale Terraform
  TERRAFORM_VERSION = "1.7.5"
  TF_PACKAGE="terraform_${local.TERRAFORM_VERSION}_linux_amd64.zip"
  
  # Script bash pour télécharger et installer Terraform
  startup_script = <<-EOT
    #!/bin/bash 
    set -e 

    # Installer les dépendances
    sudo apt-get update
    sudo apt-get install -y unzip curl git
    
    echo "Installation de Terraform version ${local.TERRAFORM_VERSION}..."
    curl -o /tmp/${local.TF_PACKAGE} https://releases.hashicorp.com/terraform/${local.TERRAFORM_VERSION}/${local.TF_PACKAGE}
    unzip /tmp/${local.TF_PACKAGE} -d /usr/local/bin/


    # Vérification
    if ! command -v terraform &> /dev/null
    then
        echo "Erreur: Terraform n'a pas été installé correctement." >&2
        exit 1
    fi
    echo "Terraform $(terraform version) installé avec succès."

    # Nettoyage
    rm /tmp/${local.TF_PACKAGE}
  EOT
}

# 1. CRÉATION DU VPC ET DU SUBNET (Réseau Privé)
resource "google_compute_network" "tf_vpc" {
  name                    = "tf-installer-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "tf_subnet" {
  name                       = "tf-installer-subnet"
  ip_cidr_range              = "10.10.0.0/24"
  region                     = "europe-west1"
  network                    = google_compute_network.tf_vpc.name
  private_ip_google_access   = true 
}

# 2. CLOUD NAT (Accès Internet Sortant pour l'installation)
resource "google_compute_router" "router" {
  name    = "tf-nat-router"
  network = google_compute_network.tf_vpc.name
  region  = "europe-west1"
}

resource "google_compute_router_nat" "nat_config" {
  name                               = "tf-nat-config"
  router                             = google_compute_router.router.name
  region                             = "europe-west1"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  nat_ip_allocate_option             = "AUTO_ONLY"
}

# 3. Règle de Firewall pour l'accès SSH via IAP (Console GCP)
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "allow-iap-ssh-to-vm"
  network = google_compute_network.tf_vpc.name
  
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  # Plage IP de Google IAP (obligatoire)
  source_ranges = ["35.235.240.0/20"] 
  target_tags   = ["ssh-iap-access"]
}


# 4. Création de l'Instance Compute Engine SANS IP PUBLIQUE
resource "google_compute_instance" "tf_installer_vm" {
  name         = "terraform-vm"
  machine_type = "e2-medium" 
  zone         = "europe-west1-b"
  tags         = ["ssh-iap-access"] 
  
  # Le métadata SSH n'est plus nécessaire ici.
  metadata = {
    startup-script = local.startup_script 
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11" 
      size  = 20
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.tf_subnet.name
    # PAS d'access_config
  }
  
  depends_on = [google_compute_router_nat.nat_config]
}

# 5. Afficher l'IP privée (pour référence)
output "vm_private_ip" {
  description = "Adresse IP privée de la VM (pour la connexion via IAP)"
  value       = google_compute_instance.tf_installer_vm.network_interface[0].network_ip
}
