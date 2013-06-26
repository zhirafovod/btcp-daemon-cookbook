# remove /etc/hosts
#file "/etc/hosts" do
#  action :delete
#end

# parse /etc/resolv.conf name, return container name if string conain pattern like 'search dmpws1-1.sla71.mycmdb.net sla71.mycmdb.net'
node.default['container_name'] = node['name']
File.open('/etc/resolv.conf') { |f| f.each_line { |l| node.default['container_name'] = $1 if l.match('^search\s+([^\.]+\.[^\.]+)') } }

debian_version = File.open('/etc/debian_version'){ |file| file.read }
if debian_version.start_with? "wheezy"
        cookbook_file "/etc/apt/sources.list" do
                source "sources.list.wheezy.erb"
                mode "0644"
                owner "root"
                group "root"
                action :create
                notifies :run, "execute[aptitude update]", :immediately
        end
elsif debian_version.start_with? "6"
        #squeeze
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

# install packages
package 'python-twisted'
package 'python2.7'
package 'transmission-daemon'
#package 'python-transmissionrpc'
package 'python-pip' do
  action :install
end
package 'screen'
package 'vim'

# install python modules for each module in the array separated by whitespaces
python_virtualenv = "/var/lib/btcp/python"
#%w{PAM==0.4.2 PyYAML==3.10 SOAPpy SQLAlchemy==0.8.0b2 SimpleDB==0.0.5 Twisted==12.0.0 Twisted-Conch==12.0.0 Twisted-Core==12.0.0 Twisted-Lore==12.0.0 Twisted-Mail==12.0.0 Twisted-Names==12.0.0 Twisted-News==12.0.0 Twisted-Runner==12.0.0 Twisted-Web==12.0.0 Twisted-Words==12.0.0 Twistr==1.0.0 argparse==1.2.1 chardet fpconst==0.7.2 iso8601==0.1.4 pyOpenSSL==0.13 pyasn1==0.1.3 pycassa==1.8.0-1 pycrypto==2.6 pyserial==2.5 python-apt==0.8.4 python-debian==0.1.21 python-debianbts==1.11 reportbug==6.4.3 simplejson==2.6.2 six==1.3.0 swampy==2.1.1 thrift==0.9.0 transmissionrpc==0.10 wsgiref==0.1.2 zope.interface==3.6.1}.each do |s|
#%w{SQLAlchemy SimpleDB Twisted argparse pycassa simplejson transmissionrpc }.each do |s|
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
