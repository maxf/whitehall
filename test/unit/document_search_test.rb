# require 'test_helper'

# class DocumentSearchTest < ActiveSupport::TestCase

#   test "#selected_topics returns an empty set by default" do
#     assert_equal [], Whitehall::DocumentSearch.new().selected_topics
#   end

#   test "#selected_organisations returns an empty set by default" do
#     assert_equal [], Whitehall::DocumentSearch.new().selected_organisations
#   end

#   test "#selected_publication_filter_option returns nil by default" do
#     assert_nil Whitehall::DocumentSearch.new().selected_publication_filter_option
#   end

#   test "departments param sets #selected_organisations" do
#     organisation = stub_organisation('defra')

#     filter = Whitehall::DocumentSearch.new(departments: [organisation.slug])

#     assert_equal [organisation], filter.selected_organisations
#   end

#   test "keywords param sets the keywords attribute" do
#     filter = Whitehall::DocumentSearch.new(keywords: "alpha beta")
#     assert_equal %w(alpha beta), filter.keywords
#   end

#   test "direction param sets direction attribute" do
#     assert_equal "before", Whitehall::DocumentSearch.new(direction: "before").direction
#   end

#   test "date param sets date attribute" do
#     assert_equal Date.parse("2012-01-01 12:23:45"), Whitehall::DocumentSearch.new(date: "2012-01-01 12:23:45").date
#   end

#   test "invalid date param sets date attribute to nil" do
#     assert_equal nil, Whitehall::DocumentSearch.new(date: "invalid-date").date
#   end

#   test "publication_filter_option param sets #selected_publication_filter_option" do
#     publication_filter_option = stub_publication_filter_option("testing filter option - statistics")
#     filter = Whitehall::DocumentSearch.new(publication_filter_option: publication_filter_option.slug)
#     assert_equal publication_filter_option, filter.selected_publication_filter_option
#   end

#   test "publication_type param also sets #selected_publication_filter_option to keep old links working" do
#     publication_filter_option = stub_publication_filter_option("testing filter option - statistics")
#     filter = Whitehall::DocumentSearch.new(publication_type: publication_filter_option.slug)

#     assert_equal publication_filter_option, filter.selected_publication_filter_option
#   end

#   test "publication_filter_option overwrites older publication_type param" do
#     publication_filter_option = stub_publication_filter_option("testing filter option - statistics")
#     filter = Whitehall::DocumentSearch.new(publication_type: 'foobar', publication_filter_option: publication_filter_option.slug)

#     assert_equal publication_filter_option, filter.selected_publication_filter_option
#   end

# private

#   def stub_organisation(slug)
#     organisation = stub("organisation-#{slug}", slug: slug, name: slug.humanize)
#     Organisation.stubs(:where).with(slug: [slug]).returns([organisation])
#     organisation
#   end

#   def stub_publication_type(slug, attributes={})
#     publication_type = stub("publication-type-#{slug}", {id: slug, slug: slug, pluralized_name: slug.humanize.pluralize}.merge(attributes))
#     PublicationType.stubs(:find_by_slug).with(slug).returns(publication_type)
#     publication_type
#   end

#   def stub_publication_filter_option(label, attributes={})
#     publication_filter_option = stub("publication-filter-option-#{label}", {
#       label: label.humanize.pluralize,
#       slug: label,
#       publication_types: [stub_publication_type(label)],
#       edition_types: []
#     }.merge(attributes))
#     Whitehall::PublicationFilterOption.expects(:find_by_slug).with(label).at_least_once.returns(publication_filter_option)
#     publication_filter_option
#   end
# end
