resource "local_file" "ansible_inventory" {
  filename = "${path.module}/ansible/inventory/hosts.yml"

  content = yamlencode({
    all = {
      vars = {
        ansible_ssh_common_args : "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
      }
      children = {
        api_servers = {
          hosts = {
            for name, cfg in var.containers :
            name => {
              ansible_host = proxmox_virtual_environment_container.this[name].ipv4.veth0
              ansible_user = "root"
            } if can(regex("api", name))
          }
        }
        mysql_servers = {
          hosts = {
            for name, cfg in var.containers :
            name => {
              ansible_host = proxmox_virtual_environment_container.this[name].ipv4.veth0
              ansible_user = "root"
            } if can(regex("db", name))
          }
        }
        monitoring = {
          hosts = {
            for name, cfg in var.containers :
            name => {
              ansible_host = proxmox_virtual_environment_container.this[name].ipv4.veth0
              ansible_user = "root"
            } if can(regex("monitoring", name))
          }
        }
        proxmox_nodes = {
          hosts = {
            for name, cfg in var.nodes :
            name => {
              ansible_host = cfg.ip_address
              ansible_user = "root"
            }
          }
        }
        ungrouped = {
          vars = {
            ansible_port               = 22
            ansible_python_interpreter = "/usr/bin/python3"
          }
          hosts = {
            for name, cfg in var.containers :
            name => {
              ansible_host = proxmox_virtual_environment_container.this[name].ipv4.veth0
              ansible_user = "root"
            } if !can(regex("(db|api|monitoring)", name))
          }
        }
      }
    }
  })

  depends_on = [
    proxmox_virtual_environment_container.this
  ]
}

resource "null_resource" "ansible_provisioner" {
  for_each = var.containers

  triggers = {
    container_id = proxmox_virtual_environment_container.this[each.key].id
  }

  # Wait for container to be ready (has an IP address)
  provisioner "local-exec" {
    command     = <<-EOT
      # Wait for container to boot and get IP
      echo "Waiting for container ${each.key} to boot..."
      for i in {1..20}; do
        ping_result=$(ping -c 1 ${proxmox_virtual_environment_container.this[each.key].ipv4.veth0} 2>&1)
        if echo "$${ping_result}" | grep -q "bytes from"; then
          echo "Container is reachable"
          break
        fi
        echo "Attempt $i/20: waiting for container to be reachable..."
        sleep 5
      done
    EOT
    interpreter = ["bash", "-c"]
  }

  # Wait for SSH to be available
  provisioner "local-exec" {
    command = "timeout 180 bash -c \"until nc -z ${proxmox_virtual_environment_container.this[each.key].ipv4.veth0} 22; do echo 'waiting for SSH...'; sleep 3; done\""
  }

  # Install Python on the container (required for Ansible)
  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "apt-get install -y python3 python3-pip",
      "python3 -m pip install --upgrade pip"
    ]

    connection {
      type        = "ssh"
      user        = "root"
      host        = proxmox_virtual_environment_container.this[each.key].ipv4.veth0
      private_key = file("~/.ssh/id_ed25519") # Adjust path to your private key
      timeout     = "5m"
    }
  }

  depends_on = [
    proxmox_virtual_environment_container.this,
    local_file.ansible_inventory
  ]
}

# Run Ansible playbook after all VMs are provisioned
resource "null_resource" "run_ansible" {
  triggers = {
    inventory_hash = local_file.ansible_inventory.id
  }

  provisioner "local-exec" {
    command     = "ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/site.yml"
    working_dir = path.module
    on_failure  = continue

    environment = {
      # This points Ansible to a password file or you can use 
      # ANSIBLE_VAULT_PASSWORD (if your version supports it)
      ANSIBLE_VAULT_PASSWORD_FILE = "${path.module}/ansible/.vault_pass"
    }
  }

  depends_on = [
    null_resource.ansible_provisioner
  ]
}

resource "local_file" "homepage_vars" {
  filename = "${path.module}/ansible/inventory/homepage_data.yml"

  content = yamlencode({
    homepage_containers = {
      for name, cfg in var.containers :
      name => {
        name = name
        ip   = proxmox_virtual_environment_container.this[name].ipv4.veth0
        vmid = proxmox_virtual_environment_container.this[name].vm_id
        node = proxmox_virtual_environment_container.this[name].node_name
        # Automatic Icon Selection Logic
        icon = (
          can(regex("pihole", name)) ? "pi-hole.png" :
          can(regex("plex", name)) ? "plex.png" :
          can(regex("db|mysql|mariadb", name)) ? "mariadb.png" :
          can(regex("nginx|proxy", name)) ? "nginx.png" :
          can(regex("api|site", name)) ? "php.png" :
          can(regex("traefik", name)) ? "traefik.png" :
          can(regex("homepage", name)) ? "homepage.png" :
          can(regex("monitoring", name)) ? "grafana.png" :
          "mdi-container" # Default icon
        )
      }
    }
  })
}