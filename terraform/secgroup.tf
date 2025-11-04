# Security Groups
################# create all sg #################
resource "aws_security_group" "sec-grp-bastion" {
  name   = "sec-grp-bastion"
  vpc_id = aws_vpc.main.id
}

resource "aws_security_group" "sec-grp-revproxy" {
  name   = "sec-grp-revproxy"
  vpc_id = aws_vpc.main.id
}

resource "aws_security_group" "sec-grp-db" {
  name   = "sec-grp-db"
  vpc_id = aws_vpc.main.id
}

resource "aws_security_group" "sec-grp-monitor" {
  name   = "sec-grp-monitor"
  vpc_id = aws_vpc.main.id
}

resource "aws_security_group" "sec-grp-app" {
  name   = "sec-grp-app"
  vpc_id = aws_vpc.main.id
}


################# sec-grp-bastion in #################

# Rule from IPs
resource "aws_security_group_rule" "bastion_from_ips" {
  type              = "ingress"
  from_port         = 4242
  to_port           = 4242
  protocol          = "tcp"
  security_group_id = aws_security_group.sec-grp-bastion.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "4242 from IPs"
}

# Rule from monitor
resource "aws_security_group_rule" "bastion_from_monitor" {
  type                     = "ingress"
  from_port                = 9100
  to_port                  = 9100
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec-grp-bastion.id
  source_security_group_id = aws_security_group.sec-grp-monitor.id
  description              = "9100 from monitor"
}


################# sec-grp-bastion out #################

# Rule to revproxy
resource "aws_security_group_rule" "bastion_to_revproxy" {
  type                     = "egress"
  from_port                = 4242
  to_port                  = 4242
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec-grp-bastion.id
  source_security_group_id = aws_security_group.sec-grp-revproxy.id
  description              = "4242 to revproxy"
}

# Rule to app
resource "aws_security_group_rule" "bastion_to_app" {
  type                     = "egress"
  from_port                = 4242
  to_port                  = 4242
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec-grp-bastion.id
  source_security_group_id = aws_security_group.sec-grp-app.id
  description              = "4242 to App"
}

# Rule to monitor
resource "aws_security_group_rule" "bastion_to_monitor" {
  type                     = "egress"
  from_port                = 4242
  to_port                  = 4242
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec-grp-bastion.id
  source_security_group_id = aws_security_group.sec-grp-monitor.id
  description              = "4242 to monitor"
}

# Rule to internet
resource "aws_security_group_rule" "bastion_to_internet" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.sec-grp-bastion.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "https to internet"
}

################# sec-grp-revproxy in #################

# Rule from IPs
resource "aws_security_group_rule" "revproxy_from_ips" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.sec-grp-revproxy.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "443 from IPs (HTTPS)"
}

# Rule from IPs
resource "aws_security_group_rule" "revproxy80_from_ips" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.sec-grp-revproxy.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "80 from IPs (HTTPS)"
}

# Rule from Bastion
resource "aws_security_group_rule" "revproxy_from_bastion" {
  type                     = "ingress"
  from_port                = 4242
  to_port                  = 4242
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec-grp-revproxy.id
  source_security_group_id = aws_security_group.sec-grp-bastion.id
  description              = "4242 from bastion"
}

# Rule monitor from monitor
resource "aws_security_group_rule" "revproxy_from_monitor" {
  type                     = "ingress"
  from_port                = 9100
  to_port                  = 9100
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec-grp-revproxy.id
  source_security_group_id = aws_security_group.sec-grp-monitor.id
  description              = "9100 from monitor"
}

################# sec-grp-revproxy out #################

# Rule prometheus to monitor
resource "aws_security_group_rule" "revproxy_to_monitor" {
  type                     = "egress"
  from_port                = 9090
  to_port                  = 9090
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec-grp-revproxy.id
  source_security_group_id = aws_security_group.sec-grp-monitor.id
  description              = "revproxy to monitor"
}

# Rule grafana to monitor
resource "aws_security_group_rule" "grafana_revproxy_to_monitor" {
  type                     = "egress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec-grp-revproxy.id
  source_security_group_id = aws_security_group.sec-grp-monitor.id
  description              = "grafana revproxy to monitor"
}

# Rule to app
resource "aws_security_group_rule" "revproxy_to_app" {
  type                     = "egress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec-grp-revproxy.id
  source_security_group_id = aws_security_group.sec-grp-app.id
  description              = "revproxy to app 3000"
}

# Rule to internet
resource "aws_security_group_rule" "revproxy_to_internet" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.sec-grp-revproxy.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "https to internet"
}

# Rule to internet
resource "aws_security_group_rule" "revproxy80_to_internet" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.sec-grp-revproxy.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "http to internet"
}

################# sec-grp-db in #################

# Rule from app
resource "aws_security_group_rule" "db_from_app" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec-grp-db.id
  source_security_group_id = aws_security_group.sec-grp-app.id
  description              = "Prostresql from app"
}

# Rule monitoring from Bastion
resource "aws_security_group_rule" "db_from_monitor" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec-grp-db.id
  source_security_group_id = aws_security_group.sec-grp-monitor.id
  description              = "Postgresql from monitor"
}

################# sec-grp-db out #################

################# sec-grp-monitor in #################

# Rule ssh from Bastion
resource "aws_security_group_rule" "ssh_monitor_from_bastion" {
  type                     = "ingress"
  from_port                = 4242
  to_port                  = 4242
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec-grp-monitor.id
  source_security_group_id = aws_security_group.sec-grp-bastion.id
  description              = "4242 from Bastion"
}

# Rule grafana from revproxy
resource "aws_security_group_rule" "grafana_from_revproxy" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec-grp-monitor.id
  source_security_group_id = aws_security_group.sec-grp-revproxy.id
  description              = "grafana from revproxy"
}

# Rule grafana from monitor
resource "aws_security_group_rule" "grafana_from_monitor" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec-grp-monitor.id
  source_security_group_id = aws_security_group.sec-grp-monitor.id
  description              = "grafana from monitor"
}

# Rule monitor from revproxy
resource "aws_security_group_rule" "monitor_from_revproxy" {
  type                     = "ingress"
  from_port                = 9090
  to_port                  = 9090
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec-grp-monitor.id
  source_security_group_id = aws_security_group.sec-grp-revproxy.id
  description              = "monitor from revproxy"
}

# Rule monitor from monitor
resource "aws_security_group_rule" "monitor_9090_from_monitor" {
  type                     = "ingress"
  from_port                = 9090
  to_port                  = 9090
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec-grp-monitor.id
  source_security_group_id = aws_security_group.sec-grp-monitor.id
  description              = "monitor 9090 from db"
}

# Rule monitor from monitor
resource "aws_security_group_rule" "monitor_from_monitor" {
  type                     = "ingress"
  from_port                = 9100
  to_port                  = 9100
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec-grp-monitor.id
  source_security_group_id = aws_security_group.sec-grp-monitor.id
  description              = "monitor from monitor"
}

################# sec-grp-monitor out #################

# Rule Supervision to Bastion
resource "aws_security_group_rule" "monitor_to_bastion" {
  type                     = "egress"
  from_port                = 9100
  to_port                  = 9100
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec-grp-monitor.id
  source_security_group_id = aws_security_group.sec-grp-bastion.id
  description              = "Supervision to Bastion"
}

# Rule Supervision to revproxy
resource "aws_security_group_rule" "monitor_to_revproxy" {
  type                     = "egress"
  from_port                = 9100
  to_port                  = 9100
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec-grp-monitor.id
  source_security_group_id = aws_security_group.sec-grp-revproxy.id
  description              = "Supervision to Bastion"
}

# Rule Supervision to app
resource "aws_security_group_rule" "monitor_to_app" {
  type                     = "egress"
  from_port                = 9100
  to_port                  = 9100
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec-grp-monitor.id
  source_security_group_id = aws_security_group.sec-grp-app.id
  description              = "Supervision to App"
}

# Rule Supervision to app 3000
resource "aws_security_group_rule" "monitor_to_app_3000" {
  type                     = "egress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec-grp-monitor.id
  source_security_group_id = aws_security_group.sec-grp-app.id
  description              = "Supervision to App 3000"
}

# Rule cAdvisor to app 8080
resource "aws_security_group_rule" "monitor_to_cAdvisor_8080" {
  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec-grp-monitor.id
  source_security_group_id = aws_security_group.sec-grp-app.id
  description              = "Supervision to cAdvisor 8080"
}

# Rule Supervision to monitor
resource "aws_security_group_rule" "Supervision_to_monitor" {
  type                     = "egress"
  from_port                = 9100
  to_port                  = 9100
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec-grp-monitor.id
  source_security_group_id = aws_security_group.sec-grp-monitor.id
  description              = "Supervision to monitor"
}

# Rule to db
resource "aws_security_group_rule" "monitor_to_db" {
  type                     = "egress"
  from_port                = 9106
  to_port                  = 9106
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec-grp-monitor.id
  source_security_group_id = aws_security_group.sec-grp-db.id
  description              = "Supervision to db"
}

# Rule to monitor
resource "aws_security_group_rule" "monitor_to_monitor" {
  type                     = "egress"
  from_port                = 9090
  to_port                  = 9090
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec-grp-monitor.id
  source_security_group_id = aws_security_group.sec-grp-monitor.id
  description              = "monitor to monitor"
}

# Rule to internet
resource "aws_security_group_rule" "monitor_to_internet" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.sec-grp-monitor.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "https to internet"
}

# Rule alerting to internet
resource "aws_security_group_rule" "alerting_monitor_to_internet" {
  type              = "egress"
  from_port         = 9093
  to_port           = 9093
  protocol          = "tcp"
  security_group_id = aws_security_group.sec-grp-monitor.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "alerting to internet"
}

################# sec-grp-app in #################

# Rule ssh from bastion
resource "aws_security_group_rule" "app_from_bastion" {
  type                     = "ingress"
  from_port                = 4242
  to_port                  = 4242
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec-grp-app.id
  source_security_group_id = aws_security_group.sec-grp-bastion.id
  description              = "app from bastion 4242"
}

# Rule ssh from revproxy
resource "aws_security_group_rule" "app_from_revproxy" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec-grp-app.id
  source_security_group_id = aws_security_group.sec-grp-revproxy.id
  description              = "app from revproxy 3000"
}

# Rule app 3000 to app
resource "aws_security_group_rule" "app_3000_to_app" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec-grp-app.id
  source_security_group_id = aws_security_group.sec-grp-app.id
  description              = "3000 app to app"
}

# Rule Supervision from monitor
resource "aws_security_group_rule" "app_from_supervision" {
  type                     = "ingress"
  from_port                = 9100
  to_port                  = 9100
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec-grp-app.id
  source_security_group_id = aws_security_group.sec-grp-monitor.id
  description              = "9100 from monitor"
}

# Rule cAdvisor from monitor
resource "aws_security_group_rule" "cAdvisor_from_supervision" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec-grp-app.id
  source_security_group_id = aws_security_group.sec-grp-monitor.id
  description              = "cAdvisor from monitor"
}

# Rule 8080 from APP
resource "aws_security_group_rule" "app_8080_from_app" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec-grp-app.id
  source_security_group_id = aws_security_group.sec-grp-app.id
  description              = "8080 from app"
}

# Rule 2377 from APP
resource "aws_security_group_rule" "app_2377_from_app" {
  type                     = "ingress"
  from_port                = 2377
  to_port                  = 2377
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec-grp-app.id
  source_security_group_id = aws_security_group.sec-grp-app.id
  description              = "2377 from app"
}

# Rule 7946 from APP
resource "aws_security_group_rule" "app_7946_from_app" {
  type                     = "ingress"
  from_port                = 7946
  to_port                  = 7946
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec-grp-app.id
  source_security_group_id = aws_security_group.sec-grp-app.id
  description              = "7946 from app"
}

# Rule 7946_UDP from APP
resource "aws_security_group_rule" "app_7946_udp_from_app" {
  type                     = "ingress"
  from_port                = 7946
  to_port                  = 7946
  protocol                 = "udp"
  security_group_id        = aws_security_group.sec-grp-app.id
  source_security_group_id = aws_security_group.sec-grp-app.id
  description              = "7946 udp from app"
}

# Rule 4789 from APP
resource "aws_security_group_rule" "app_4789_from_app" {
  type                     = "ingress"
  from_port                = 4789
  to_port                  = 4789
  protocol                 = "udp"
  security_group_id        = aws_security_group.sec-grp-app.id
  source_security_group_id = aws_security_group.sec-grp-app.id
  description              = "4789 from app"
}

################# sec-grp-app out #################

# Rule to db
resource "aws_security_group_rule" "app_to_db" {
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec-grp-app.id
  source_security_group_id = aws_security_group.sec-grp-db.id
  description              = "app to db"
}

# Rule to app
resource "aws_security_group_rule" "app_to_app" {
  type                     = "egress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec-grp-app.id
  source_security_group_id = aws_security_group.sec-grp-app.id
  description              = "app to app 3000"
}

# Rule 7946 to APP
resource "aws_security_group_rule" "app_7946_to_app" {
  type                     = "egress"
  from_port                = 7946
  to_port                  = 7946
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec-grp-app.id
  source_security_group_id = aws_security_group.sec-grp-app.id
  description              = "7946 to app"
}

# Rule 7946_UDP to APP
resource "aws_security_group_rule" "app_7946_udp_to_app" {
  type                     = "egress"
  from_port                = 7946
  to_port                  = 7946
  protocol                 = "udp"
  security_group_id        = aws_security_group.sec-grp-app.id
  source_security_group_id = aws_security_group.sec-grp-app.id
  description              = "7946 udp to app"
}

# Rule 4789 to APP
resource "aws_security_group_rule" "app_4789_to_app" {
  type                     = "egress"
  from_port                = 4789
  to_port                  = 4789
  protocol                 = "udp"
  security_group_id        = aws_security_group.sec-grp-app.id
  source_security_group_id = aws_security_group.sec-grp-app.id
  description              = "4789 to app"
}

# Rule to app
resource "aws_security_group_rule" "app_to_app_2377" {
  type                     = "egress"
  from_port                = 2377
  to_port                  = 2377
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec-grp-app.id
  source_security_group_id = aws_security_group.sec-grp-app.id
  description              = "app to app 2377"
}

# Rule to app
resource "aws_security_group_rule" "app_to_app_8080" {
  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sec-grp-app.id
  source_security_group_id = aws_security_group.sec-grp-app.id
  description              = "app to app 8080"
}

# Rule to internet
resource "aws_security_group_rule" "app_to_internet" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.sec-grp-app.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "https to internet"
}

################# sec-grp end #################