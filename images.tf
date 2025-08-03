resource "docker_image" "bind9_image" {
    name = "bind9:latest"
    keep_locally = false

    build {
        context    = "${path.module}/bind9"
        dockerfile = "Dockerfile"
    }
}