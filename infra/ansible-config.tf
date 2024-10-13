# This file generates Ansible inventory file to point at IP address of instances

resource "local_file" "ansible_inventory" {
    filename = "${path.module}/ansible-inventory.yml"
    content = <<-EOF
      boxen:
        hosts:
          app_servers:
            ansible_host: ${aws_instance.app.public_dns}
          db_servers:
            ansible_host: ${aws_instance.db.public_dns}
          app-clone_servers:
            ansible_host: ${aws_instance.app-clone.public_dns}
    EOF
}

