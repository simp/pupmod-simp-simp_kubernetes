# This test is to declare functionality of kubernetes on EL7 machines.
#
require 'spec_helper_acceptance'
require 'json'

test_name 'kubernetes using redhat provided packages'

describe 'kubernetes using redhat provided packages' do

  masters        = hosts_with_role(hosts,'master')
  nodes          = hosts_with_role(hosts,'node')
  controller     = masters.first
  kube_masters   = masters.map { |m| "http://#{fact_on(m,'fqdn')}:8080" }.join(',')
  etcd_endpoints = masters.map { |m| "http://#{fact_on(m,'fqdn')}:2379" }.join(',')
  etcd_peer      = masters.map { |m| "'#{m}=http://#{fact_on(m,'fqdn')}:2380'" }.join(',')

  # let(:manifest) { <<-EOS
  #     include 'simp_kubernetes'
  #   EOS
  # }

  context 'should set up the every-host config' do
    hosts.each do |host|
      it 'should set up the every-host config' do
        fqdn = fact_on(host, 'fqdn')

        # install kubernetes
        on(host, 'yum install -y kubernetes flannel')

        # configure kubernetes
        on(host,'mkdir -p /etc/kubernetes')
        config = <<-EOF.gsub(/^\s+/,'')
          # Comma separated list of nodes in the etcd cluster
          KUBE_MASTER="--master=#{kube_masters}"

          # Should this cluster be allowed to run privileged docker containers
          KUBE_ALLOW_PRIV="--allow-privileged=false"

          # logging to stderr means we get it in the systemd journal
          KUBE_LOGTOSTDERR="--logtostderr=true"

          # journal message level, 0 is debug
          KUBE_LOG_LEVEL="--v=0"

          # Add your own!
          # KUBE_API_ARGS="--etcd-cafile=/etc/pki/simp-testing/pki/cacerts/cacerts.pem \\
          #   --etcd-certfile=/etc/pki/simp-testing/pki/private/#{fqdn}.pem \\
          #   --etcd-keyfile=/etc/pki/simp-testing/pki/private/#{fqdn}.pem \\
          #   --kubelet-https=true \\
          #   --kubelet-certificate-authority=/etc/pki/simp-testing/pki/cacerts/cacerts.pem \\
          #   --kubelet-client-certificate=/etc/pki/simp-testing/pki/private/#{fqdn}.pem \\
          #   --kubelet-client-key=/etc/pki/simp-testing/pki/private/#{fqdn}.pem \\
          #   --tls-ca-file=/etc/pki/simp-testing/pki/cacerts/cacerts.pem \\
          #   --tls-cert-file=/etc/pki/simp-testing/pki/private/#{fqdn}.pem \\
          #   --tls-private-key-file=/etc/pki/simp-testing/pki/private/#{fqdn}.pem \\
          "
        EOF
        create_remote_file(host, '/etc/kubernetes/config', config)

        # configure flannel
        config = <<-EOF.gsub(/^\s+/,'')
          # Flanneld configuration options

          # etcd url location.  Point this to the server where etcd runs
          FLANNEL_ETCD_ENDPOINTS="#{etcd_endpoints}"

          # etcd config key.  This is the configuration key that flannel queries
          # For address range assignment
          FLANNEL_ETCD_PREFIX="/kube-simp/network"

          # Any additional options that you want to pass
          # FLANNEL_OPTIONS="
          #   --etcd-keyfile=/etc/pki/simp-testing/pki/private/#{fqdn}.pub \\
          #   --etcd-certfile=/etc/pki/simp-testing/pki/private/#{fqdn}.pem \\
          #   --etcd-cafile=/etc/pki/simp-testing/pki/cacerts/cacerts.pem \\
          # "
        EOF
        create_remote_file(host, '/etc/sysconfig/flanneld', config)

        # disable firewall for now
        on(host, 'systemctl disable firewalld')
        on(host, 'systemctl stop firewalld')
      end
    end
  end

  context 'should set up the master' do
    masters.each do |host|
      it 'should set up the master' do
        fqdn = fact_on(host, 'fqdn')
        # install etcd
        on(host, 'yum install -y etcd')

        # drop in a kubeconfig file
        # kubeconfig = {
        #   'current-context' => 'simp-context',
        #   'apiVersion' => 'v1',
        #   'kind' => 'Config',
        #   'clusters' => [
        #     { 'cluster' => {
        #         'apiVersion' => 'v1',
        #         'server' => "https://#{fact_on(controller,'fqdn')}:6443"
        #       },
        #       'name' => 'simp-cluster',
        #       'certificate-authority' => '/etc/pki/simp-testing/pki/cacerts/cacerts.pem',
        #     }
        #   ],
        #   'contexts' => [
        #     { 'context' => {
        #         'cluster' => 'simp-cluster',
        #         'user' => 'simp'
        #       },
        #       'name' => 'simp-context'
        #     }
        #   ],
        #   'preferences' => { 'color' => true },
        #   'users' => [
        #     { 'name' => 'simp',
        #       'user' => {
        #         'client-certificate' => '/etc/pki/simp-testing/pki/private/master01.tasty.bacon.pem',
        #         'client-key' => '/etc/pki/simp-testing/pki/private/master01.tasty.bacon.pem'
        #       }
        #     }
        #   ]
        # }.to_yaml
        # on(host, 'mkdir -p /root/.kube/')
        # create_remote_file(host, '/root/.kube/config', kubeconfig)

        # configure etcd
        etcd_manifest = <<-EOF
          class {'etcd':
            listen_client_urls    => 'http://0.0.0.0:2379',
            advertise_client_urls => "http://${facts['fqdn']}:2379",
            listen_peer_urls      => 'http://0.0.0.0:2380',
            etcd_name             => "#{host}",

            # client_cert_auth      => true,
            # peer_client_cert_auth => true,
            # cert_file             => "/etc/pki/simp-testing/pki/private/${facts['fqdn']}.pem",
            # key_file              => "/etc/pki/simp-testing/pki/private/${facts['fqdn']}.pem",
            # trusted_ca_file       => '/etc/pki/simp-testing/pki/cacerts/cacerts.pem',
            # peer_cert_file        => "/etc/pki/simp-testing/pki/private/${facts['fqdn']}.pem",
            # peer_key_file         => "/etc/pki/simp-testing/pki/private/${facts['fqdn']}.pem",
            # peer_trusted_ca_file  => '/etc/pki/simp-testing/pki/cacerts/cacerts.pem',

            initial_advertise_peer_urls => "http://${facts['fqdn']}:2380",
            initial_cluster             => [ #{etcd_peer} ],
          }
        EOF
        apply_manifest_on(host, etcd_manifest)

        # configure kubernetes master
        apiserver = <<-EOF.gsub(/^\s+/,'')
          # The address on the local server to listen to.
          # KUBE_API_ADDRESS="--bind-address=0.0.0.0"
          KUBE_API_ADDRESS="--insecure-bind-address=0.0.0.0"

          # The port on the local server to listen on.
          # KUBE_API_PORT="--secure-port=6443"
          KUBE_API_PORT="--insecure-port=8080"

          # Port kubelets listen on
          KUBELET_PORT="--kubelet-port=10250"

          # Comma separated list of nodes in the etcd cluster
          KUBE_ETCD_SERVERS="--etcd-servers=#{etcd_endpoints}"

          # Address range to use for services
          KUBE_SERVICE_ADDRESSES="--service-cluster-ip-range=10.254.0.0/16"

          # Other options
          # KUBE_API_ARGS="--etcd-cafile=/etc/pki/simp-testing/pki/cacerts/cacerts.pem \\
          #   --etcd-certfile=/etc/pki/simp-testing/pki/private/#{fqdn}.pem \\
          #   --etcd-keyfile=/etc/pki/simp-testing/pki/private/#{fqdn}.pem \\
          #   --kubelet-https=true \\
          #   --kubelet-certificate-authority=/etc/pki/simp-testing/pki/cacerts/cacerts.pem \\
          #   --kubelet-client-certificate=/etc/pki/simp-testing/pki/private/#{fqdn}.pem \\
          #   --kubelet-client-key=/etc/pki/simp-testing/pki/private/#{fqdn}.pem \\
          #   --tls-ca-file=/etc/pki/simp-testing/pki/cacerts/cacerts.pem \\
          #   --tls-cert-file=/etc/pki/simp-testing/pki/private/#{fqdn}.pem \\
          #   --tls-private-key-file=/etc/pki/simp-testing/pki/private/#{fqdn}.pem \\
          #
          #   --advertise-address=#{fact_on(host,'ipaddress_eth1')} \\
          #   --insecure-bind-address=127.0.0.1 \\
          "
        EOF
        create_remote_file(host, '/etc/kubernetes/apiserver', apiserver)

        # starts etcd
        on(host, "systemctl enable etcd")
        on(host, "systemctl start etcd")
        retry_on(host, "systemctl is-active etcd", retry_interval: 5)

        # network stuff
        network_config = {
          Network: '10.30.0.0/16',
          SubnetLen: 24,
          Port: 8472,
          Backend: { Type: 'vxlan' }
        }.to_json.gsub(/"/,'\"')
        etcdctl_config = [
          "--endpoints #{etcd_endpoints}",
          # "--cert-file /etc/pki/simp-testing/pki/private/#{fqdn}.pem",
          # "--key-file /etc/pki/simp-testing/pki/private/#{fqdn}.pem",
          # '--ca-file /etc/pki/simp-testing/pki/cacerts/cacerts.pem'
        ].join(' ')
        on(master, "etcdctl #{etcdctl_config} mkdir /kube-simp/network")
        on(master, "etcdctl #{etcdctl_config} mk /kube-simp/network/config \"#{network_config}\"")

        # starts services
        %w[kube-apiserver kube-controller-manager kube-scheduler flanneld].each do |service|
          on(host, "systemctl enable #{service}")
          on(host, "systemctl start #{service}")
          retry_on(host, "systemctl is-active #{service}", retry_interval: 5)
        end

        # needs to know about nodes
        nodes.each do |node|
          node_json = {
            apiVersion: 'v1',
            kind: 'Node',
            metadata: {
              name: node,
              labels: { name: "#{node}-label" }
            },
            spec: { externalID: fact_on(node, 'fqdn') }
          }.to_json
          on(host, 'mkdir -p /etc/kubernetes/nodes/')
          create_remote_file(host, "/etc/kubernetes/nodes/#{node}.json", node_json)
          on(host, "kubectl create -f /etc/kubernetes/nodes/#{node}.json")

          # should see the nodes
          result = on(host, 'kubectl get nodes').stdout
          expect(result).to match(/Unknown/)
        end
      end
    end
  end

  context 'set up the nodes' do
    nodes.each do |host|
      it 'set up the nodes' do
        # configure kubelet
        config = <<-EOF.gsub(/^\s+/,'')
          ###
          # Kubernetes kubelet (node) config

          # The address for the info server to serve on (set to 0.0.0.0 or "" for all interfaces)
          KUBELET_ADDRESS="--address=0.0.0.0"

          # You may leave this blank to use the actual hostname
          KUBELET_HOSTNAME="--hostname-override=#{fact_on(host,'fqdn')}"

          # location of the api-server
          KUBELET_API_SERVER="--api-servers=#{kube_masters}"

          # Add your own!
          KUBELET_ARGS=""
        EOF
        create_remote_file(host, '/etc/kubernetes/kubelet', config)

        # starts services
        %w[kube-proxy kubelet docker flanneld].each do |service|
          on(host, "systemctl enable #{service}")
          on(host, "systemctl start #{service}")
          retry_on(host, "systemctl is-active #{service}", retry_interval: 5)
        end

        # # should see the nodes
        # result = on(host, 'kubectl get nodes').stdout
        # expect(result).to match(/Ready/)
      end
    end
  end

  context 'deploy test nginx service' do
    it 'should deploy a nginx service ' do
      # https://github.com/kubernetes/kubernetes/blob/master/examples/simple-nginx.md
      # on(controller, 'kubectl run test-nginx --image=nginx --replicas=3 --port=80')
      # on(controller, 'kubectl expose deployment test-nginx --port=80 --type=NodePort')

      deployment_yaml = <<-EOF
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 3
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
---
kind: Service
metadata:
  name: nginx-service
spec:
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 9380
  selector:
    app: nginx
      EOF
      create_remote_file(controller, '/root/test-nginx_deployment.yaml', deployment_yaml)
      on(controller, 'kubectl create -f /root/test-nginx_deployment.yaml')
    end
  end
end
