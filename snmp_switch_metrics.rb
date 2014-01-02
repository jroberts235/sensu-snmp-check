#!/opt/sensu/embedded/bin/ruby
# Check SNMP switch metrics
# ===
#
# This walks a switch and returns all data from 4 columns
# 'ifIndex', 'ifDescr', 'ifInOctets', 'ifOutOctets'
#
#
# Requires SNMP gem
#
# On your cisco switch:
#
#   snmp-server community public RO
#
# Examples:
#
#   snmp_switch_metrics -H host -c community
#
#
#  Author Jeff Roberts <jeff.roberts@nastygal.com>
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'snmp'
require 'sensu-plugin/metric/cli'

# class
class SwitchMetrics < Sensu::Plugin::Metric::CLI::Graphite
  option :host,
    :short => '-H HOST',
    :long => '--host HOST',
    :description => 'HOST to get metrics from',
    :required => true

  option :port,
    :short => '-P PORT',
    :long => '--port PORT',
    :description => 'PORT to connect to',
    :default => '161'

  option :community,
    :description => 'Community name to use',
    :short => '-c NAME',
    :long => '--community NAME',
    :default => 'public'

  option :scheme,
    :description => 'Metric naming scheme',
    :long => '--scheme SCHEME',
    :default => "stats.#{Socket.gethostname}"

  option :help,
    :long => '--help',
    :short => '-h',
    :description => 'Show this message',
    :on => :tail,
    :show_options => true,
    :boolean => true,
    :exit => 0

  def walk(host, scheme)
    ifTable_columns = %w[ ifIndex  ifDescr ifInOctets ifOutOctets ]
    SNMP::Manager.open(:host => host,
                       :port => config[:port],
                       :community => config[:community]
                      ) do |manager|
      a = []
      manager.walk(ifTable_columns) do |row|
        a2 = []
        row.each do |vb|
          a2 << vb.value.to_s.tr('/', '|')
          a << a2 if a2.size == 4
        end
      end
      timestamp = Time.now.to_i
      a.each_index do |index|
        puts "#{scheme}.#{a[index][1]}.in #{a[index][2]} #{timestamp}"
        puts "#{scheme}.#{a[index][1]}.out #{a[index][3]} #{timestamp}"
      end
    end
  end

  def run
    host = config[:host]
    scheme = config[:scheme]
    walk(host, scheme)
    ok # exit
  end
end # Class end
