require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'shield'
require 'erubis'

require_relative './models/racing'
require_relative './models/users'

require_relative './forms/add_race'

require_relative './services/races'

module FormulaE end

module FormulaE::Web
  # module imports (currently, these do nothing because the models are
  # not in a module).
  User ||= FormulaE::Models::User
  Racer ||= FormulaE::Models::Racer

  class WebApp < Sinatra::Application
    configure do
      enable :sessions
      set :erubis, :escape_html => true
    end

    helpers Shield::Helpers

    helpers do
      def has_errors
        !error_message.nil?
      end

      def error_message_html
        html = "<div class='alert alert-danger' role='alert'>"
        html += "<span class='glyphicon glyphicon-exclamation-sign' aria-hidden='true'></span>"
        html += "<span class='sr-only'>Error:</span>"
        if error_message.is_a? Enumerable
          html += "<span>&nbsp;There were errors:</span>"
          html += "<ul>"
          error_message.each { |msg| html += "<li>#{msg}</li>" }
          html += "</ul>"
        else
          html += error_message
        end
        html += "</div>"
        session[:error_message] = nil # clear it so it's not shown more than once
        html
      end

      def error_message
        session[:error_message]
      end

      def set_error_message(errors)
        session[:error_message] = errors
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
      erubis :racer_table, :locals => { racers: Racer.all.sort_by(:elo_rating, :order => 'DESC') }
    end

    get '/races' do
      erubis :races, :locals => { races: Race.all }
    end

    get '/cars' do
      erubis :cars, :locals => { racers: Racer.all }
    end

    get '/login' do
      erubis :login
    end

    post '/login' do
      if login(User, params[:email], params[:password])
        remember(user) if params[:remember]
        redirect('/')
      else
        set_error_message 'Invalid username or password.'
        redirect('/login')
      end
    end

    get '/secure/add_race' do
      session[:form] = FormulaE::Web::Forms::AddRaceForm.new
      erubis :add_race, :locals => { form: session[:form], racers: Racer.all }
    end

    post '/secure/add_race' do
      form = FormulaE::Web::Forms::AddRaceForm.new(params)
      session[:form] = form
      if form.valid?
        service = FormulaE::Services::RaceService.new
        service.add_race(form)
        redirect('/')
      else
        set_error_message form.errors.full_messages
        erubis :add_race, :locals => { form: session[:form], racers: Racer.all }
      end
    end

    get '/logout' do
      logout(User)
      redirect '/'
    end
  end
end
