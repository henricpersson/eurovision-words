require 'nokogiri'
require 'httparty'
require 'set'

@all_words = {}

def load_stopwords
  f = File.open('stopwords.txt')
  words = []
  f.each_line do |word|
    words.push(normalize(word))
  end
  words
end

def normalize(word)
  word.downcase.strip.gsub(/[^a-z]/, '')
end

def url(path)
  "http://www.diggiloo.net/#{path}"
end

def add_word(word)
  count = @all_words[word] || 0
  @all_words[word] = count + 1
end

def process_lyrics_on_url(url)
  doc = Nokogiri::HTML(HTTParty.get(url))
  doc.css('#lyrics-table td').each do |line|
    line.content.split.each do |word|
      word = normalize(word)
      add_word(word) unless word.empty? || @stopwords.include?(word)
    end
  end
end

def get_song_urls
  urls = []
  range = 1956..2010
  puts "Finding (English) songs from #{range.first} to #{range.last}..."
  range.each do |year|
    doc = Nokogiri::HTML(HTTParty.get(url("?#{year}.all")))
    links = doc.css('table.list td.t a[title=\'English version\']')
    links.each do |link|
      urls.push(url(link.[]('href')))
      print '.'
    end
  end
  puts
  urls
end

def process_songs
  song_urls = get_song_urls
  puts "Reading lyrics from these #{song_urls.count} songs..."
  song_urls.each do |url|
    process_lyrics_on_url(url)
    print '.'
  end
  puts
end

def process_results
  results = @all_words.sort_by { |word, count| -count }
  print_results(results)
  write_results_to_file(results)
end

def write_results_to_file(results)
  File.open(@output_filename, 'w') do |f|
    results.each do |word, count|
       f.write "#{word}: #{count}\n"
    end
  end
  puts "Full report written to #{@output_filename}."
end

def print_results(results)
  puts "\nRESULTS - sorted by occurrence"
  puts '-------------------------------'
  results.first(40).each do |word, count|
    puts "#{word}: #{count}"
  end
  puts
end

def check_and_init_args
  if ARGV.count != 1
    abort 'Missing filename argument'
  elsif File.exist? ARGV[0]
    abort "File already exists: #{ARGV[0]}"
  end
  @output_filename = ARGV[0]
end

check_and_init_args
@stopwords = load_stopwords
process_songs
process_results


