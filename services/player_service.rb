require_relative '../models/racing'

module FormulaE
  module Services

    class PlayerService
      def add_player(player_form)
        existing = Racer.find(name: player_form.name)

        if existing.size == 0
          racer = Racer.create(name: player_form.name)
          Car.basic_car(racer)
          Car.advanced_car(racer)
        else
          raise "Player #{player_form.name} already exists!"
        end
      end

      def delete_player(name)
        racer = Racer.find(name: name).first

        if !racer.nil?
          racer.delete
        else
          raise "No racer named #{name}"
        end
      end
    end
  end
end
