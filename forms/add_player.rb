require 'virtus'
require 'active_model'

module FormulaE
  module Web
    module Forms

      # Form for adding a player. See add_player.erb.
      class AddPlayerForm
        include Virtus.model
        include ActiveModel::Validations

        attribute :name, String

        validates :name, presence: true
      end
    end
  end
end
