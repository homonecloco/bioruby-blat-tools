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

  opts.on("-f", "--sequences FILE" , "FASTA file containing all the possible sequences. ") do |o|
    options[:fasta] = o
  end
  
end.parse!


blat_file = options[:blat_file]
stream = ARGF
stream = IO.open(options[:blat_file]) unless  options[:blat_file] == "-"
max_gap_size = options[:max_gap_size]

sequences = Hash.new
Bio::FlatFile.open(Bio::FastaFormat, options[:fasta]) do |fasta_file|
  fasta_file.each do |entry|
    sequences[entry.entry_id] = entry.naseq
  end
end

$stderr.puts "#Loaded #{sequences.length} squences"

total = 0 
skipped = 0
puts ["query", "target", "hit_length", "hit_pident", "longest_hsp_length", "longest_hsp_pident"].join("\t")
Bio::Blat::StreamedReport.each_hit(stream) do |hit|
  if hit.strand == '-'
    skipped += 1
    next
  end
  #puts hit.data.join("\t")
  longest = hit.longest_hsp_length(min_gap = max_gap_size)

  longest.query = sequences[hit.query_id]
  longest.hit   = sequences[hit.target_id]
  #puts longest
  #puts longest.mismatch
  #puts longest.query_gap_count
  puts [hit.query_id, hit.target_id, hit.length, hit.percent_identity, longest.length, longest.percent_identity ].join("\t")
end

$stderr.puts ("#{total} lines, #{skipped} skipped")
stream.close unless  options[:blat_file] == "-"