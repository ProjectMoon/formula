require_relative '../forms/add_race'
require_relative '../models/racing'
require_relative '../services/rating'
require_relative './result'

module FormulaE
  module Services
    # The race service contains all business logic relating to
    # manipuation of races.
    class RaceService
      def add_race(race_form)
        race = Race.new(number: race_form.number, date: race_form.date, status: :started,
                        type: race_form.type, circuit: race_form.circuit)

        begin
          saved = race.save
        rescue Ohm::UniqueIndexViolation
          return ServiceResult.new(false, "Race number #{race_form.number} already exists.")
        end

        if saved
          race_form.grid_positions.each do |racer, positions|
            if !racer.nil?
              # add or update a RaceBeginning
              RaceBeginning.create(race: race, racer: racer, grid_positions: positions)
            end
          end

          race.save_all
          ServiceResult.new(true)
        else
          ServiceResult.new(false, 'Unable to create race.')
        end
      end

      def finish_race(race_form)
        if !race_form.race.nil?
          race_form.places.each do |racer, places_and_statuses|
            puts "#{racer.name}: #{places_and_statuses}"
          end

          ServiceResult.new(true)
        else
          ServiceResult.new(false, 'Race not found')
        end
      end
    end
  end
end
