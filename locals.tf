locals {
  image_node_matrix = {
    for pair in flatten([
      for node_name in keys(var.nodes) : [
        for image_name, image in var.images : {
          key       = "${node_name}-${image_name}"
          node_name = node_name
          image     = image
        }
      ]
    ]) :
    pair.key => pair
  }
}