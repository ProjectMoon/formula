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
      def has_errors
        !error_message.nil? && !error_message.empty?
      end

      def error_message_html
        html = "<div class='alert alert-danger' role='alert'>"
        html += " <span class='glyphicon glyphicon-exclamation-sign' aria-hidden='true'></span>"
        html += "<span class='sr-only'>Error:</span>"
        html += error_message
        html += "</div>"
        session[:error_message] = nil # clear it so it's not shown more than once
        html
      end

      def error_message
        session[:error_message]
      end

      def error_message=(msg)
        session[:error_message] = msg
      end

      def user
        authenticated(User)
      end

      def logged_in
        authenticated(User) != nil
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

    get '/login' do
      erb :login
    end

    post '/login' do
      puts "hello"
      puts params
      if login(User, params[:email], params[:password])
        remember(user) if params[:remember]
        redirect('/')
      else
        session[:error_message] = 'Invalid username or password.'
        redirect('/login')
      end
    end

    get '/secure/add_race' do
      erb :add_race
    end

    post '/secure/add_race' do
      # TODO add the race.
    end

    get '/logout' do
      logout(User)
      redirect '/'
    end
  end
end
