resource "docker_image" "image" {
    for_each = var.docker_images
    name = "${each.value.name}:${each.value.tag}"
    keep_locally = each.value.keep_locally

    build {
        context    = data.http.image_pull[each.value.name].url
        dockerfile = each.value.dockerfile
    }
}