require 'bio'
require 'levenshtein'

module Bio
  class Blat
    class StreamedReport < Report 
      def self.each_hit(text = '')
        flag = false
        head = []
        text.each_line do |line|
          if flag then
            yield Hit.new(line)
          else
            if /^\d/ =~ line 
              flag = true
              redo
            end
            line = line.chomp
            if /\A\-+\s*\z/ =~ line
              flag = true
            else
              head << line
            end
          end
        end
      end

      def self.each_best_hit(text = '')
        best_aln = Hash.new
        self.each_hit(text) do |hit|
          current_matches = hit.match 
          current_name = hit.query_id
          current_identity = hit.percent_identity
          current_score = hit.score
          best_aln[current_name] = hit if best_aln[current_name] == nil or current_score > best_aln[current_name] .score
        end
        best_aln.each_value { |val| yield  val }
      end
    end
  end
end

class Bio::Blat::Report::Hit::BlockArray
  attr_accessor :query, :hit
  def initialize()
    @arr = Array.new 
  end

  def << (block)
    @arr << block
  end

  def length
    @arr.map(&:blocksize).reduce(0, :+)
  end

  def [](i)
    @arr[i]
  end

  def first
    @arr.first
  end

  def last
    @arr.last
  end

  def query_from
    @arr.first.query_from
  end
  def query_to
    @arr.last.query_to
  end

  def hit_from
    @arr.first.hit_from
  end

  def hit_to
    @arr.last.hit_to
  end

  def query_length
    query_to - query_from + 1
  end

  def hit_length
    hit_to - hit_from + 1
  end

  def query_gap_count

    last = false
    count = 0
    @arr.each do |hsp|
      if last
        gap_query  =  hsp.query_from - last.query_to - 1 
        count += 1 if gap_query > 0
      end
      last = hsp 
    end
    count
  end

  def query_seq(sequence)
    seq = ""
    @arr.each_with_index do |e, i| 
      seq << sequence[e.query_from - 1 , e.blocksize]
    end
    seq
  end

  def hit_seq(sequence)
    seq = ""
    @arr.each_with_index do |e, i| 
      seq << sequence[e.hit_from - 1 , e.blocksize]
    end
    seq
  end

  def mismatch
    Levenshtein.distance query_seq(query),  hit_seq(hit)
    
  end

  def to_s
    "q:#{query_from}-#{query_to} (#{query_length})\th:#{hit_from}-#{hit_to} (#{hit_length}) \t #{length}"
  end

  def milli_bad
    qalen = query_length
    talen = hit_length
    alen =  qalen < talen ? qalen : talen
    return 0 if alen <= 0

    d = qalen - talen
    d = 0 if d < 0
    total = length
    return 0 if total == 0
    return (1000 * (self.mismatch + self.query_gap_count +
                      (3 * Math.log(1 + d)).round) / total)
  end

  def percent_identity
    100.0 - self.milli_bad * 0.1
  end

end

class Bio::Blat::Report::Hit

  def covered
    match + mismatch + rep_match
  end
  alias :length :covered
  
  def query_percentage_covered
    covered * 100.0 / query_len.to_f
  end

  def target_percentage_covered
    covered * 100.0 / target_len.to_f
  end

  def longest_hsp_length(min_gap = 0)
    min_length = 0
    current_length = 0
    current_block_array = BlockArray.new
    longest_block_array = BlockArray.new

    hsps.each do | hsp |
      if current_block_array.length == 0 
        current_block_array << hsp
        next
      end 
      longest_block_array = current_block_array if current_block_array.length > longest_block_array.length
      gap_hit    =  hsp.hit_from   - current_block_array.hit_to   - 1   
      gap_query  =  hsp.query_from - current_block_array.query_to - 1
      if gap_hit > min_gap or gap_query > min_gap
        current_block_array = BlockArray.new
      end 
      current_block_array << hsp
    end

    longest_block_array = current_block_array if current_block_array.length > longest_block_array.length
    longest_block_array
  end
end