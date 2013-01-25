class AnnouncementsController < PublicFacingController
  include CacheControlHelper

  respond_to :html, :json
  respond_to :atom, only: :index

  class OldAnnouncementDecorator < SimpleDelegator
    def documents
      AnnouncementPresenter.decorate(__getobj__.documents)
    end
  end
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
    @es = params[:test]
    if @es == "es"
      search = Whitehall::DocumentSearch.new(params)
      @filter = AnnouncementDecorator.new(search)
    else
      document_filter = Whitehall::DocumentFilter.new(all_announcements, params)
      @filter = OldAnnouncementDecorator.new(document_filter)
    end

    respond_to do |format|
      format.html
      format.json do
        render json: AnnouncementFilterJsonPresenter.new(@filter)
      end
      format.atom do
        @announcements = @filter.documents.sort_by(&:public_timestamp).reverse
        # TODO: Fix the atom sorting in ES
        # @announcements = @filter.documents
      end
    end
  end

private

  def all_announcements
    Announcement.published.includes(:document, :organisations)
  end

  def scheduled_announcements
    @scheduled_announcements ||= begin
      all_scheduled_announcements = Announcement.scheduled.order("scheduled_publication asc")
      filter = Whitehall::DocumentFilter.new(all_scheduled_announcements, params.except(:direction))
      filter.documents
    end
    # @scheduled_announcements = Announcement.scheduled.order("scheduled_publication asc")
  end

end
