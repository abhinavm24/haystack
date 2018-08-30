locals {
  k8s_cluster_name = "${var.haystack_cluster_name}-k8s.${var.aws_domain_name}"
}

data "aws_subnet" "haystack_node_subnet" {
  id = "${var.aws_nodes_subnet}"
}


/*
module "kops" {
  source = "kops"
  k8s_version = "${var.k8s_version}"
  aws_vpc_id = "${var.aws_vpc_id}"
  k8s_cluster_name = "${local.k8s_cluster_name}"
  masters_instance_type = "${var.master_instance_type}"
  kops_executable_name = "${var.kops_executable_name}"
  app-nodes_instance_type = "${var.app-node_instance_type}"
  app-nodes_instance_count = "${var.app-node_instance_count}"
  monitoring-nodes_instance_type = "${var.monitoring-nodes_instance_type}"
  monitoring-nodes_instance_count = "${var.monitoring-nodes_instance_count}"
  s3_bucket_name = "${var.s3_bucket_name}"
  aws_hosted_zone_id = "${var.aws_hosted_zone_id}"
  aws_zone = "${data.aws_subnet.haystack_node_subnet.availability_zone}"
  aws_nodes_subnet = "${var.aws_nodes_subnet}"
  aws_utilities_subnet = "${var.aws_utility_subnet}"
  master_instance_volume = "${var.master_instance_volume}"
  app-nodes_instance_volume = "${var.app-nodes_instance_volume}"
  monitoring-nodes_instance_volume = "${var.monitoring-nodes_instance_volume}"
}
*/


module "aws-eks-cluster" {
  source = "eks"
  k8s_cluster_name = "${local.k8s_cluster_name}"
  role_arn = "${module.iam_roles.masters_role_arn}"
  master_security_group_ids = "${module.security_groups.master_security_group_ids}"
  aws_subnet_ids = "${var.aws_nodes_subnet}"
  depends_on = [
    "${module.iam_roles.aws_iam_role_policy_attachment_master-AmazonEKSClusterPolicy_arn}",
    "${module.iam_roles.aws_iam_role_policy_attachment_master-AmazonEKSServicePolicy_arn}"]
}

module "security_groups" {
  source = "security-groups"
  aws_vpc_id = "${var.aws_vpc_id}"
  reverse_proxy_port = "${var.reverse_proxy_port}"
  k8s_cluster_name = "${local.k8s_cluster_name}"
  haystack_cluster_name = "${var.haystack_cluster_name}"
  graphite_node_port = "${var.graphite_node_port}"
}

module "iam_roles" {
  source = "iam-roles"
  aws_hosted_zone_id = "${var.aws_hosted_zone_id}"
  s3_bucket_name = "${var.s3_bucket_name}"
  k8s_cluster_name = "${local.k8s_cluster_name}"
  haystack_cluster_name = "${var.haystack_cluster_name}"
}
module "asg" {
  source = "asg"
  k8s_cluster_name = "${local.k8s_cluster_name}"
  s3_bucket_name = "${var.s3_bucket_name}"
  nodes_iam-instance-profile_arn = "${module.iam_roles.nodes_iam-instance-profile_arn}"
  app-nodes_instance_type = "${var.app-node_instance_type}"
  app-nodes_instance_count = "${var.app-node_instance_count}"
  monitoring-nodes_instance_type = "${var.monitoring-nodes_instance_type}"
  monitoring-nodes_instance_count = "${var.monitoring-nodes_instance_count}"
  nodes_security_groups = "${module.security_groups.node_security_group_ids}"
  aws_zone = "${data.aws_subnet.haystack_node_subnet.availability_zone}"
  //masters_instance_type = "${var.master_instance_type}"
  aws_ssh_key = "${var.aws_ssh_key}"
  aws_nodes_subnet = "${var.aws_nodes_subnet}"
  //masters_security_groups = "${module.security_groups.master_security_group_ids}"
  //masters_iam-instance-profile_arn = "${module.iam_roles.masters_iam-instance-profile_arn}"
  haystack_cluster_name = "${var.haystack_cluster_name}"
  //master_instance_volume = "${var.master_instance_volume}"
  app-nodes_instance_volume = "${var.app-nodes_instance_volume}"
  monitoring-nodes_instance_volume = "${var.monitoring-nodes_instance_volume}"
  //nodes_ami = "${var.node_ami}"
  //masters_ami = "${var.master_ami}"
  amazon_account_id = "${var.amazon_account_id}"
}

module "elbs" {
  source = "elbs"
  elb_api_security_groups = "${module.security_groups.api-elb-security_group_ids}"
  aws_elb_subnet = "${var.aws_utility_subnet}"
  k8s_cluster_name = "${local.k8s_cluster_name}"
  nodes_api_security_groups = "${module.security_groups.nodes-api-elb-security_group_ids}"
  reverse_proxy_port = "${var.reverse_proxy_port}"
  //master-1_asg_id = "${module.asg.master-1_asg_id}"
  //master-2_asg_id = "${module.asg.master-2_asg_id}"
  //master-3_asg_id = "${module.asg.master-3_asg_id}"
  app-nodes_asg_id = "${module.asg.app-nodes_asg_id}"
  "monitoring-nodes_asg_id" = "${module.asg.monitoring-nodes_asg_id}"
  haystack_cluster_name = "${var.haystack_cluster_name}"
  monitoring_security_groups = "${module.security_groups.monitoring-elb-security_group_ids}"
  graphite_node_port = "${var.graphite_node_port}"
  aws_nodes_subnet = "${var.aws_nodes_subnet}"
}

module "route53" {
  source = "route53"
  master_elb_dns_name = "${module.elbs.master-elb-dns_name}"
  nodes_elb_dns_name = "${module.elbs.app-nodes-elb-dns_name}"
  k8s_cluster_name = "${local.k8s_cluster_name}"
  haystack_ui_cname = "${var.haystack_ui_cname}"
  kubectl_executable_name = "${var.kubectl_executable_name}"
  aws_hosted_zone_id = "${var.aws_hosted_zone_id}"
  k8s_dashboard_cname_enabled = "${var.k8s_dashboard_cname_enabled}"
  k8s_dashboard_cname = "${var.k8s_dashboard_cname}"
  metrics_cname_enabled = "${var.metrics_cname_enabled}"
  metrics_cname = "${var.metrics_cname}"
  logs_cname = "${var.logs_cname}"
  logs_cname_enabled = "${var.logs_cname_enabled}"
}

resource "aws_eip" "eip" {
  vpc = true
}
