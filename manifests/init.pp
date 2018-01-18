# Full description of SIMP module 'simp_kubernetes' here.
#
# @param is_master Enable if the node is to the kubernetes master
#
# @param master_ports Ports to be opened if `$is_master` is true
#
# @param worker_ports Ports to be opened if `$is_master` is false
#
# @param use_simp_docker Use simp/simp_docker to manage docker
#
# @param manage_repo Manage the upstream kubernetes repo using the internet
#
# @param repo_enabled Enable the internet kubernetes repo
#
# @param manage_packages Use this module to install package dependencies
#
# @param packages Kubernetes related packages to install
#
# @param package_ensure Ensure parameter to be forwarded to the packages
#
# @param manage_kubelet_sevice Manage the kubelet service. This is turned off by
#   default for bootstrapping reasons
#
# @param service_ensure Ensure parameter to be forwarded to the service
#
# @param kubelet_overrides Contents of a systemd overrides file, for changing
#   runtime configuration of the kubelet
#
# @author https://github.com/simp/pupmod-simp-simp_kubernetes/graphs/contributors
#
class simp_kubernetes (
  Boolean $is_master,
  Hash $master_ports,
  Hash $worker_ports,
  Boolean $use_simp_docker,
  Boolean $manage_repo,
  Boolean $repo_enabled,
  Boolean $manage_packages,
  Array[String] $packages,
  String $package_ensure,
  Boolean $manage_kubelet_sevice,
  Optional[String] $service_ensure,
  String $kubelet_overrides,
) {
  if $use_simp_docker { include '::simp_docker' }

  if $is_master {
    iptables::ports { 'kubernetes master': ports => $master_ports }
  }
  else {
    iptables::ports { 'kubernetes worker': ports => $worker_ports }
  }

  if $manage_repo and $manage_packages {
    $_enabled = $repo_enabled ? { true => 1, default => 0 }
    yumrepo { 'google-kubernetes':
      baseurl       => 'https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64',
      descr         => 'The kubernetes repository - from Google',
      enabled       => $_enabled,
      gpgcheck      => '1',
      repo_gpgcheck => '1',
      gpgkey        => 'https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg',
    }
  }

  if $manage_packages {
    $_require = $manage_repo ? { true => Yumrepo['google-kubernetes'], default => undef }
    package { $packages:
      ensure  => $package_ensure,
      require => $_require,
    }
  }

  if $manage_kubelet_sevice {
    service { 'kubelet':
      ensure => $service_ensure,
      enable => true,
    }
  }

  if $kubelet_overrides {
    file { '/etc/systemd/system/kubelet.service.d/override.conf':
      ensure  => file,
      content => $kubelet_overrides
    }
  }

}
