# Copyright (c) 2014 Hewlett-Packard Development Company, L.P.
# Copyright (C) 2017 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Puppet maillist provider for mailman mailing lists.
# Based on the 'mailman' package provider in puppet 2.7, except this one
# does not muck with aliases.

require 'puppet/provider/parsedfile'

Puppet::Type.type(:mailman_list).provide(:mailman) do

  defaultfor :kernel => 'Linux'

  if [ "CentOS", "RedHat", "Fedora" ].any? { |os|  Facter.value(:operatingsystem) == os }
    commands :list_lists => "/usr/lib/mailman/bin/list_lists", :rmlist => "/usr/lib/mailman/bin/rmlist", :newlist => "/usr/lib/mailman/bin/newlist"
    commands :mailman => "/usr/lib/mailman/mail/mailman"
  else
    # This probably won't work for non-Debian installs, but this path is sure not to be in the PATH.
    commands :list_lists => "list_lists", :rmlist => "rmlist", :newlist => "newlist"
    commands :mailman => "/var/lib/mailman/mail/mailman"
  end

  mk_resource_methods

  # Return a list of existing mailman instances.
  def self.instances
    ret = []
    Dir.entries('/srv/mailman').each do |entry|
      if (entry == '.' || entry == '..') then next end
      path = File.join('/srv/mailman', entry)
      if !File.directory?(path) then next end
      if !File.exists?(File.join(path, 'lists')) then next end
      ENV['MAILMAN_SITE_DIR'] = path
      list_lists('--bare').split("\n").each do |line|
        ret << new(:ensure => :present, :name => line.strip+'@'+entry)
      end
    end
    return ret
  end

  def self.prefetch(lists)
    instances.each do |prov|
      if list = lists[prov.name] || lists[prov.name.downcase]
        list.provider = prov
      end
    end
  end

  def setenv
    r = self.name.split('@')
    ENV['MAILMAN_SITE_DIR'] = File.join('/srv/mailman', r[1])
    print "Mailman install dir", ENV['MAILMAN_SITE_DIR'], "\n"
    return r[0]
  end

  def create
    print "create ", self.name, "\n"
    name = setenv
    args = []
    if val = @resource[:mailserver]
      args << "--emailhost" << val
    end
    if val = @resource[:webserver]
      args << "--urlhost" << val
    end

    args << name
    if val = @resource[:admin]
      args << val
    else
      raise ArgumentError, "Mailman lists require an administrator email address"
    end
    if val = @resource[:password]
      args << val
    else
      raise ArgumentError, "Mailman lists require an administrator password"
    end
    newlist(*args)
    puts "done"
  end

  def destroy(purge = false)
    puts "destroy", self.name
    name = setenv
    args = []
    args << "--archives" if purge
    args << name
    rmlist(*args)
  end

  def exists?
    properties[:ensure] != :absent
  end

  def flush
    @property_hash.clear
  end

  def properties
    if @property_hash.empty?
      @property_hash = query || {:ensure => :absent}
      @property_hash[:ensure] = :absent if @property_hash.empty?
    end
    @property_hash.dup
  end

  def purge
    destroy(true)
  end

  def query
    self.class.instances.each do |list|
      if list.name == self.name or list.name.downcase == self.name
        return list.properties
      end
    end
    nil
  end
end
