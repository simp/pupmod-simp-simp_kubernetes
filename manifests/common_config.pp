# Populate the every-node kubernetes configuration
#
class simp_kubernetes::common_config {
  assert_private()

  package { 'kubernetes':
    ensure => $::simp_kubernetes::package_ensure,
  }

  $config_template = epp('simp_kubernetes/etc/kubernetes/config.epp', {
      'kube_masters' => $::simp_kubernetes::kube_master_urls,
      'allow_priv'   => $::simp_kubernetes::allow_priv,
      'logtostderr'  => $::simp_kubernetes::logtostderr,
      'log_level'    => $::simp_kubernetes::log_level,
      'api_args'     => $::simp_kubernetes::api_args,
    }
  )

  file { '/etc/kubernetes/config':
    ensure  => 'file',
    content => $config_template,
  }

}
