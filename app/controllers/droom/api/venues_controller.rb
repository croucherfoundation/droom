module Droom::Api
  class VenuesController < Droom::Api::ApiController
    before_action :get_venues, only: [:index]
    before_action :find_or_create_venue, only: [:create]
    load_resource find_by: :slug, class: "Droom::Venue"
    # after_filter :set_pagination_headers, only: [:index]

    def index
      render json: Droom::VenueSerializer.new(@venues)
    end

    def show
      return_venue
    end

    def update
      @venue.update(venue_params)
      return_venue
    end

    def create
      return_venue
    end

    def destroy
      @venue.destroy
      head :ok
    end

    def return_venue
      render json: Droom::VenueSerializer.new(@venue)
    end

  protected

    def find_or_create_venue
      if params[:venue]
        if params[:venue][:slug].present?
          @venue = Droom::Venue.where(slug: params[:venue][:slug]).first
        end
        if params[:venue][:name].present?
          @venue ||= Droom::Venue.where(name: params[:venue][:name]).first
        end
      end
      @venue ||= Droom::Venue.create(venue_params)
    end

    def build_venue
      @venue = Droom::Venue.new
    end

    def get_venues
      venues = Droom::Venue.in_name_order

      if params[:q].present?
        @fragments = params[:q].split(/\s+/)
        @fragments.each { |frag| venues = venues.matching(frag) }
      end
      @venues = venues

      # @show = params[:show] || 20
      # @page = params[:page] || 1
      # if @show == 'all'
      #   @venues = venues
      # else
      #   @venues = venues.page(@page).per(@show)
      # end
    end

    def venue_params
      params.require(:venue).permit(:name, :lat, :lng, :address, :post_code, :country_code)
    end

  end
end
