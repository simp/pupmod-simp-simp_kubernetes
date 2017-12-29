# Container for classes only relevant to Kubernetes masters
#
class simp_kubernetes::master {


  if $::simp_kubernetes::manage_etcd {
    include '::simp_kubernetes::master::etcd'

    if $::simp_kubernetes::network_tech == 'flannel' {
      Class['simp_kubernetes::master::etcd'] -> Class['simp_kubernetes::flannel']
    }
  }

  if $::simp_kubernetes::kube_manage_firewall {
    iptables::listen::tcp_stateful { 'simp_kubernetes kube_api_port':
      trusted_nets => $::simp_kubernetes::trusted_nets,
      dports       => [$::simp_kubernetes::kube_api_port],
    }
  }

  contain '::simp_kubernetes::master::apiserver'
  contain '::simp_kubernetes::master::controller_manager'
  contain '::simp_kubernetes::master::scheduler'

}
