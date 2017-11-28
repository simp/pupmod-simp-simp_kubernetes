#
class simp_kubernetes::master {


  if $::simp_kubernetes::manage_etcd {
    include '::simp_kubernetes::etcd'

    if $::simp_kubernetes::network_tech == 'flannel' {
      Class['simp_kubernetes::etcd'] -> Class['simp_kubernetes::flannel']
    }
  }

  include '::simp_kubernetes::master::apiserver'
  include '::simp_kubernetes::master::controller_manager'
  include '::simp_kubernetes::master::scheduler'

}
