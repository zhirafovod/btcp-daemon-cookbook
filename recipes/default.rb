# remove /etc/hosts
#file "/etc/hosts" do
#  action :delete
#end

# parse /etc/resolv.conf name, return container name if string conain pattern like 'search dmpws1-1.sla71.mycmdb.net sla71.mycmdb.net'
node.default['container_name'] = node['name']
File.open('/etc/resolv.conf') { |f| f.each_line { |l| node.default['container_name'] = $1 if l.match('^search\s+([^\.]+\.[^\.]+)') } }

debian_version = File.open('/etc/debian_version'){ |file| file.read }
if debian_version.start_with?("wheezy","7")
        cookbook_file "/etc/apt/sources.list" do
                source "sources.list.wheezy.erb"
                mode "0644"
                owner "root"
                group "root"
                action :create
                notifies :run, "execute[aptitude update]", :immediately
        end
elsif debian_version.start_with?("squeeze","6")
        cookbook_file "/etc/apt/sources.list" do
                source "sources.list.wheezy.erb"
                mode "0644"
                owner "root"
                group "root"
                action :create
                notifies :run, "execute[aptitude update]", :immediately
        end
        execute "apt-get -y --force-yes dist-upgrade"
end

execute "aptitude update" do
  action :nothing
end

#user "vagrant" do
#  comment "vagrant user for python-btcp-daemon"
#  system true
#  shell "/bin/false"
#end

# install binary dependencies 
%w{python2.7 python-pip python-twisted transmission-daemon screen vim}.each do |p|
  package p do
    action :install
  end
end

# install python dependencies 
%w{argparse pycassa simplejson transmissionrpc}.each do |s|
  p, v = s.split('>=', 2)
  python_pip p do
    #virtualenv python_virtualenv
    if v 
      version v
    end
    action :install
  end
end

# remove python2.6 
execute "apt-get --force-yes -y remove python-btcp python2.6 python2.6-minimal" do
  action :nothing
end

# install transmission-daemon configuration
service "transmission-daemon" do
  action :stop
end

cookbook_file "/etc/transmission-daemon/settings.json" do
	source "btcp.transmission-daemon.settings.json.erb"
	mode "0644"
  owner "debian-transmission"
  group "debian-transmission"
  action :create
end

# finished
directory "/var/lib/transmission-daemon/finished" do
  owner "debian-transmission"
  group "debian-transmission"
  mode 0755
  action :create
end

# downloads
directory "/var/lib/transmission-daemon/downloads" do
  owner "debian-transmission"
  group "debian-transmission"
  mode 0755
  action :create
end

# mount tmpfs to downloads
#execute "mount -t tmpfs -o size=500M,nr_inodes=5k,mode=700 tmpfs /var/lib/transmission-daemon/downloads"

service "transmission-daemon" do
  action :restart
end

# deploy libraries
remote_directory "/usr/lib/python2.7/dist-packages" do
  source "src"
  files_backup 10
  files_owner "root"
  files_group "root"
  files_mode 00644
  #owner "nobody"
  #group "nobody"
  #mode 00755
  action :create
end

git "/usr/lib/python2.7/dist-packages/btcp" do
  repository "https://github.com/zhirafovod/btcp-daemon.git"
  user "root"
  group "root"
  action :sync
end

# deploy executables
remote_directory "/usr/local/bin" do
  source "bin"
  files_backup 10
  files_owner "root"
  files_group "root"
  files_mode 00755
  #owner "nobody"
  #group "nobody"
  #mode 00755
  action :create
end

# deploy configuration
remote_directory "/etc/btcp" do
  source "etc/btcp"
  files_backup 10
  files_owner "root"
  files_group "root"
  files_mode 00755
  #owner "nobody"
  #group "nobody"
  #mode 00755
  action :create
end

# create configuration from template
template "/etc/btcp/btcp.conf" do
  source "btcp.conf.erb"
  mode "0644"
  #owner "vagrant"
  #group "vagrant"
  action :create
end

# deploy init.d scripts
remote_directory "/etc/init.d" do
  source "init.d"
  files_backup 10
  files_owner "root"
  files_group "root"
  files_mode 00755
  #owner "nobody"
  #group "nobody"
  #mode 00755
  action :create
end

# start btcp daemon
service "btcp-daemon" do
  action :restart
end
