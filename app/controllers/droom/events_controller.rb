module Droom
  class EventsController < Droom::DroomController
    include Droom::Concerns::ScanAttachedFile

    require "uri"
    require "icalendar"
    require "prawn"

    respond_to :html, :json, :ics, :js

    prepend_before_action :authenticate_from_param, only: [:subscribe]
    before_action :get_my_events, :only => [:subscribe]
    before_action :get_events, :only => [:index, :calendar]
    before_action :composite_dates, :only => [:update, :create]
    before_action :build_event, :only => [:new, :create]
    before_action :set_timezone_feature, :only => [:index, :show]
    load_and_authorize_resource

    before_action :set_event_invitation, only: [:show, :update]

    def index
      respond_with @events do |format|
        format.html { render :layout => 'centered' }
        format.js { render :partial => 'droom/events/events' }
      end
    end

    def calendar
      respond_with @events, layout: 'application_v2'
    end

    def subscribe
      cal = Icalendar::Calendar.new
      @events.each do |event|
        cal.add_event(event.icalendar_event)
      end
      render plain: cal.to_ical, content_type: 'text/calendar'
    end

    class Array
      def to_ics
        to_icalendar.to_ical
      end

      def to_icalendar
        cal = Icalendar::Calendar.new
        self.flatten.each do |item|
          cal.add_event(item.icalendar_event) if item.respond_to? :icalendar_event
        end
        cal
      end
    end

    def past
      @direction = "past"
      get_events
      respond_with @events do |format|
        format.html { render template: 'droom/events/index', layout: 'centered' }
        format.js { render partial: 'droom/events/events' }
      end
    end

    def show
      respond_with @event do |format|
        format.html { render :layout => 'centered' }
        format.js { render :partial => "droom/events/#{params[:view].presence || 'event'}" }
        format.zip { send_file @event.documents_zipped.path, :type => 'application/zip', :disposition => 'attachment', :filename => "#{@event.slug}.zip" }
      end
    end

    def new
      @event.start = Time.zone.now.change(hour: 10)
      respond_with @event
    end

    def create
      if @event.save
        set_success_flash_headers(@event, :create)

        if @event.stream?
          render :partial => "minimal", locals: { show_color_button: true }, status: :created
        else
          render :partial => "event", status: :created
        end
      else
        render_ajax_error(@event)
      end
    end

    def update
      if @event.update(event_params)
        set_success_flash_headers(@event, :update)
        
        if @event.stream?
          render :partial => "minimal", locals: { show_color_button: true }, status: :ok
        else
          if request.referrer =~ /\/events\/\d+/
            render :partial => "full", status: :ok
          else
            render :partial => "event", status: :ok
          end
        end
      else
        render_ajax_error(@event)
      end
    end

    def destroy
      @event.destroy
      set_delete_notice(@event)
      redirect_to droom.events_path
    end

    def upload_pdf
      file = params[:file]
      if file.content_type == "application/pdf"
        if error = scan_attachment('File', file.tempfile.path)
          render json: { error: error }, status: :unprocessable_entity
        else
          file_path = URI.open(file.tempfile).path
          event = Event.find(params[:id])
          event.generate_thumbnails(file_path)
          render json: { success: true }
        end

      else
        render json: { error: t("validations.file.invalid_type") }, status: :unprocessable_entity
      end
    end

    def show_compiled_file
      if @event.compiled_file.attached?
        redirect_to @event.compiled_file.url
      else
        raise ActiveRecord::RecordNotFound
      end
    end

    def compile_pdf

      @event.generate_pdf_cover if @event.thumbnails.empty? && @event.single_documents.empty?

      @thumbnails = @event.thumbnails.order(:position)
      @single_documents = @event.single_documents.order(:position)

      render layout: 'no_layout', template: 'droom/events/compile_pdf/show'
    end

    def compile_pdf_selection
      case request.method_symbol

      when :get
        render template: 'droom/events/compile_pdf/selection'

      when :post
        compile_type = params[:compile_type]
        selected_ids = params[:selected_ids]

        @event.update_columns(compile_type: compile_type, selected_document_ids: selected_ids)
        if @event.process_attached_documents
          render json: { redirect_url: compile_pdf_event_path(@event) }, status: :ok
        else
          render json: { error: 'Failed to generate PDF' }, status: :unprocessable_entity
        end
      else
        head :method_not_allowed
      end
    end

    def build_compile_pdf
      ActiveRecord::Base.transaction do
        @deleted_thumbnail_ids = compile_pdf_params[:deleted_items]
        @remaining_thumbnails = compile_pdf_params[:remaining_items]
        delete_thumbnails_documents if @deleted_thumbnail_ids.present?
        reposition_thumbnails_documents if @remaining_thumbnails.present?

        @event.combined_pdf
        head :ok
      rescue => e
        Rails.logger.error "Compile PDF failed: #{e.message}"
        head :unprocessable_entity
      end
    end

    def generate_pdf
      if @event.combined_pdf && @event.compiled_file.attached?
        render json: { success: true }
      else
        render json: { error: 'Failed to generate PDF' }, status: :unprocessable_entity
      end
    end

    def download_pdf
      if @event.compiled_file.attached?
        file = @event.compiled_file
        data = URI.open(file.url)
        send_data data.read,
                  filename: file.filename.to_s,
                  type: file.content_type,
                  disposition: 'attachment'
      else
        head :not_found
      end
    end

    def delete_pdf
      if @event.compiled_file.attached?
        @event.delete_compiled_file
        render json: { success: true }
      end
    end

  protected

    def set_timezone_feature
      @timezone_feature = FeatureFlag.enabled?('time-zone-feature', current_user)
    end

    def set_event_invitation
      @event_invitation = Droom::Invitation.where(user_id: current_user.id, event_id: @event.id).first if @event
    end

    def get_my_events
      @events = Droom::Event.accessible_by(current_ability)
      if Droom.config.separate_calendars?
        @events = @events.in_calendar(Droom::Calendar.default_calendar)
      end
      if scholar?
        @event_type = Droom::EventType.find_by_slug('other_events')
        @events = @events.where(event_type_id: @event_type.id)
      end
      @events
    end

    def get_events
      get_my_events

      if @direction == 'past'
        @events = @events.past.order('start DESC')

        if params[:year].present?
          @year = params[:year].to_i
          @events = @events.in_year(@year)
        end
      else
        @direction = 'future'
        @events = @events.future_and_current.order('start ASC')
      end

      # event_type filter applies to both past and future
      if params[:event_type].present?
        @event_type = Droom::EventType.find(params[:event_type])
        @events = @events.where(event_type_id: @event_type.id) if @event_type
      end

      @events = paginated(@events)
    end

    def build_event
      @event = Droom::Event.new(event_params)
      @event.created_by = current_user
    end

    # NB. the stored timezone parameter is just an interface convenience: we use it to display a consistent form.
    # The event start and finish dates are stored as datetimes with zones.
    #
    def composite_dates
      if params[:event]
        if params[:event][:start_date].present?
          # We adjust the given datetimes so that they are considered to happen in the given zone, if there is one.
          # If none is given, everything happen within the configured time zone for the application.
          date = Time.zone.parse(params[:event][:start_date])
          timezone = ActiveSupport::TimeZone.new(params[:event][:timezone]) if params[:event][:timezone].present?
          date = date.change(offset: timezone.utc_offset) if timezone
          timezone ||= Time.zone

          if params[:event][:start_time].present?
            start_time = Tod::TimeOfDay.parse(params[:event][:start_time])
            params[:event][:start] = start_time.on(date, timezone)
          end
          if params[:event][:finish_time].present?
            finish_time = Tod::TimeOfDay.parse(params[:event][:finish_time])
            params[:event][:finish] = finish_time.on(date, timezone)
          end
        end
      end
    end

    def event_params
      if params[:event]
        params.require(:event).permit(:name, :description, :video_conference_link, :meeting_number, :event_set_id, :event_type_id, :calendar_id, :all_day, :master_id, :url, :start, :finish, :end_date, :timezone, :venue_id, :venue_name, :cover_text, :short_code, :color_code)
      else
        {}
      end
    end

    # special case for calendar subscription
    # in which the user's authentication token is given as url param
    # later authenticate_user! action will cause subscription to fail if no user found here.
    #
    def authenticate_from_param
      if params[:tok].present?
        user = Droom::User.find_by(authentication_token: params[:tok])
        if user && user.data_room_user?
          sign_in user
        end
      end
    end

    def compile_pdf_params
      params.permit(deleted_items: [], remaining_items: [:id, :position])
    end

    def delete_thumbnails_documents
      thumbnails = @event.thumbnails.where(id: @deleted_thumbnail_ids)

      return if thumbnails.empty?

      positions = thumbnails.pluck(:position)
      @event.single_documents.where(position: positions).destroy_all
      thumbnails.destroy_all
    end

    def reposition_thumbnails_documents
      @remaining_thumbnails.each do |item|
        thumbnail = @event.thumbnails.find(item[:id])

        next if thumbnail.nil? || thumbnail.position == item[:position]

        thumbnail.single_document.update_column(:position, item[:position])
        thumbnail.update_column(:position, item[:position])
      end
    end
  end
end
