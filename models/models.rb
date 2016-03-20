require 'set'
require 'elo'
require 'ohm'

# TODO set up redis connection

class Racer < Ohm::Model
  DEFAULT_RATING = 1500

  attribute :name
  attribute :elo_rating
  index :name
end

class RaceResult < Ohm::Model
  reference :racer, :Racer
  attribute :status
  attribute :points, lambda { |p| p.to_i }
  reference :race, :Race

  def <=>(other)
    # for points, we want to maximize, not minimize.
    other.points <=> self.points
  end
end

class Race < Ohm::Model
  attr_reader :standings
  collection :results, :RaceResult

  # Point scores used in a 10 car race. With less players, only higher
  # values are used. This is OK since the points are used to determine
  # the place for inputs into the Elo system.
  SCORES = [ 25, 18, 15, 12, 10, 8, 6, 4, 2, 1 ]

  def standings()
    if @standings.nil?
      @standings = SortedSet.new(self.results)
    end

    @standings
  end

  def <<(race_result)
    @racers << race_result.racer
    standing = Standing.new(race_result.racer, race_result.status, calculate_points(race_result.places))
    @standings << standing
  end

  def [](i)
    @racers[i]
  end

  def in_place(place)
    @standings.to_a[place - 1].racer
  end

  def standings_not_eliminated
    @standings.select { |standing| standing.racer.status != :eliminated }
  end

  # Make sure that the number of places defined on the players matches
  # the number of cars, that no place number is higher than 10, and
  # that the place numbers are all sequential (e.g. not 1st, 2nd,
  # 4th). If it's a multi-car race, make sure everyone has multiple
  # cars.
  def validate()
    # TODO ... later
  end

  # Calculate the points for the player in the race, determined by the
  # placement of all the cars in the race controlled by that player.
  def calculate_points(places)
    places.inject(0) { |pts, place| pts += SCORES[place - 1] }
  end
end

race = Race.create
jeff = Racer.create(name: 'jeff', elo_rating: 1500)
res = RaceResult.create(race: race, racer: jeff, status: :finished, points: 25)
jeff.save()
res.save()
race.save()

# load er up

r = Race[1]
puts r.standings.to_a[0].racer.name
r.results.each do |result|
  puts result.points
end

# TODO fix the overloaded operators, make it easier to add people, update other code to work w/ these properties
