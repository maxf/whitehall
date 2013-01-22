class Admin::WorldwideOfficesController < Admin::BaseController
  respond_to :html

  before_filter :find_worldwide_office, only: [:edit, :update, :show, :contacts]
  before_filter :social_helper, only: [:new, :create, :edit, :update]
  before_filter :contact_helper, only: [:create, :update]
  attr :social, :contact

  def index
    respond_with @worldwide_offices = WorldwideOffice.all
  end

  def new
    @worldwide_office = WorldwideOffice.new
    social.build_social_media_account(@worldwide_office)
    respond_with @worldwide_office
  end

  def create
    contact.destroy_blank_phone_numbers(params[:worldwide_office])
    social.destroy_blank_social_media_accounts(params[:worldwide_office])
    @worldwide_office = WorldwideOffice.new(params[:worldwide_office])

    if @worldwide_office.save
      social.build_social_media_account(@worldwide_office)
    end

    respond_with @worldwide_office, location: admin_worldwide_office_path(@worldwide_office)
  end

  def edit
    social.build_social_media_account(@worldwide_office)
    respond_with @worldwide_office
  end

  def update
    contact.destroy_blank_phone_numbers(params[:worldwide_office])
    social.destroy_blank_social_media_accounts(params[:worldwide_office])
    @worldwide_office = WorldwideOffice.find(params[:id])

    unless @worldwide_office.update_attributes(params[:worldwide_office])
      social.build_social_media_account(@worldwide_office)
    end

    respond_with @worldwide_office, location: admin_worldwide_office_path
  end

  def destroy
    @worldwide_office = WorldwideOffice.find(params[:id])
    @worldwide_office.destroy
    respond_with @worldwide_office, location: admin_worldwide_offices_path
  end

  private

  def social_helper
    @social = Whitehall::Controllers::SocialMedia.new
  end

  def contact_helper
    @contact = Whitehall::Controllers::Contacts.new
  end

  def find_worldwide_office
    @worldwide_office = WorldwideOffice.find(params[:id])
  end
end
