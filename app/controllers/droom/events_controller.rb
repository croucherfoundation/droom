module Droom
  class EventsController < Droom::DroomController
    require "uri"
    require "icalendar"
    layout 'no_layout', only: [:compile_pdf]

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

    def compile_pdf
      @pdf_images = Droom::Thumbnail.where(document_id: 3896)
      @pdf_img = [
        { url: "https://www.slideteam.net/media/catalog/product/cache/1280x720/c/r/creative_one_page_booklet_cover_template_presentation_report_infographic_ppt_pdf_document_slide01.jpg", page_number: 1 },
        { url: "https://marketplace.canva.com/EAGHUG_eCjQ/1/0/501w/canva-blue-illustrative-business-book-cover-vTEd7B2uzOo.jpg", page_number: 2 },
        { url: "https://www.slideteam.net/media/catalog/product/cache/1280x720/c/r/creative_one_page_booklet_cover_template_presentation_report_infographic_ppt_pdf_document_slide01.jpg", page_number: 3 },
        { url: "https://marketplace.canva.com/EAGHUG_eCjQ/1/0/501w/canva-blue-illustrative-business-book-cover-vTEd7B2uzOo.jpg", page_number: 4 },
        { url: "https://www.slideteam.net/media/catalog/product/cache/1280x720/c/r/creative_one_page_booklet_cover_template_presentation_report_infographic_ppt_pdf_document_slide01.jpg", page_number: 5 }
      ]
      # pdf = Prawn::Document.new
      # pdf.fill_color "87CEFA"
      # pdf.fill_rectangle [pdf.bounds.left, pdf.bounds.top], pdf.bounds.width, pdf.bounds.height

      # logo_path = Rails.root.join("app/assets/images/croucher_logo.png")
      # pdf.image logo_path, at: [50, 700], height: 50 if File.exist?(logo_path)

      # pdf.fill_color "FFFFFF"
      # pdf.font "Helvetica"
      # pdf.text_box "A Governors’ Meeting is to be held on Tuesday 22 October at 3:30pm",
      #             at: [150, 650], size: 24, width: 400, align: :left

      # send_data pdf.render, filename: "first_pdf.pdf", type: "application/pdf", disposition: "inline"
    
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

  protected

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
