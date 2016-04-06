# rating.rb
#
# business logic for rating players in a race.

require_relative '../models/racing'

module FormulaE
  module Services
    module Rating
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
        # groups = get_groups(race)

        ratings = Hash.new do |hash, race_result|
          puts "accessing #{race_result.racer.elo_rating}"
          # apply k-factor rules to the player directly, as the
          # configure block gets weird when it's called multiple times
          # over the life of the application.

          # for now, we simply use the number of racers as the k-factor.
          k_factor = race.results.size
          hash[race_result] = Elo::Player.new(k_factor: k_factor, rating: race_result.racer.elo_rating)
        end

        Elo.configure do |config|
          config.use_FIDE_settings = false
        end

        # groups.each do |racer1, group1|
        #   groups.each do |racer2, group2|
        #     if racer1 != racer2
        #       rating1 = ratings[racer1]
        #       rating2 = ratings[racer2]

        #       # update elo rating based on duel results.
        #       # lower numbered groups are better.
        #       game = rating1.versus(rating2)
        #       if group1 < group2
        #         game.winner = rating1
        #       elsif group2 < group1
        #         game.winner = rating2
        #       else
        #         game.draw
        #       end
        #     end
        #   end
        # end

        # http://sradack.blogspot.is/2008/06/elo-rating-system-multiple-players.html
        # implemented this, with the D factor being higher with less # of players.
        #
        # we probably need to tweak the scoring function a bit,
        # perhaps to make it work with groups better. also ideally we
        # do not want to store in 100s and * 10 for display. We need a
        # better score function that gives points to the last player,
        # instead of 0 points. It's too big of a jump. perhaps
        # percentage? This produces a decent range... though stll very
        # close together.
        #
        # Delete races 5 and 6 to return to production DB.

        rating_updates = {}

        race.results.each do |result|
          estimated = estimated_score(race.results, result)
          actual = actual_score(race.results, result)
          updated_elo = update_elo(race.results.size, result.racer.elo_rating, estimated, actual)

          puts "estimated, actual for #{result.racer.name} = #{estimated}, #{actual}"
          puts "updated elo for #{result.racer.name} = #{updated_elo}"

          rating_updates[result.racer] = updated_elo
        end

        rating_updates.each do |racer, updated_elo|
          racer.update(:elo_rating => updated_elo)
        end


        puts

        # ratings.each do |race_result, elo|
        #   race_result.racer.update(:elo_rating => elo.rating)
        # end

        # ratings
      end

      def self.estimated_score(race_results, curr_result)
        d_factor = 5 * (15 - race_results.size)

        num_players = race_results.size.to_f
        num_games = (num_players * (num_players - 1)) / 2
        num_games = num_games.to_f
        curr_elo = curr_result.racer.elo_rating.to_f

        estimated_score = 0.0

        race_results.each do |result|
          if result != curr_result
            other_elo = result.racer.elo_rating.to_f
            estimated_score += 1 / (1 + (10 ** ((other_elo - curr_elo) / d_factor)))
          end
        end

        estimated_score = estimated_score / num_games
        estimated_score
      end

      def self.actual_score(race_results, curr_result)
        num_players = race_results.size.to_f
        num_games = (num_players * (num_players - 1)) / 2
        num_games = num_games.to_f
        total_points = race_results.inject(0.0) { |pts, result| pts + result.points }

        actual_score = 0.0
        #actual_score = (num_players - curr_result.highest_place.to_f) / num_games
        actual_score = curr_result.points.to_f / total_points
        actual_score
      end

      def self.update_elo(num_players, curr_elo, estimated_score, actual_score)
        k_factor = 30
        curr_elo + k_factor * (actual_score - estimated_score)
      end

      # Reset all players and recaluclate ratings by running through all the races.
      def self.recalculate()
        Racer.all.each do |racer|
          racer.update(:elo_rating => Racer::DEFAULT_RATING)
        end

        Race.all.each do |race|
          self.rank(race)
        end
      end
    end
  end
end
