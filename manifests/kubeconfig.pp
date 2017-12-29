# Lay down kubeconfig files. Useful for configuring control plane components
# Not recommended for personal kubeconfig files
#
# @param current_context
#   `kubectl config use-context <context>`
#
# @param clusters
#   `kubectl config set-cluster`
#
# @param contexts
#   `kubectl config set-context`
#
# @param users
#   `kubectl config set-credentials`
#
# @param content
#   The raw content to stick in this kubeconfig. Can be a string or a hash.
#
# @param api_version
#
# @param preferences
#
define simp_kubernetes::kubeconfig (
  String $current_context,
  Array[Simp_kubernetes::Kubeconfig::Cluster] $clusters,
  Array[Simp_kubernetes::Kubeconfig::Context] $contexts,
  Array[Simp_kubernetes::Kubeconfig::User] $users,
  Optional[Variant[Hash,String]] $content = undef,
  String $api_version = 'v1',
  Hash $preferences = {},
) {

  if $content {
    $_content = $content ? {
      Hash    => $content.to_yaml,
      default => $content
    }
    file { $name:
      ensure  => file,
      group   => 'kube',
      content => $_content,
    }
  }
  else {
    $context_names = $contexts.map |$context| { $context['name'] }
    unless $current_context in $context_names {
      fail('simp_kubernetes::kubeconfig: $current_context should be listed in $contexts')
    }
    unless $name =~ Stdlib::AbsolutePath {
      fail('simp_kubernetes::kubeconfig: $name should be an absolute path')
    }

    $kubeconfig = {
      'apiVersion'      => $api_version,
      'clusters'        => $clusters,
      'contexts'        => $contexts,
      'current-context' => $current_context,
      'kind'            => 'Config',
      'preferences'     => $preferences,
      'users'           => $users
    }

    file { $name:
      ensure  => file,
      group   => 'kube',
      content => $kubeconfig.to_yaml,
    }
  }

}
