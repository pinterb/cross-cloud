module "master" {
  source                    = "./modules/master"
  name                      = "${ var.name }"
  master_node_count         = "${ var.master_node_count }"
  packet_facility           = "${ var.packet_facility }"
  packet_project_id         = "${ var.packet_project_id }"
  packet_billing_cycle      = "${ var.packet_billing_cycle }"
  packet_operating_system   = "${ var.packet_operating_system }"
  packet_master_device_plan = "${ var.packet_master_device_plan }"
  master_cloud_init = "${ module.master_templates.master_cloud_init }"
}

module "worker" {
  source                    = "./modules/worker"
  name                      = "${ var.name }"
  worker_node_count         = "${ var.worker_node_count }"
  packet_facility           = "${ var.packet_facility }"
  packet_project_id         = "${ var.packet_project_id }"
  packet_billing_cycle      = "${ var.packet_billing_cycle }"
  packet_operating_system   = "${ var.packet_operating_system }"
  packet_worker_device_plan = "${ var.packet_worker_device_plan }"
  worker_cloud_init = "${ module.worker_templates.worker_cloud_init }"
}


module "tls" {
  source = "../tls"

  data_dir = "${ var.data_dir }"

  tls_ca_cert_subject_common_name = "kubernetes"
  tls_ca_cert_subject_organization = "Kubernetes"
  tls_ca_cert_subject_locality = "San Francisco"
  tls_ca_cert_subject_province = "California"
  tls_ca_cert_subject_country = "US"
  tls_ca_cert_validity_period_hours = 1000
  tls_ca_cert_early_renewal_hours = 100

  tls_client_cert_subject_common_name = "kubecfg"
  tls_client_cert_validity_period_hours = 1000
  tls_client_cert_early_renewal_hours = 100
  tls_client_cert_dns_names = "kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster.local"
  tls_client_cert_ip_addresses = "127.0.0.1"

  tls_apiserver_cert_subject_common_name = "kubernetes-master"
  tls_apiserver_cert_validity_period_hours = 1000
  tls_apiserver_cert_early_renewal_hours = 100
  tls_apiserver_cert_dns_names = "kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster.local,*.${ var.name }.${ var.cloud_provider }.local"
  tls_apiserver_cert_ip_addresses = "127.0.0.1,100.64.0.1,${ var.dns_service_ip }"

  tls_worker_cert_subject_common_name = "kubernetes-worker"
  tls_worker_cert_validity_period_hours = 1000
  tls_worker_cert_early_renewal_hours = 100
  tls_worker_cert_dns_names = "kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster.local"
  tls_worker_cert_ip_addresses = "127.0.0.1"
}


module "master_templates" {
  source = "/cncf/master_templates-v1.9.0-dns-etcd"

  master_node_count = "${ var.master_node_count }"
  name = "${ var.name }"
  etcd_endpoint     = "etcd.${ var.name }.${ var.cloud_provider }.local"
  etcd_discovery    = "${ var.name }.${ var.cloud_provider }.local"

  kubelet_artifact = "${ var.kubelet_artifact }"
  cni_artifact = "${ var.cni_artifact }"
  etcd_image = "${ var.etcd_image }"
  etcd_tag = "${ var.etcd_tag }"
  kube_apiserver_image = "${ var.kube_apiserver_image }"
  kube_apiserver_tag = "${ var.kube_apiserver_tag }"
  kube_controller_manager_image = "${ var.kube_controller_manager_image }"
  kube_controller_manager_tag = "${ var.kube_controller_manager_tag }"
  kube_scheduler_image = "${ var.kube_scheduler_image }"
  kube_scheduler_tag = "${ var.kube_scheduler_tag }"
  kube_proxy_image = "${ var.kube_proxy_image }"
  kube_proxy_tag = "${ var.kube_proxy_tag }"

  cloud_provider = ""
  cloud_config = "${ var.cloud_config }"
  cluster_domain = "${ var.cluster_domain }"
  cluster_name = "${ var.cluster_name }"
  pod_cidr = "${ var.pod_cidr }"
  service_cidr = "${ var.service_cidr }"
  non_masquerade_cidr = "${ var.non_masquerade_cidr }"
  dns_service_ip = "${ var.dns_service_ip }"

  ca = "${ module.tls.ca }"
  ca_key = "${ module.tls.ca_key }"
  apiserver = "${ module.tls.apiserver }"
  apiserver_key = "${ module.tls.apiserver_key }"
  cloud_config_file = ""

  dns_conf = "${ module.dns.dns_conf }"

}

module "worker_templates" {
  source = "../worker_templates-v1.9.0"

  worker_node_count = "${ var.worker_node_count }"
  name = "${ var.name }"

  kubelet_artifact = "${ var.kubelet_artifact }"
  cni_artifact = "${ var.cni_artifact }"
  kube_proxy_image = "${ var.kube_proxy_image }"
  kube_proxy_tag = "${ var.kube_proxy_tag }"

  cloud_provider = ""
  cloud_config = "${ var.cloud_config }"
  cluster_domain = "${ var.cluster_domain }"
  pod_cidr = "${ var.pod_cidr }"
  non_masquerade_cidr = "${ var.non_masquerade_cidr }"
  dns_service_ip = "${ var.dns_service_ip }"
  internal_lb_ip      = "internal-master.${ var.name }.${ var.cloud_provider }.local"

  ca = "${ module.tls.ca }"
  worker = "${ module.tls.worker }"
  worker_key = "${ module.tls.worker_key }"
  cloud_config_file = ""

  dns_conf = "${ module.dns.dns_conf }"

}

module "dns" {
  source = "../dns-etcd"
  
  name = "${ var.name }"
  etcd_server = "${ var.etcd_server }"
  discovery_nameserver = "${ var.discovery_nameserver }"
  cloud_provider = "${ var.cloud_provider }"

  master_ips = "${ module.master.master_ips }"
  public_master_ips = "${ module.master.public_master_ips }"
  worker_ips = "${ module.worker.worker_ips }"

  master_node_count = "${ var.master_node_count }"
  worker_node_count = "${ var.worker_node_count }"

}

module "kubeconfig" {
  source = "../kubeconfig"
  data_dir = "${ var.data_dir }"
  endpoint = "master.${ var.name }.${ var.cloud_provider }.local"
  name = "${ var.name }"
  ca = "${ module.tls.ca}"
  client = "${ module.tls.client }"
  client_key = "${ module.tls.client_key }"

}
