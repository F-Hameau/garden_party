class GardensController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home, :index]
  before_action :set_garden, only: [:show, :edit, :update, :destroy]

  def new
    @garden = Garden.new
    authorize @garden
  end

  def index
    @gardens = policy_scope(Garden)

    if params[:query].present?
      sql_query = " \
              gardens.name @@ :query \
              OR gardens.address @@ :query \
            "
      @gardens_list = Garden.where(sql_query, query: "%#{params[:query]}%")
    elsif params[:swim].present?
      @params = 'swim'
      @gardens_list = Garden.where(swimming_pool: true) if params[:swim] == 'true'
    elsif params[:bbq].present?
      @params = 'bbq'
      @gardens_list = Garden.where(barbecue: true) if params[:bbq] == 'true'
    else
      @gardens_list = Garden.all
    end

    @gardens = Garden.where.not(latitude: nil, longitude: nil)

    @markers = @gardens_list.map do |garden|
      {
        lng: garden.longitude,
        lat: garden.latitude,
        infoWindow: render_to_string(partial: "shared/infowindow", locals: { garden: garden })
      }
    end
  end

  def my_gardens
    @gardens = current_user.gardens
    authorize @gardens
  end

  def show
    @bookings = Booking.where(garden_id: @garden)
    authorize @garden
    @booking = Booking.new
    authorize @booking
    @dates = update_availabilities
  end

  def create
    @garden = Garden.new(garden_params)
    @garden.user = current_user
    authorize @garden
    if @garden.save!
      redirect_to garden_path(@garden)
    else
      render 'new'
    end
  end

  def edit
    authorize @garden
  end

  def update
    @garden.update(garden_params)
    authorize @garden
    redirect_to garden_path(@garden)
  end

  def destroy
    authorize @garden
    @garden.destroy
    redirect_to my_gardens_path
  end

  private

  def set_garden
    @garden = Garden.find(params[:id])
  end

  def garden_params
    params.require(:garden).permit(:name, :address, :description, :price, :swimming_pool, :barbecue, :max_guests, :photo)
  end

  def update_availabilities
    @garden.bookings.map do |booking|
      {
        from: booking.start_date,
        to: booking.end_date
      }
    end
  end
end
