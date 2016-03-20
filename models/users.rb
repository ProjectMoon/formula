require 'ohm'
require 'ohm/contrib'
require 'shield'

module FormulaE
  module Models
    class User < Ohm::Model
      include Shield::Model

      attribute :email
      attribute :crypted_password
      # TODO more stuff like team name, cars, etc.
      # TODO tie to racer

      unique :email

      # Required by Shield. Given a username (email), return the
      # corresponding user.
      def self.fetch(email_address)
        User.with(:email, email_address)
      end
    end
  end
end
