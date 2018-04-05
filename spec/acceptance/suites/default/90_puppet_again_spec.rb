require 'spec_helper_acceptance'

test_name 'run puppet again'

describe 'run puppet again' do

  masters    = hosts_with_role(hosts,'master')
  workers    = hosts_with_role(hosts,'worker')
  controller = masters.first

  shared_examples_for 'a healthy kubernetes cluster' do
    it { sleep 60 }
    it 'should get componentstatus with no unhealthy components' do
      status = on(controller, 'kubectl get componentstatus' )
      expect(status.stdout).not_to match(/Unhealthy/)
    end
    it 'should get nodes with all good statuses' do
      status = on(controller, 'kubectl get nodes' )
      status.stdout.split("\n")[1..-1].each do |node|
        expect(node).to match(/\sReady\s/)
      end
    end
    it 'should get pods with all good statuses' do
      status = on(controller, 'kubectl get pods --all-namespaces' )
      status.stdout.split("\n")[1..-1].each do |pod|
        expect(pod).to match(/Running/)
      end
    end
  end

  shared_examples_for 'wait for pods to finish deploying' do
    it 'should not have pods in ContainerCreating or Pending status' do
      sleep 20
      retry_on(controller,
        'kubectl get pods --all-namespaces --field-selector=status.phase!=ContainerCreating |& grep "No resources found"',
        desired_exit_codes: 1,
        retry_interval: 10,
        max_retries: 60,
      )
    end
  end

  context 'run puppet with a populated kubernetes cluser' do
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

    masters.each do |host|
      it "should not make any puppet changes on #{host}" do
        apply_manifest_on(host, master_manifest, catch_changes: true)
      end
    end
    workers.each do |host|
      it "should not make any puppet changes on #{host}" do
        apply_manifest_on(host, worker_manifest, catch_changes: true)
      end
    end
  end

  context 'should be healthy' do
    it { sleep 30 }
    it_behaves_like 'wait for pods to finish deploying'
    it_behaves_like 'a healthy kubernetes cluster'
  end
end
