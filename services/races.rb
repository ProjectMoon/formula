require_relative '../forms/add_race'
require_relative '../models/racing'
require_relative '../services/rating'

module FormulaE
  module Services
    # The race service contains all business logic relating to
    # manipuation of races.
    class RaceService
      def add_race(race_form)
        race = Race.create(number: race_form.number, date: race_form.date,
                           type: race_form.type, circuit: race_form.circuit)

        race_form.places.each do |place, racer_info|
          racer = racer_info[:racer]

          if !racer.nil?
            # TODO pick the car
            puts "found racer #{racer}"

            case race_form.type
            when :advanced
              car = racer.car('Advanced Car')
            when :basic
              car = racer.car('Basic Car')
            end

            race << RaceResult.create(car: car, race: race, racer: racer,
                                      status: racer_info[:status], places: place)
          end
        end

        race.save_all
        Rating.rank(race)
      end
    end
  end
end
