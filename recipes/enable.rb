#
# Cookbook Name:: redisio
# Recipe:: enable
#
# Copyright 2013, Brian Bianco <brian.bianco@gmail.com>
#
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

redis = node['redisio']

execute 'reload-systemd' do
  command '/usr/bin/systemctl daemon-reload'
  only_if { node['redisio']['job_control'] == 'systemd' }
  action :nothing
end

redis['servers'].each do |current_server|
  server_name = current_server['name'] || current_server['port']
  resource_name = if node['redisio']['job_control'] == 'systemd'
                    "service[redis@#{server_name}]"
                  else
                    "service[redis#{server_name}]"
                  end
  resource = resources(resource_name)
  resource.action Array(resource.action)
  if node['redisio']['job_control'] != 'systemd'
    resource.action << :enable
  else
    link "/etc/systemd/system/multi-user.target.wants/redis@#{server_name}.service" do
      to '/usr/lib/systemd/system/redis@.service'
      notifies :run, 'execute[reload-systemd]', :immediately
    end
  end
  resource.action << :enable
  resource.action << :start
end
