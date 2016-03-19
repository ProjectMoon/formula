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

  def racer_at_place(place)
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

  # Generate a list of hashes, each with two keys "player" and
  # "group". Player is the player object, while group is the grouping
  # to be used for Elo rating input. With 10 cars in the race, the first 9 places
  # are groups 1 to 5 (with group 1 being reserved for 1st place) and
  # group 6 is for 10th. With less players, the lower places start
  # getting put into their own groups (8th and 9th are groups 5 and 6
  # with 9 cars, for example).
  def get_groups()
    # qualifying_groups is the number of groups that are based on
    # points. group 7 is a special group for people eliminated.
    num_players = racers.size

    # key is player, value is group number.
    groups = {}

    # keep track of any already-processed players to prevent
    # duplicates.
    processed = []

    # first handle eliminated people. they are forced to group 7 no
    # matter what place they came in.
    @standings.each do |standing|
      if standing.status == :eliminated
        groups[standing.racer] = 7
        processed << standing.racer
      end
    end

    # first is always its own group
    first_player = racer_at_place(1)
    groups[first_player] = 1
    processed << first_player

    # determine number of single groups in this race. capped at the
    # number of players to prevent array index overrun.
    if num_players < 10
      single_groups = (10 - num_players) + 1

      if single_groups > num_players
        single_groups = num_players - 1
      end
    else
      single_groups = 0
    end

    # Handle the double grouped players (2nd to 9th place in 10 player race)

    # for each player in the double ranked groups (2nd to whatever
    # place), their target group is place / 2 and rounded up.
    last_target = 0
    upper_bound = num_players - single_groups
    for place in (2..upper_bound)
      racer = racer_at_place(place)
      target = (place / 2).ceil
      if !processed.include?(racer)
        groups[racer] = target + 1
        processed << racer
      end
      last_target = target
    end

    # single-grouped players: use last target of the double ranked
    # players to figure out where they go, and increment.
    for place in (upper_bound)..num_players
      break if place > num_players
      racer = racer_at_place(place)
      target = last_target
      last_target += 1
      if !processed.include?(racer)
        groups[racer] = target + 1
        processed << racer
      end
    end

    # lower-numbered groups come first.
    groups.sort_by {|_player, group| group}
  end

  # Given a list of player names (strings) in an array that represents
  # their averaged place in a race, return a set of "duels" to be used
  # as input into elo. Each duel has two players, each with their group
  # as the determining factor for win/loss/draw.
  def duel()
    groups = get_groups()
    ratings = Hash.new do |hash, racer|
      hash[racer] = Elo::Player.new(:rating => racer.elo_rating)
    end

    Elo.configure do |config|
      config.default_k_factor = @racers.size
      config.use_FIDE_settings = false
    end

    groups.each do |racer1, group1|
      groups.each do |racer2, group2|
        if racer1 != racer2
          rating1 = ratings[racer1]
          rating2 = ratings[racer2]

          # update elo rating based on duel results.
          # lower numbered groups are better.
          game = rating1.versus(rating2)
          if group1 < group2
            game.winner = rating1
          elsif group2 < group1
            game.winner = rating2
          else
            game.draw
          end
        end
      end
    end

    # update the ratings of all players in the race.
    @racers.each do |racer|
      racer.elo_rating = ratings[racer].rating
    end

    ratings
  end
end
