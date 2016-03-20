require 'ohm'
require_relative './racing'

jeff = Racer.find(name: 'Jeff').first
puts jeff.race_results.size
jeff.race_results.each do |result|
  puts result.race
end
