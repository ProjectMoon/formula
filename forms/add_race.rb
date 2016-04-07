require 'virtus'
require 'active_model'

require_relative './general'
require_relative '../models/racing'

module FormulaE
  module Web
    module Forms

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
          end

          Racer[value]
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

        # race start positions
        10.times do |num|
          attribute "start#{num + 1}".to_sym, RacerCoercion
        end

        validates :number, :date, :type, :circuit, presence: true

        validate do |form|
          # make sure at least one racer is in the list.
          racer_present = false

          10.times do |num|
            if !self.position(num+1).nil?
              racer_present = true
              break
            end
          end

          errors.add(:start1, "No racer selected") if !racer_present

          # make sure that the places are contiguous, i.e. the
          # previous place (minus 1st) should always have a value if
          # the current place has a racer.
          10.times do |num|
            place = num + 1
            next if place <= 1
            curr_racer = self.public_send("start#{place}")

            if curr_racer != nil
              prev_racer = self.public_send("start#{place - 1}")
              if prev_racer.nil?
                errors.add "start#{place - 1}".to_sym, "Grid position is missing."
              end
            end
          end
        end

        # Convenience method to get the racer at a position.
        def position(num)
          self.public_send("start#{num}")
        end

        # Assemble a hash of racers as keys, with the grid positions
        # as the value.
        def grid_positions
          hsh = Hash.new([])

          10.times do |num|
            place = num + 1
            racer = self.position(place)

            if !racer.nil?
              hsh[racer] << place
            end
          end

          hsh
        end
      end
    end
  end
end
