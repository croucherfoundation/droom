module Droom::Api
  class EventsController < Droom::Api::ApiController
    skip_before_action :assert_local_request!, only: [:calendar], raise: false
    prepend_before_action :authenticate_from_param, only: [:calendar]
    before_action :get_events, only: [:index]
    before_action :find_or_create_event, only: [:create]
    load_and_authorize_resource find_by: :uuid, class: "Droom::Event", except: [:calendar]
    skip_load_and_authorize_resource only: [:calendar]
    
    def index
      render json: @events
    end

    def show
      render json: @event
    end

    def calendar
      range_type = params[:range_type].presence || "month"
      date = params[:date].present? ? Date.parse(params[:date]) : Date.today
      
      range =
        case range_type
        when "day"   then date.beginning_of_day..date.end_of_day
        when "week"  then date.beginning_of_week(:sunday)..date.end_of_week(:sunday).end_of_day
        when "month" then date.beginning_of_month..date.end_of_month.end_of_day
        when "year"  then date.beginning_of_year..date.end_of_year.end_of_day
        end

      @events = Droom::Event.where(
        "start <= ? AND (
          (end_date IS NOT NULL AND end_date >= ?) OR
          (end_date IS NULL AND finish IS NOT NULL AND finish >= ?) OR
          (end_date IS NULL AND finish IS NULL AND start >= ?)
        )",
        range.end, range.begin.to_date, range.begin, range.begin
      ).order(:start)

      render json: @events, each_serializer: Droom::CalendarSerializer
    end

    def update
      @event.update(event_params)
      render json: @event
    end

    def create
      if @event && @event.persisted?
        render json: @event
      else
        render json: {
          errors: @event.errors.to_a
        }
      end
    end

    def destroy
      @event.destroy
      head :ok
    end

  protected

    def find_or_create_event
      if params[:event]
        if params[:event][:uid].present?
          @event = Droom::Event.where(uid: params[:event][:uid]).first
        end
      end
      @event ||= Droom::Event.create(event_params)
    end

    def get_events
      events = Droom::Event.in_name_order
      if params[:q].present?
        @fragments = params[:q].split(/\s+/)
        @fragments.each { |frag| events = events.matching(frag) }
      end
      @events = events
    end

    def event_params
      params.require(:event).permit(:name, :description, :event_set_id, :calendar_id, :event_type_id, :all_day, :url, :start, :finish, :timezone, :venue_id, :venue_name)
    end

    def authenticate_from_param
      if params[:tok].present?
        user = Droom::User.find_by(authentication_token: params[:tok])
        if user && user.data_room_user?
          sign_in user
        else
          raise Droom::AccessDenied
        end
      else
        raise Droom::AccessDenied
      end
    end

  end
end