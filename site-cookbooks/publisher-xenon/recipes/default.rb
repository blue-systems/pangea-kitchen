#
# Cookbook:: publisher-xenon
# Recipe:: default
#
# Copyright:: 2018,  Harald Sitter
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

user = 'aptly'
group = user.clone
home = "/home/#{user}"

apt_repository 'aptly' do
  uri node['aptly']['uri']
  distribution node['aptly']['dist']
  components node['aptly']['components']
  keyserver node['aptly']['keyserver']
  key node['aptly']['key']
  action :add
end

package 'aptly'
package 'graphviz'

# Publisher User
publisher_setup_with_systemd 'aptly' do
  action :setup
  sshkeys []
  listen_stream 'aptly.socket' # expanded relative to home dir
  listen_socket true
end

directory "#{home}/.ssh" do
  owner user
  group group
  mode 0o700
end

# There is no reason to be more dynamic here, so we don't use the ssh cookbook
# but simply write the file as intended.
file "#{home}/.ssh/authorized_keys" do
  content <<-EOF
# Generated by Chef via publisher-xenon cookbook; additions need to happen there
# Jenkins on xenon:
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBpku8vqM0f8h7zbDY1Y8PwSbwdALWDVk0CeuZcvYhptU+bcsXEkkcGfZBxV+NWWXs+ygs8Ylsrn8RdtJLdCJzhZbSFVzZNL2VZEnzp1kfhcDp6Vqd5oJlggEdIpgnuamoEuXgrBgGraLDyJOLhZLvEAL2xlqeyWYrcZy4XYQAh6idKcIFciK1uEFvVATLdvPwPjIJ6PwRC9lHVXuwYhbnJEKT+/HeEzXWNvB02EQ0FmjfsbBIzYekh6bjz/Rq/anYCUE3PHQqrhljb2Bnz9MQKQXtCgdQ/mTipjcyssHTyr7/ptSTqpKsUkeGkonhLfnbFF8IA/+pYOf/UwWEnsAn jenkins@do-xenon-jenkins
  EOF
  owner user
  group group
  mode 0o600
  action :create
end

directory "#{home}/images" do
  owner user
  group group
  mode 0o750
  action :create
  recursive true
end

include_recipe 'apache2::default'

web_app 'archive.xenon.pangea.pub' do
  server_name 'archive.xenon.pangea.pub'
  docroot "#{home}/aptly/public"
  directory_options %w[Indexes FollowSymLinks]
  cookbook 'apache2'
  notifies :reload, 'service[apache2]', :immediately # reload immediately so we can certbot it
end

# TODO
# certbot_apache server_name do
#   domains ['archive.xenon.pangea.pub']
#   redirect true
#   email 'sitter@kde.org'
#   only_if { ssl }
# end

# The following should technically be in its own cookbook similar to
# neon_websites. We don't have a generic system for this unfortunatley, so just
# tuck it in here for now.

directory '/var/www/files' do
  owner 'root'
  group 'jenkins' # It's a bit meh that we hardcode this thusly, but whatevs
  mode 0o775
  action :create
  recursive true
end

web_app 'files.xenon.pangea.pub' do
  server_name 'files.xenon.pangea.pub'
  docroot '/var/www/files'
  directory_options %w[Indexes FollowSymLinks]
  cookbook 'apache2'
  notifies :reload, 'service[apache2]', :immediately # reload immediately so we can certbot it
end

certbot_apache 'files.xenon.pangea.pub' do
  domains ['files.xenon.pangea.pub']
  redirect false
  email 'sitter@kde.org'
  webroot_path '/var/www/files'
end
