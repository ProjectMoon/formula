require 'virtus'
require 'active_model'

require_relative './general'

module FormulaE
  module Web
    module Forms

      # Form for adding a player. See add_player.erb.
      class AddPlayerForm
        include Virtus.model
        include ActiveModel::Validations
        include ConstructorGuard

        attribute :name, String

        validates :name, presence: true
      end
    end
  end
end
