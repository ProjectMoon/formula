require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'shield'

require_relative './models/racing'
require_relative './models/users'

module FormulaE end

module FormulaE::Web
  # module imports
  User ||= FormulaE::Models::User
  Racer ||= FormulaE::Models::Racer

  class WebApp < Sinatra::Application
    configure do
      enable :sessions
    end

    helpers Shield::Helpers

    helpers do
      def user
        authenticated(User)
      end

      def username
        !user.nil? ? user.email : "not logged in"
      end
    end

    before '/secure/*' do
      error(401) unless authenticated(User)
    end

    # Display the table of players and their ratings.
    get '/' do
      erb :racer_table, :locals => { racers: Racer.all.sort_by(:elo_rating, :order => 'DESC') }
    end

    get '/races' do
      erb :races, :locals => { races: Race.all }
    end

    get '/cars' do
      erb :cars, :locals => { racers: Racer.all }
    end

    get '/secure/add_race' do
      erb :add_race
    end

    post '/secure/add_race' do
      # TODO add the race.
    end
  end
end
