require 'set'
require 'elo'
require 'ohm'


class Player
  DEFAULT_RATING = 1500

  attr_accessor :name
  attr_accessor :elo_rating

  def initialize(name, elo_rating = DEFAULT_RATING)
    @name = name
    @elo_rating = elo_rating
  end
end

class RaceResult
  attr_accessor :racer
  attr_accessor :status
  attr_accessor :places

  def initialize(racer, status, *places)
    @racer = racer
    @status = status
    @places = places
  end
end

class Race
  # Point scores used in a 10 car race. With less players, only higher
  # values are used. This is OK since the points are used to determine
  # the place for inputs into the Elo system.
  SCORES = [ 25, 18, 15, 12, 10, 8, 6, 4, 2, 1 ]

  # Internal class used to determine the overall placement of a player
  # in the race, based on their scored points.
  Standing = Struct.new(:racer, :status, :points) do
    # Compare method to determine ranking. If for some reason the
    # players have the same number of points, then the highest place
    # is used as a tie breaker.
    def <=>(other)
      if self.points == other.points
        # in this case we want to minimize, since lower number = higher place.
        @racer.highest_place <=> other.racer.highest_place
      else
        # for points, we want to maximize, not minimize.
        other.points <=> self.points
      end
    end
  end

  # TODO stuff like name, track, number, etc
  attr_accessor :racers
  attr_reader :standings

  def initialize()
    @racers = []
    @standings = SortedSet.new
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
