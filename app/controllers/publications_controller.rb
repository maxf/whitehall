class PublicationsController < DocumentsController
  class PublicationesqueDecorator < SimpleDelegator
    def search
      __getobj__.published_publication_search.results
    end
    def documents
      PublicationesquePresenter.decorate(__getobj__.published_publication_search.results)
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
    params[:direction] ||= "before"

    clean_malformed_params_array(:topics)
    clean_malformed_params_array(:departments)

    expire_on_next_scheduled_publication(scheduled_publications)
    search = Whitehall::DocumentSearch.new(params)
    @filter = PublicationesqueDecorator.new(search)

    respond_to do |format|
      format.html
      format.json do
        render json: PublicationFilterJsonPresenter.new(@filter)
      end
      format.atom do
        # TODO fix atom feed
        # @publications = @filter.documents.sort_by(&:public_timestamp).reverse
        @publications = @filter.documents
      end
    end
  end

  def show
    @related_policies = @document.statistics? ? [] : @document.published_related_policies
    set_slimmer_organisations_header(@document.organisations)
  end

private

  def scheduled_publications
    @scheduled_publications = Publicationesque.scheduled.order("scheduled_publication asc")
  end

  def document_class
    Publication
  end
end
