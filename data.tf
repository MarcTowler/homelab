data "http" "image_pull" {
  for_each = {for x in var.docker_images: x.name => x}
  url = "https://github.com/MarcTowler/Docker/images/${each.value.name}/Dockerfile"
}