require 'optparse'
$: << File.expand_path(File.dirname(__FILE__) + '/../lib')
$: << File.expand_path('.')
path= File.expand_path(File.dirname(__FILE__) + '/../lib/bio-blat-tools.rb')
require path

options = {}
options[:identity] = 95
options[:covered] = 60
options[:blat_file] = "-"

OptionParser.new do |opts|
  
  opts.banner = "Usage: best_blat_hit.rb [options]"

  opts.on("-p", "--psl FILE", "PSL file") do |o|
    options[:blat_file] = o.upcase
  end
  
end.parse!


blat_file = options[:blat_file]
stream = ARGF
stream = IO.open(options[:blat_file]) unless  options[:blat_file] == "-"

Bio::Blat::StreamedReport.each_best_hit(stream) do |hit|
    puts hit.data.join("\t")
end

