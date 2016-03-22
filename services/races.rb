require_relative '../models/racing'

module FormulaE
  module Web
    module Services

      # Form to add a race. See add_race.erb.
      class AddRaceForm
        attr_reader :params

        attr_reader :number
        attr_reader :date
        attr_reader :type
        attr_reader :circuit

        attr_reader :places

        def initialize(params)
          @params = params
          @number = params[:number]
          @date = params[:date]
          @type = params[:type]
          @circuit = params[:circuit]
          @places = {}

          params.select { |k, v| k.start_with?('place') }.each do |place_input, racer_id|
            place = place_input["place".length..-1]
            @places[place.to_i] = {
              racer_id: racer_id.to_i, # TODO don't to_i this... validate!
              status: params.has_key?("eliminated#{place}") ? :eliminated : :finished
            }
          end
        end
      end

      # The race service contains all business logic relating to
      # manipuation of races.
      class RaceService
        def add_race(race_form)
          race = Race.create(number: race_form.number, date: race_form.date,
                             type: race_form.type, circuit: race_form.circuit)

          race_form.places.each do |place, racer_info|
            racer = Racer[racer_info[:racer_id]]

            if !racer.nil?
              # TODO pick the car
              puts "found racer #{racer}"
              race << RaceResult.create(car: racer.cars[0], race: race, racer: racer,
                                        status: racer_info[:status], places: place)
            end
          end

          race.save_all
        end
      end
    end
  end
end
