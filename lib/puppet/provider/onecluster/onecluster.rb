# OpenNebula Puppet provider for onecluster
#
# License: APLv2
#
# Authors:
# Based upon initial work from Ken Barber
# Modified by Martin Alfke
#
# Copyright
# initial provider had no copyright
# Deutsche Post E-POST Development GmbH - 2014
#

require 'rexml/document'

Puppet::Type.type(:onecluster).provide(:onecluster) do
  desc "onecluster provider"

  commands :onecluster => "onecluster"

  def create
    output = "onecluster create #{resource[:name]} ", self.class.login()
    `#{output}`
    self.debug "We have hosts: #{resource[:hosts]}"
    self.debug "We have vnets: #{resource[:vnets]}"
    hosts = []
    hosts << resource[:hosts]
    hosts.each { |host|
      host_command = "onecluster addhost #{resource[:name]} #{host} ", self.class.login()
      self.debug "Running host add command : #{host_command}"
      `#{host_command}`
    }
    vnets = []
    vnets << resource[:vnets]
    vnets.each { |vnet|
        vnet_command = "onecluster addvnet #{resource[:name]} #{vnet} ", self.class.login()
        self.debug "Running vnet add command: #{vnet_command}"
        `#{vnet_command}`
    }
    ds = []
    ds << resource[:datastores]
    ds.each { |datastore|
        ds_command = "onecluster adddatastore #{resource[:name]} #{datastore} ", self.class.login()
        `#{ds_command}`
    }
  end

  def destroy
      hosts_output = "onecluster show #{resource[:name]} --xml ", self.class.login()
      xml = REXML::Document.new(`#{hosts_output}`)
      self.debug "Removing hosts vnets and datastores from cluster #{resource[:name]}"
      xml.elements.each("CLUSTER/HOSTS/ID") { |host|
          host_command = "onecluster delhost #{resource[:name]} #{host.text} ", self.class.login
          `#{host_command}`
      }
      xml.elements.each("CLUSTER/VNETS/ID") { |vnet|
          vnet_command = "onecluster delvnet #{resource[:name]} #{vnet.text} ", self.class.login
          `#{vnet_command}`
      }
      xml.elements.each("CLUSTER/DATASTORES/ID") { |ds|
          ds_command = "onecluster deldatastore #{resource[:name]} #{ds.text} ", self.class.login
          `#{ds_command}`
      }
      output = "onecluster delete #{resource[:name]} ", self.class.login()
      self.debug "Running command #{output}"
      `#{output}`
  end

  def exists?
    if self.class.onecluster_list().include?(resource[:name])
        self.debug "Found cluster #{resource[:name]}"
        true
    end
  end

  def self.onecluster_list
    xml = REXML::Document.new(`onecluster list -x`)
    list = []
    xml.elements.each("CLUSTER_POOL/CLUSTER/NAME") do |cluster|
      list << cluster.text
    end
    list
  end

  def self.instances
    output = "onecluster list -x ", login
    REXML::Document.new(`#{output}`).elements.collect("CLUSTER_POOL/CLUSTER") do |cluster|
      new(
        :name       => cluster.elements["NAME"].text,
        :ensure     => :present,
        :datastores => cluster.elements["DATASTORES"].text.to_a,
        :hosts      => cluster.elements["HOSTS"].text,
        :vnets      => cluster.elements["VNETS"].text.to_a
      )
    end

  end

  # login credentials
  def self.login
    credentials = File.read('/var/lib/one/.one/one_auth').strip.split(':')
    user = credentials[0]
    password = credentials[1]
    login = " --user #{user} --password #{password}"
    login
  end

  #getters
  def hosts
      result = []
      getter_output = "onecluster show #{resource[:name]} --xml ", self.class.login
      xml = REXML::Document.new(`#{getter_output}`)
      xml.elements.each("CLUSTER/HOSTS/ID") { |element|
          host_getter_output = "onehost show #{element.text} --xml ", self.class.login
          host_xml = REXML::Document.new(`#{host_getter_output}`)
          host_xml.elements.each("HOST/NAME") { |host_element|
            result << host_element.text
          }
      }
      result
  end
  def vnets
      result = []
      getter_output = "onecluster show #{resource[:name]} --xml ", self.class.login
      xml = REXML::Document.new(`#{getter_output}`)
      xml.elements.each("CLUSTER/VNETS/ID") { |element|
          vnet_getter_output = "onevnet show #{element.text} --xml ", self.class.login
          vnet_xml = REXML::Document.new(`#{vnet_getter_output}`)
          vnet_xml.elements.each("VNET/NAME") { |vnet_element|
            result << vnet_element.text
          }
      }
      result
  end
  def datastores
      result = []
      getter_output = "onecluster show #{resource[:name]} --xml ", self.class.login
      xml = REXML::Document.new(`#{getter_output}`)
      xml.elements.each("CLUSTER/DATASTORES/ID") { |element|
          ds_getter_output = "onedatastore show #{element.text} --xml ", self.class.login
          ds_xml = REXML::Document.new(`#{ds_getter_output}`) { |ds_element|
            result << ds_element.text
          }
      }
      result
  end

  #setters
  def hosts=(value)
      value.each { |host|
        host_command = "onecluster addhost #{resource[:name]} #{host} ", self.class.login()
        self.debug "Running host add command : #{host_command}"
        `#{host_command}`
      }
      # todo: remove hosts which are no longer in list
  end
  def vnets=(value)
      value.each { |vnet|
        vnet_command = "onecluster addvnet #{resource[:name]} #{vnet} ", self.class.login()
        self.debug "Running vnet add command: #{vnet_command}"
        `#{vnet_command}`
      }
      # todo: remove vnets which are no longer in list
  end
  def datastores=(value)
      value.each { |ds|
        ds_command = "onecluster adddatastore #{resource[:name]} #{datastore} ", self.class.login()
        `#{ds_command}`
      }
      # todo: remove datastores which are no longer in list
  end
end
