# rating.rb
#
# business logic for rating players in a race.

module FormulaE::Rating
  # Generate a list of hashes, each with two keys "player" and
  # "group". Player is the player object, while group is the grouping
  # to be used for Elo rating input. With 10 cars in the race, the first 9 places
  # are groups 1 to 5 (with group 1 being reserved for 1st place) and
  # group 6 is for 10th. With less players, the lower places start
  # getting put into their own groups (8th and 9th are groups 5 and 6
  # with 9 cars, for example).
  def self.get_groups(race)
    # qualifying_groups is the number of groups that are based on
    # points. group 7 is a special group for people eliminated.
    num_players = race.results.size

    # key is player, value is group number.
    groups = {}

    # keep track of any already-processed players to prevent
    # duplicates.
    processed = []

    # first handle eliminated people. they are forced to group 7 no
    # matter what place they came in.
    race.standings.each do |standing|
      if standing.status == :eliminated
        groups[standing.racer] = 7
        processed << standing.racer
      end
    end

    # first is always its own group
    first_player = race.racer_in_place(1)
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
      racer = race.racer_in_place(place)
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
      racer = race.racer_in_place(place)
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

  # Calculate new elo ratings based on input race data. Racers are
  # grouped according to the rules of the get_groups method. This
  # method pairs each racer against each other and uses their group
  # number to calculate elo rating. Lower-numbered groups win against
  # higher-numbered groups, while the same group is a tie This method
  # alters the racers' elo ratings. This method returns a hash where
  # the keys are the racers and the values are the elo rating objects
  # generated.
  def self.rank(race)
    groups = get_groups(race)

    ratings = Hash.new do |hash, racer|
      hash[racer] = Elo::Player.new(:rating => racer.elo_rating)
    end

    Elo.configure do |config|
      config.default_k_factor = race.results.size
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

    ratings.each do |racer, elo|
      racer.update(:elo_rating => elo.rating)
    end

    ratings
  end
end
