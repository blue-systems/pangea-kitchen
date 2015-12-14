property :uid, String, name_property: true
property :repositories, Array, default: []
property :sshkeys, Array, default: []
property :apiport, Integer, default: 8080

action :setup do
  # FIXME: Because I couldn't figure out how to achieve this via
  #        lazy variables.
  node.default['aptly']['rootdir'] = "/home/#{uid}"

  user_account uid do
    ssh_keygen false
    ssh_keys sshkeys
    create_group true
    home node['aptly']['rootdir']
  end

  node.default['aptly']['group'] = uid
  node.default['aptly']['user'] = uid

  template "#{node['aptly']['rootdir']}/.aptly.conf" do
    source 'aptly.conf.erb'
    owner uid
    group uid
    variables(
      rootdir: "#{node['aptly']['rootdir']}/aptly",
      downloadconcurrency: node['aptly']['downloadconcurrency'],
      architectures: node['aptly']['architectures'],
      dependencyfollowsuggests: node['aptly']['dependencyfollowsuggests'],
      dependencyfollowrecommends: node['aptly']['dependencyfollowrecommends'],
      dependencyfollowallvariants: node['aptly']['dependencyfollowallvariants'],
      dependencyfollowsource: node['aptly']['dependencyfollowsource'],
      gpgdisablesign: node['aptly']['gpgdisablesign'],
      gpgdisableverify: node['aptly']['gpgdisableverify'],
      downloadsourcepackages: node['aptly']['downloadsourcepackages'],
      ppadistributorid: node['aptly']['ppadistributorid'],
      ppacodename: node['aptly']['ppacodename']
    )
  end

  repositories.each do |repo|
    aptly_repo repo do
      action :create
      comment "Apt repository for #{repo}"
      component 'main'
    end
  end

  template "/etc/init/#{uid}_aptly.conf" do
    action :create
    source 'aptly_upstart.conf.erb'
    owner 'root'
    group 'root'
    mode '0644'
    variables(
      user: uid,
      group: uid,
      dir: node['aptly']['rootdir'],
      port: apiport
    )
  end

  service "#{uid}_aptly" do
    action :restart
  end
end
