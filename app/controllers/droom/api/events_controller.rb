module Droom::Api
  class EventsController < Droom::Api::ApiController
    skip_before_action :assert_local_request!, only: [:calendar], raise: false
    prepend_before_action :authenticate_from_param, only: [:calendar]
    before_action :get_events, only: [:index]
    before_action :find_or_create_event, only: [:create]
    load_resource find_by: :uuid, class: "Droom::Event", except: [:calendar]
    
    def index
      render_api_success(resource: @events)
    end

    def show
      render_api_success(resource: @event)
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

      @events = Droom::Event.accessible_by(current_ability).includes(:event_type).where(
        "start <= ? AND (
          (end_date IS NOT NULL AND end_date >= ?) OR
          (end_date IS NULL AND finish IS NOT NULL AND finish >= ?) OR
          (end_date IS NULL AND finish IS NULL AND start >= ?)
        )",
        range.end, range.begin.to_date, range.begin, range.begin
      ).order(:start)

      render_api_success(resource: @events, each_serializer: Droom::CalendarSerializer)
    end

    def update
      if @event.update(event_params)
        @event.touch if @event.event_type&.slug == "screening" && @event.previous_changes.empty?
        render_api_success(resource: @event)
      else
        render_api_error(errors: @event.errors, status: :unprocessable_entity)
      end
    end

    def create
      if @event && @event.persisted?
        render_api_success(resource: @event)
      else
        render_api_error(errors: @event.errors, status: :unprocessable_entity)
      end
    end

    def destroy
      if @event.destroy
        render_api_success
      else
        render_api_error(errors: @event.errors, status: :unprocessable_entity)
      end
      
    end

  protected

    def find_or_create_event
      if params[:event]
        # Resolve event_type_slug to event_type_id so callers can pass a slug
        if params[:event][:event_type_slug].present?
          event_type = Droom::EventType.find_by(slug: params[:event].delete(:event_type_slug))
          params[:event][:event_type_id] = event_type.id if event_type
        end

        if params[:event][:uuid].present?
          # Serialize source-key retries even when the remote event exists but its
          # Applications link was not committed.
          event_type = Droom::EventType.find(event_params[:event_type_id])
          event_type.with_lock do
            @event = Droom::Event.find_or_initialize_by(uuid: params[:event][:uuid])
            @event.update!(event_params)
          end
          return
        end
      end
      @event ||= Droom::Event.create!(event_params)
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
      permitted = params.require(:event).permit(:name, :description, :event_set_id, :calendar_id, :event_type_id, :all_day, :url, :video_conference_link, :start, :finish, :end_date, :timezone, :venue_id, :venue_name, :private, :public)
      permitted[:uuid] = params[:event][:uuid] if action_name == "create" && params[:event][:uuid].present?
      permitted
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