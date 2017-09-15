#!/usr/bin/env ruby
require 'optparse'
require 'bio'
require 'csv'
$: << File.expand_path(File.dirname(__FILE__) + '/../lib')
$: << File.expand_path('.')
path= File.expand_path(File.dirname(__FILE__) + '/../lib/bio-blat-tools.rb')
require path

options = {}
options[:identity] = 95
options[:min_bases] = 200
options[:blat_file] = "-"
options[:max_gap_size] = 1

OptionParser.new do |opts|
  
  opts.banner = "Usage: filter_blat.rb [options]"

  opts.on("-p", "--psl FILE", "PSL file") do |o|
    options[:blat_file] = o
  end
  
  opts.on("-g", "--max_gap_size INT", "Maximum gap size to consider different blocks part of the same HSP") do |o|
    options[:max_gap_size] = o.to_i
  end
  
end.parse!


blat_file = options[:blat_file]
stream = ARGF
stream = IO.open(options[:blat_file]) unless  options[:blat_file] == "-"
max_gap_size = options[:max_gap_size]

Bio::Blat::StreamedReport.each_hit(stream) do |hit|
  puts hit.data.join("\t")
  longest = hit.longest_hsp_length(min_gap = max_gap_size)
  puts [hit.query_id, hit.target_id, hit.length, hit.percent_identity, longest.length ].join("\t")
end

stream.close unless  options[:blat_file] == "-"