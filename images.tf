resource "docker_image" "image" {
  for_each     = var.docker_images
  name         = "${each.value.name}:${each.value.tag}"
  keep_locally = each.value.keep_locally

  build {
    context    = (each.value.remote_repo == null) ? data.http.image_pull[each.value.name].url : each.value.remote_repo
    dockerfile = (each.value.remote_repo == null) ? each.value.dockerfile : null
  }
}