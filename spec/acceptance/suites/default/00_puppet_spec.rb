require 'spec_helper_acceptance'

test_name 'prepare system for kubeadm'

describe 'prepare system for kubeadm' do

  masters = hosts_with_role(hosts,'master')
  workers = hosts_with_role(hosts,'worker')

  hosts.each do |host|
    it 'should set a root password' do
      on(host, "sed -i 's/enforce_for_root//g' /etc/pam.d/*")
      on(host, 'echo "root:password" | chpasswd --crypt-method SHA256')
    end
    it 'should disable swap' do
      on(host, 'swapoff -a')
      on(host, "sed -i '/swap/d' /etc/fstab")
    end
    it 'should disable selinux :(' do
      on(host, 'setenforce 0')
      on(host, "sed -i 's/enforcing/disabled/g' /etc/selinux/config /etc/selinux/config")
    end
    it 'should set up haveged' do
      host.install_package('epel-release')
      host.install_package('haveged')
      on(host, 'systemctl enable haveged --now')
    end
    it 'should set up dnsmasq' do
      host.install_package('dnsmasq')
      on(host, 'systemctl enable dnsmasq --now')
    end
    it 'should set sysctl' do
      on(host, 'sysctl net.bridge.bridge-nf-call-iptables=1', accept_all_exit_codes: true)
    end
  end

  context 'uses puppet to prepare hosts' do
    worker_manifest = <<-EOF
      include 'iptables'
      class { 'simp_kubernetes': }
    EOF
    master_manifest = <<-EOF
      include 'iptables'
      class { 'simp_kubernetes':
        is_master => true,
      }
    EOF
    hiera = {
      'iptables::optimize_rules' => false,
      'iptables::ignore' => [
        'DOCKER',
        'docker',
        'KUBE',
        'cali'
      ],
      'iptables::ports' => {
        '22'   => nil,
        '6666' => nil
      },
      'simp_options::trusted_nets' => [
        '192.168.0.0/16',
        '10.0.0.0/8'
      ]
    }

    masters.each do |host|
      it "should do master stuff on #{host}" do
        set_hieradata_on(host, hiera)
        apply_manifest_on(host, master_manifest, catch_failures: true)
        apply_manifest_on(host, master_manifest, catch_failures: true)
        apply_manifest_on(host, master_manifest, catch_changes: true)
      end
    end
    workers.each do |host|
      it "should do node stuff on #{host}" do
        set_hieradata_on(host, hiera)
        apply_manifest_on(host, worker_manifest, catch_failures: true)
        apply_manifest_on(host, worker_manifest, catch_failures: true)
        apply_manifest_on(host, worker_manifest, catch_changes: true)
      end
    end
  end
end
