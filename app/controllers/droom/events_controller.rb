module Droom
  class EventsController < Droom::DroomController
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

    def index
      respond_with @events do |format|
        format.js { render :partial => 'droom/events/events' }
      end
    end

    def calendar
      respond_with @events
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
      render template: "droom/events/index"
    end

    def show
      @event_invitation = Droom::Invitation.where(user_id: current_user.id, event_id: @event.id).first if @event
      respond_with @event do |format|
        format.js { render :partial => 'droom/events/event' }
        format.zip { send_file @event.documents_zipped.path, :type => 'application/zip', :disposition => 'attachment', :filename => "#{@event.slug}.zip" }
      end
    end

    def new
      @event.start = Time.zone.now.change(hour: 10)
      respond_with @event
    end

    def create
      if @event.save
        if @event.stream?
          render :partial => "minimal", locals: { show_color_button: true}
        else
          render :partial => "event"
        end
      else
        respond_with @event
      end
    end

    def update
      if @event.update(event_params)

        if @event.stream?
          render :partial => "minimal", locals: { show_color_button: true}
        else
          render :partial => "event"
        end
      else
        respond_with @event
      end
    end

    def destroy
      @event.destroy
      head :ok
    end

    def upload_pdf
      file = params[:file]
      if file.content_type == "application/pdf"
        file_path = URI.open(file.tempfile).path
        event = Event.find(params[:id])
        event.generate_thumbnails(file_path)
        render json: { success: true }
      else
        render json: { error: "Invalid file type" }, status: :unprocessable_entity
      end
    end

    def compile_pdf
      @event.pdf_cover_generate if @event.thumbnails.empty?

      @thumbnails = @event.thumbnails.order(:position)
      @single_documents = @event.single_documents.order(:position)

      render layout: 'no_layout'
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

  protected

    def pdf_cover_generate(event)
      meeting_texts = {
        1 => "A Trustees’ Meeting is to be held on #{event.start.strftime('%A %d %B %Y')} at #{event.start.strftime('%I:%M%p')}",
        2 => "A meeting of the NCF Nomination Committee is to be held on #{event.start.strftime('%A %d %B %Y')} at #{event.start.strftime('%I:%M%p')}",
        3 => "An Investment Committee Meeting is to be held on #{event.start.strftime('%A %d %B %Y')} at #{event.start.strftime('%I:%M%p')}",
        4 => "An Audit Committee Meeting is to be held on #{event.start.strftime('%A %d %B %Y')} at #{event.start.strftime('%I:%M%p')}",
        5 => "A Governors’ Meeting is to be held on #{event.start.strftime('%A %d %B %Y')} at #{event.start.strftime('%I:%M%p')}",
        6 => "A meeting of the CF Nomination & Remuneration Committee is to be held on #{event.start.strftime('%A %d %B %Y')} at #{event.start.strftime('%I:%M%p')}",
        7 => "A meeting of the Academic Assessment Working Group is to be held on #{event.start.strftime('%A %d %B %Y')} at #{event.start.strftime('%I:%M%p')}"
      }
      meeting_text = meeting_texts[event.event_type_id]


      pdf = Prawn::Document.new(page_size: "A4", margin: 0)
      pdf.fill_color = [1, 2, 3, 6].include?(event.event_type_id) ? "EE3A43" : "56C1FF"

      pdf.fill_rectangle [pdf.bounds.left, pdf.bounds.top], pdf.bounds.width, pdf.bounds.height

      logo_path = Rails.root.join("app/assets/images/croucher_logo.png")
      pdf.image logo_path, at: [45, 790], height: 110 if File.exist?(logo_path)

      pdf.fill_color "FFFFFF"
      pdf.font_families.update("MarrSans" => {
        :normal => Rails.root + "app/assets/stylesheets/ui-library/fonts/MarrSans-Regular.otf",
      })
      pdf.font "MarrSans"
      pdf.text_box meeting_text,
                  at: [40, 630], size: 30, width: 450, align: :left

      pdf.stroke_color "FFFFFF"

      pdf.text_box "\n\nTo join the meeting click <u><link href='#{"https://#{event.video_conference_link}"}'>here</link></u>",
                  at: [40, 450], size: 30, width: 450, align: :left, inline_format: true

      pdf.text_box "To go to the dataroom click <u><link href='https://data.croucher.org.hk'>here</link></u>",
                  at: [40, 260], size: 30, width: 450, align: :left, inline_format: true

      send_data pdf.render, filename: "first_pdf.pdf", type: "application/pdf", disposition: "inline"
      # cover_path = Rails.root.join("public/uploads/cover_#{event.id}.pdf")
      # pdf.render_file(cover_path)

      # cover_path.to_s

    end

    def set_timezone_feature
      @timezone_feature = FeatureFlag.enabled?('time-zone-feature', current_user)
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
      if params[:year].present?
        @year = params[:year].to_i
        @events = @events.in_year(@year).order('start ASC')
      elsif @direction == 'past'
        @events = paginated(@events.past.order('start DESC'))
      else
        @direction = 'future'
        @events = paginated(@events.future_and_current.order('start ASC'))
      end
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
        params.require(:event).permit(:name, :description, :video_conference_link, :meeting_number, :event_set_id, :event_type_id, :calendar_id, :all_day, :master_id, :url, :start, :finish, :end_date, :timezone, :venue_id, :venue_name)
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

  end
end
