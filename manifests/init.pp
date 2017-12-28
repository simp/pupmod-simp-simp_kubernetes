# Full description of SIMP module 'simp_kubernetes' here.
#
# @param is_master
#   Enable if the host is to be a Kubernetes Master. This host would have the
#   following services:
#     - `kube-apiserver`
#     - `kube-contoller-manager`
#     - `kube-scheduler`
#   If false (default), the module will configure these services:
#     - `kubelet`
#     - `kube-proxy`
#   All nodes have `flannel` by default, unless configured otherwise
#
# @param network_tech
#   Which networking backend to use. Currently only `flannel` is supported.
#
# @param manage_etcd
#   Install and manage etcd
#
# @param inject_network_config
#   Fill etcd with the network configuration required by flannel
#
# @param etcd_static_cluster
#   Use the 'static' method to bootstrap the etcd cluster. Other methods
#   require setup outside the scope of this module, but should still be
#   compatible using this toggle.
#
# @param etcd_prefix
#   The etcd prefix where the flannel's configuration can be found
#
# @param flannel_network_config
#   The actual configuration for flannel
#
# @param app_pki_key
#   Path and name of the private SSL key file
#
# @param app_pki_cert
#   Path and name of the public SSL certificate
#
# @param app_pki_ca
#   Path to the CA
#
# @param etcd_peers
#   Array of hostnames/IPs that are etcd peers
#
# @param etcd_client_port
#   Port that etcd uses for serving requests
#
# @param etcd_peer_port
#   Port that etcd uses for peering
#
# @param etcd_peer_listen_address
#   Address of interface that etcd will listen on for peer communication
#   `0.0.0.0` for all interfaces.
#
# @param etcd_client_listen_address
#   Address of interface that etcd will listen on for client communication
#   `0.0.0.0` for all interfaces.
#
# @param etcd_options
#   Hash of extra options to be passed along to cristifalcas/etcd
#
# @param kube_masters
#   Array of hostnames/IPs that are Kubernetes masters
#
# @param kube_api_port
#   Port that kube-apiserver will be listening on
#
# @param kube_api_protocol
#   `http` or `https`. Be sure to specify certificates if this is set to `https`
#
# @param insecure_on_localhost
#   Configure kube-apisever to listen insecurely on localhost on port 8080
#
# @param allow_priv
#   Allow priviliged containers to run on this cluster
#
# @param logtostderr
#  Log to stderr. If true, logs will get sent to the journal
#
# @param log_level
#   Set the level of log output to debug-level (0~4) or trace-level (5~10)
#
# @param api_args
#   Hash of extra arguments to be sent to any Kubernetes service
#
# @param service_addresses
#   Virtual IP range that will be used by Kubernetes services
#
# @param kube_api_listen_address
#   Address of interface that `kube-apiserver` will listen on.
#   `0.0.0.0` for all interfaces.
#
# @param master_api_args
#   Hash of extra arguments to be sent to the `kube-apiserver` service
#
# @param scheduler_args
#   Hash of extra arguments to be sent to the `kube-scheduler` service
#
# @param controller_args
#   Hash of extra arguments to be sent to the `kube-controller-manager` service
#
# @param kubelet_listen_address
#   Address of interface that `kubelet` will listen on.
#   `0.0.0.0` for all interfaces.
#
# @param kubelet_protocol
#   `http` or `https`. Be sure to specify certificates if this is set to `https`
#
# @param kubelet_hostname
#   Overwrite hostname the the kubelet will identify itself as.
#
# @param proxy_args
#   Hash of extra arguments to be sent to the `kube-proxy` service
#
# @param kubelet_args
#   Hash of extra arguments to be sent to the `kubelet` service
#
# @param flannel_args
#   Hash of extra arguments to be sent to the `flanneld` service
#
# @param use_simp_certs
#   * If 'simp', include SIMP's pki module and use pki::copy to manage
#     application certs in /etc/pki/simp_apps/simp_apache/x509
#   * If true, do *not* include SIMP's pki module, but still use pki::copy
#     to manage certs in /etc/pki/simp_apps/simp_apache/x509
#   * If false, do not include SIMP's pki module and do not use pki::copy
#     to manage certs.  You will need to assign:
#     * app_pki_key
#     * app_pki_cert
#     * app_pki_ca
#
# @param app_pki_external_source
#   * If pki = 'simp' or true, this is the directory from which certs will be
#     copied, via pki::copy.  Defaults to /etc/pki/simp/x509.
#
#   * If pki = false, this variable has no effect.
#
# @param package_ensure
#   Forwarded to the package resource for kubernetes
#
# @param flannel_package_ensure
#   Forwarded to the package resource for flannel
#
# @param etcd_manage_firewall
#   Open up the firewall for ports used for etcd in this module using simp/iptables
#
# @param kube_manage_firewall
#   Open up the firewall for ports used for kubernetes in this module using simp/iptables
#
# @param flannel_manage_firewall
#   Open up the firewall for ports used for flannel in this module using simp/iptables
#
# @param trusted_nets
#   The address range(s) to allow connections from for host to host
#   communication
#
# @author https://github.com/simp/pupmod-simp-simp_kubernetes/graphs/contributors
#
class simp_kubernetes (
# general settings
  Boolean $is_master,
  Optional[String] $network_tech,
  Boolean $manage_etcd,
  Boolean $inject_network_config,
  Boolean $etcd_static_cluster,
  String $etcd_prefix,
  Hash $flannel_network_config,

# pki
  Stdlib::AbsolutePath $app_pki_key,
  Stdlib::AbsolutePath $app_pki_cert,
  Stdlib::AbsolutePath $app_pki_ca,

# etcd
  Array[Simplib::Host] $etcd_peers,
  Simplib::Port $etcd_client_port,
  Simplib::Port $etcd_peer_port,
  Simplib::IP $etcd_peer_listen_address,
  Simplib::IP $etcd_client_listen_address,
  Enum['http','https'] $etcd_peer_protocol,
  Enum['http','https'] $etcd_client_protocol,
  Stdlib::AbsolutePath $etcd_app_pki_key,
  Stdlib::AbsolutePath $etcd_app_pki_cert,
  Stdlib::AbsolutePath $etcd_app_pki_ca,
  Hash $etcd_options,

# every-host
  Array[Simplib::Host] $kube_masters,
  Simplib::Port $kube_api_port,
  Boolean $allow_priv,
  Boolean $logtostderr,
  Integer[1,10] $log_level,
  Hash $api_args,

# master
  Simplib::IP::CIDR $service_addresses,
  Simplib::Host $kube_api_listen_address,
  Enum['http','https'] $kube_api_protocol,
  Boolean $insecure_on_localhost,
  Hash $master_api_args,
  Hash $scheduler_args,
  Hash $controller_args,

# node
  Simplib::IP $kubelet_listen_address,
  Enum['http','https'] $kubelet_protocol,
  Optional[Simplib::Hostname] $kubelet_hostname,
  Hash $proxy_args,
  Hash $kubelet_args,

# flannel
  Hash $flannel_args,

# SIMP Catalysts
  Variant[Boolean,Enum['simp']] $use_simp_certs = simplib::lookup('simp_options::pki', { 'default_value' => false }),
  Stdlib::Absolutepath $app_pki_external_source = simplib::lookup('simp_options::pki::source', { 'default_value' => '/etc/pki/simp/x509' }),
  String $package_ensure = simplib::lookup('simp_options::package_ensure', {'default_value' => 'installed' }),
  String $flannel_package_ensure = simplib::lookup('simp_options::package_ensure', {'default_value' => 'installed' }),
  Boolean $etcd_manage_firewall = simplib::lookup('simp_options::firewall', {'default_value' => false }),
  Boolean $kube_manage_firewall = simplib::lookup('simp_options::firewall', {'default_value' => false }),
  Boolean $flannel_manage_firewall = simplib::lookup('simp_options::firewall', {'default_value' => false }),
  Simplib::Netlist $trusted_nets = simplib::lookup('simp_options::trusted_nets', {'default_value' => ['127.0.0.1/32'] }),
) {

  $etcd_advertise_client_urls = $etcd_peers.map |$peer| {
    "${etcd_client_protocol}://${peer}:${etcd_client_port}"
  }

  $kube_master_urls = $kube_masters.map |$master| {
    "${kube_api_protocol}://${master}:${kube_api_port}"
  }

  case $network_tech {
    'flannel': { include '::simp_kubernetes::flannel' }
    Undef:     { notify { 'simp_kubernetes: no network backend chosen':} }
    default:   { fail("simp_kubernetes: network_tech ${network_tech} not supported") }
  }

  # required on all hosts running kubernetes
  include '::simp_kubernetes::pki_params'
  $every_node_api_args = $::simp_kubernetes::pki_params::common_pki_params + $api_args
  contain '::simp_kubernetes::common_config'

  Class['simp_kubernetes::pki_params']
  -> Class['simp_kubernetes::flannel']
  -> Class['simp_kubernetes::common_config']

  if $is_master {
    include '::simp_kubernetes::master'
    Class['simp_kubernetes::master::etcd'] -> Class['simp_kubernetes::flannel']
    Class['simp_kubernetes::common_config'] -> Class['simp_kubernetes::master']
  }
  else {
    include '::simp_kubernetes::node'
    Class['simp_kubernetes::common_config'] -> Class['simp_kubernetes::node']
  }

}
