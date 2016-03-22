require 'virtus'
require 'active_model'

require_relative './general'

module FormulaE
  module Web
    module Forms

      # Coerce the eliminated status in the checkbox on the form.
      class EliminatedCoercion < Virtus::Attribute
        def coerce(value)
          if value == "true"
            :eliminated
          else
            :finished
          end
        end
      end

      # We only allow certain symbols for the race type.
      class TypeSymbol < Virtus::Attribute
        def coerce(value)
          case value
          when "basic"; :basic
          when "advanced"; :advanced
          when "custom"; :custom
          else nil
          end
        end
      end

      # Coercion for racer in the race, used for the places. If the
      # racer doesn't exist, return nil.
      class RacerCoercion < Virtus::Attribute
        def coerce(value)
          if !value.is_a? Integer
            begin
              value = Integer(value, 10)
            rescue ArgumentError
              nil
            end

            Racer[value]
          end
        end
      end

      # Form to add a race. See add_race.erb.
      class AddRaceForm
        include Virtus.model
        include ActiveModel::Validations
        include ConstructorGuard

        attribute :number, Integer
        attribute :date, String
        attribute :type, TypeSymbol
        attribute :circuit, String

        # race places
        10.times do |num|
          attribute "place#{num + 1}".to_sym, RacerCoercion
          attribute "eliminated#{num + 1}".to_sym, EliminatedCoercion
        end

        validates :number, :date, :type, :circuit, presence: true

        validate do |form|
          # make sure that the places are contiguous, i.e. the
          # previous place (minus 1st) should always have a value if
          # the current place has a racer.
          10.times do |num|
            place = num + 1
            next if place <= 1
            curr_racer = self.public_send("place#{place}")

            if curr_racer != nil
              prev_racer = self.public_send("place#{place - 1}")
              if prev_racer.nil?
                errors.add "place#{place - 1}".to_sym, "Place is missing."
              end
            end
          end
        end

        # Convenience method to get the racer at a place.
        def place(num)
          self.public_send("place#{num}")
        end

        # Convenience method to get the status of a racer at a place.
        def status(num)
          self.public_send("eliminated#{num}")
        end

        # Assemble a hash of places as keys, with the racer ID and
        # their finishing status as values.
        def places
          hsh = {}
          10.times do |num|
            place = num + 1
            racer = self.public_send("place#{place}")

            if !racer.nil?
              hsh[place] = {
                racer: racer,
                status: self.public_send("eliminated#{place}")
              }
            end
          end

          hsh
        end
      end
    end
  end
end
