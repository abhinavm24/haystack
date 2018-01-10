provider "aws" {
  region = "${var.aws_region}"
}

provider "kubernetes" {
  host = "${module.haystack-k8s.cluster_endpoint}"
  username = "admin"
  password = "Jm41PVbD5MddhhiAIeE76chMTpYyLsq8"
  insecure = true
}

data "aws_route53_zone" "haystack_dns_zone" {
  zone_id = "${var.aws_hosted_zone_id}"
}
