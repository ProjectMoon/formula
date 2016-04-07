require 'virtus'
require 'active_model'

require_relative './general'
require_relative '../models/racing'

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

      class RaceCoercion < Virtus::Attribute
        def coerce(value)
          if !value.is_a? Integer
            begin
              value = Integer(value, 10)
            rescue ArgumentError
              nil
            end
          end

          Race[value]
        end
      end

      # Form to add a race. See add_race.erb.
      class FinishRaceForm
        include Virtus.model
        include ActiveModel::Validations
        include ConstructorGuard

        attribute :race, RaceCoercion

        # race places
        10.times do |num|
          attribute "place#{num + 1}".to_sym, RacerCoercion
          attribute "eliminated#{num + 1}".to_sym, EliminatedCoercion
        end

        validates :race, presence: true

        validate do |form|
          # make sure at least one racer is in the list.
          racer_present = false

          10.times do |num|
            if !self.place(num+1).nil?
              racer_present = true
              break
            end
          end

          errors.add(:place1, "No racer selected") if !racer_present

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

        # Assemble a hash of racers as keys, a list of place-status
        # hashes as values.
        def places
          hsh = Hash.new([])
          10.times do |num|
            place = num + 1
            racer = self.public_send("place#{place}")

            if !racer.nil?
              puts "processing racer #{racer.name}"
              info = {
                place: place,
                status: self.public_send("eliminated#{place}")
              }

              hsh[racer] << info
              puts "put the stuff into the hash: #{hsh[racer]}"

              puts hsh
            end
          end

          puts hsh.size

          hsh.each do |racer, info|
            puts "#{racer.name}: #{info}"
          end

          hsh
        end
      end
    end
  end
end
