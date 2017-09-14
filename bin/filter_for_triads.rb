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

OptionParser.new do |opts|
  
  opts.banner = "Usage: filter_blat.rb [options]"

  opts.on("-p", "--psl FILE", "PSL file") do |o|
    options[:blat_file] = o
  end
  opts.on("-i", "--identity FLOAT", "Minimum percentage identity") do |o|
    options[:identity] = o.to_f
  end
  opts.on("-c", "--min_bases int", "Minimum alignment length (default 200)") do |o|
    options[:min_bases] = o.to_i
  end

  opts.on("-t", "--triads FILE", "CSV file with the gene triad names in the named columns 'A','B' and 'D' ") do |o|
    options[:triads] = o
  end
  
end.parse!

valid_pairs_A_B = Hash.new
valid_pairs_A_D = Hash.new
valid_pairs_B_D = Hash.new

CSV.foreach(options[:triads], headers:true ) do |row|
  valid_pairs_A_B[row['A']] = row['B']
  valid_pairs_A_D[row['A']] = row['D']
  valid_pairs_B_D[row['B']] = row['D']
end



blat_file = options[:blat_file]
stream = ARGF
stream = IO.open(options[:blat_file]) unless  options[:blat_file] == "-"

Bio::Blat::StreamedReport.each_hit(stream) do |hit|
  #puts hit.inspect
  if hit.covered >= options[:min_bases] and hit.percent_identity >= options[:identity]
    query  = hit.query_id.split("-")[0]
    target = hit.target_id.split("-")[0]
    puts hit.data.join("\t") if valid_pairs_A_B[query] == target or valid_pairs_A_D[query] == target or valid_pairs_B_D[query] == target  
  end
end

