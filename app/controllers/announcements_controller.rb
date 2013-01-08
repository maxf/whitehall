class AnnouncementsController < PublicFacingController
  include CacheControlHelper

  respond_to :html, :json
  respond_to :atom, only: :index

  class AnnouncementDecorator < SimpleDelegator
    def search
      __getobj__.announcement_search.results
    end
    def documents
      AnnouncementPresenter.decorate(__getobj__.announcement_search.results)
    end
    def count
      search.results.count
    end
    def current_page
      search.current_page
    end
    def num_pages
      search.total_pages
    end
    def total_count
      search.total_entries
    end
    def last_page?
      search.last_page?
    end
    def first_page?
      search.first_page?
    end
  end

  def index
    params[:page] ||= 1
    params[:date] ||= (Date.today + 1.month).beginning_of_month.to_s
    params[:direction] ||= "before"
    clean_malformed_params_array(:topics)
    clean_malformed_params_array(:departments)
    expire_on_next_scheduled_publication(scheduled_announcements)
    search = Whitehall::DocumentSearch.new(params)
    @filter = AnnouncementDecorator.new(search)

    respond_to do |format|
      format.html
      format.json do
        render json: AnnouncementFilterJsonPresenter.new(@filter)
      end
      format.atom do
        #TODO: Fix the atom sorting
        # @announcements = @filter.documents.sort_by(&:public_timestamp).reverse
        @announcements = @filter.documents
      end
    end
  end

private

  def scheduled_announcements
    @scheduled_announcements = Announcement.scheduled.order("scheduled_publication asc")
  end

end
