locals {
  ansible_inventory_path = abspath("${path.module}/../ansible/inventory.ini")
}

resource "local_file" "ansible_inventory" {
  content = <<-EOT
[bastion]
bastion ansible_host=${aws_instance.bastion.public_ip} public_ip=${aws_instance.bastion.public_ip} private_ip=${aws_instance.bastion.private_ip}

[proxy]
proxy ansible_host=${aws_instance.proxy.private_ip} public_ip=${aws_instance.proxy.public_ip} private_ip=${aws_instance.proxy.private_ip}

[manager]
manager ansible_host=${aws_instance.manager.private_ip} public_ip=${aws_instance.manager.public_ip} private_ip=${aws_instance.manager.private_ip}

[workers]
worker1 ansible_host=${aws_instance.worker1.private_ip} public_ip=${aws_instance.worker1.public_ip} private_ip=${aws_instance.worker1.private_ip}
worker2 ansible_host=${aws_instance.worker2.private_ip} public_ip=${aws_instance.worker2.public_ip} private_ip=${aws_instance.worker2.private_ip}

[monitoring]
monitoring ansible_host=${aws_instance.monitoring.private_ip} public_ip=${aws_instance.monitoring.public_ip} private_ip=${aws_instance.monitoring.private_ip}

[fck_nat]
fck_nat ansible_host=${aws_instance.fck_nat.private_ip} public_ip=${aws_eip.fck_nat.public_ip} private_ip=${aws_instance.fck_nat.private_ip}

[bastion:vars]
ansible_user=bastion
ansible_port=4242
ansible_ssh_private_key_file=~/.ssh/id_ed25519_bastion

[all:vars]
ansible_user=bastion
ansible_ssh_private_key_file=~/.ssh/id_ed25519_bastion
# ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ProxyJump=appuser@${aws_instance.bastion.public_ip}'
rds_endpoint=${aws_db_instance.redmine_db.address}
rds_name=${aws_db_instance.redmine_db.identifier}
db_name=${aws_db_instance.redmine_db.db_name}

[jump:children]
proxy
manager
workers
monitoring
fck_nat
EOT

  filename        = local.ansible_inventory_path
  file_permission = "0644"
}
