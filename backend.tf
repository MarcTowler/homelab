terraform {
  backend "local" {
    path = "/var/lib/github-runner/terraform.tfstate"
  }
}
