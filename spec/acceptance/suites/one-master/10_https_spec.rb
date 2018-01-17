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
    'simp_options::pki'                     => true,
    'simp_options::pki::source'             => '/etc/pki/simp-testing/pki',
    'simp_kubernetes::etcd_peers'           => Array(cluster),
    'simp_kubernetes::kube_masters'         => Array(cluster),
    'simp_kubernetes::etcd_peer_protocol'   => 'https',
    'simp_kubernetes::etcd_client_protocol' => 'https',
    'simp_kubernetes::kube_api_protocol'    => 'https',
    'simp_kubernetes::kubelet_protocol'     => 'https',
    'simp_kubernetes::kube_api_port'        => 6443,
    'simp_kubernetes::flannel_args'         => {
      'iface' => 'eth1',
    },
  }

  # nodes.each do |node|
  #   it 'add cacerts' do
  #     on(node, 'cp /etc/pki/simp-testing/pki/cacerts/cacerts.pem /etc/pki/ca-trust/source/anchors/simp_ca.pem')
  #     on(node, 'update-ca-trust')
  #   end
  # end

  masters.each do |host|
    it "should do master stuff on #{host}" do
      master_hiera = base_hiera.merge(
        'simp_kubernetes::kube_api_listen_address' => fact_on(host, 'ipaddress_eth1'),
        'simp_kubernetes::is_master' => true
      )
      set_hieradata_on(host, master_hiera)
      on(host, 'cat /etc/puppetlabs/code/hieradata/default.yaml')
      apply_manifest_on(host, manifest, catch_failures: true)
      apply_manifest_on(host, manifest, catch_changes: true)
    end
  end

  nodes.each do |host|
    it "should do node stuff on #{host}" do
      master_hiera = base_hiera.merge(
        'simp_kubernetes::is_master' => false
      )
      set_hieradata_on(host, master_hiera)
      on(host, 'cat /etc/puppetlabs/code/hieradata/default.yaml')
      apply_manifest_on(host, manifest, catch_failures: true)

      # This is here due to a race condition with the kube-proxy service fully
      # starting
      retry_on(host, 'systemctl restart kube-proxy', acceptable_exit_codes: [0,130])

      apply_manifest_on(host, manifest, catch_changes: true)
    end
  end

  context 'check kubernetes health' do
    # Fix this when we can upgrade to 1.7+
    xit 'should get componentstatus with no unhealthy components' do
      status = on(controller, 'kubectl get componentstatus').stdout
      expect(status).not_to match(/Unhealthy/)
    end

    it 'should get componentstatus with only etcd unhealthy components' do
      status = on(controller, 'kubectl get componentstatus').stdout

      # See https://github.com/kubernetes/kubernetes/issues/29330 for details
      clean_status = status.lines.delete_if{|l| l =~ /^etcd.*Unhealthy.*bad\s+cetificate/}

      expect(clean_status).not_to match(/Unhealthy/)
    end
  end

  context 'use kubernetes' do
    it 'should deploy a nginx service ' do
      scp_to(controller, 'spec/acceptance/suites/one-master/test-nginx_deployment.yaml','/root/test-nginx_deployment.yaml')
      on(controller, 'kubectl create -f /root/test-nginx_deployment.yaml')
    end
  end
end
