require 'spec_helper_acceptance'
require 'json'

test_name 'kubernetes using redhat provided packages'

describe 'kubernetes using redhat provided packages' do

  masters    = hosts_with_role(hosts,'kube-master')
  nodes      = hosts_with_role(hosts,'node')
  controller = masters.first

  manifest = "include 'simp_kubernetes'"

  cluster = masters.map{|h| fact_on(h,'fqdn') }
  base_hiera = {
    'simp_kubernetes::etcd_peers'   => Array(cluster),
    'simp_kubernetes::kube_masters' => Array(cluster),
    'simp_kubernetes::flannel_args' => {
      'iface' => 'eth1',
    },
  }

  masters.each do |host|
    it 'should do master stuff' do
      master_hiera = base_hiera.merge(
        'simp_kubernetes::is_master' => true
      )
      set_hieradata_on(host, master_hiera)
      on(host, 'cat /etc/puppetlabs/code/hieradata/default.yaml')
      apply_manifest_on(host, manifest, catch_failures: true)
      apply_manifest_on(host, manifest, catch_changes: true)
    end
  end

  nodes.each do |host|
    it 'should do node stuff' do
      master_hiera = base_hiera.merge(
        'simp_kubernetes::is_master' => false
      )
      set_hieradata_on(host, master_hiera)
      on(host, 'cat /etc/puppetlabs/code/hieradata/default.yaml')
      apply_manifest_on(host, manifest, catch_failures: true)
      apply_manifest_on(host, manifest, catch_changes: true)
    end
  end

  context 'use kubernetes' do
    it 'should deploy a nginx service ' do
      scp_to(controller, 'spec/acceptance/suites/default/test-nginx_deployment.yaml','/root/test-nginx_deployment.yaml')
      on(controller, 'kubectl create -f /root/test-nginx_deployment.yaml')
    end
  end
end
