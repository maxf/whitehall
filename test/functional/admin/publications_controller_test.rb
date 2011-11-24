require 'test_helper'

class Admin::PublicationsControllerTest < ActionController::TestCase
  setup do
    @user = login_as :policy_writer
  end

  test_controller_is_a Admin::BaseController

  test "new displays publication metadatum fields" do
    get :new

    assert_select "form#document_new" do
      assert_select "select[name*='document[publication_metadatum_attributes][publication_date']", count: 3
      assert_select "input[name='document[publication_metadatum_attributes][unique_reference]'][type='text']"
      assert_select "input[name='document[publication_metadatum_attributes][isbn]'][type='text']"
      assert_select "input[name='document[publication_metadatum_attributes][research]'][type='checkbox']"
      assert_select "input[name='document[publication_metadatum_attributes][order_url]'][type='text']"
    end
  end

  test 'creating should create a new publication' do
    first_org = create(:organisation)
    second_org = create(:organisation)
    first_policy = create(:published_policy)
    second_policy = create(:published_policy)
    attributes = attributes_for(:publication)

    post :create, document: attributes.merge(
      organisation_ids: [first_org.id, second_org.id],
      documents_related_to_ids: [first_policy.id, second_policy.id],
      publication_metadatum_attributes: attributes_for(:publication_metadatum)
    )

    created_publication = Publication.last
    assert_equal attributes[:title], created_publication.title
    assert_equal attributes[:body], created_publication.body
    assert_equal [first_org, second_org], created_publication.organisations
    assert_equal [first_policy, second_policy], created_publication.documents_related_to
  end

  test 'creating a publication should attach file' do
    greenpaper_pdf = fixture_file_upload('greenpaper.pdf', 'application/pdf')
    attributes = attributes_for(:publication)
    attributes[:attach_file] = greenpaper_pdf

    post :create, document: attributes.merge(
      publication_metadatum_attributes: attributes_for(:publication_metadatum)
    )

    assert publication = Publication.last
    assert_equal 1, publication.attachments.length
    attachment = publication.attachments.first
    assert_equal "greenpaper.pdf", attachment.carrierwave_file
    assert_equal "application/pdf", attachment.content_type
    assert_equal greenpaper_pdf.size, attachment.file_size
  end

  test 'creating a publication should create publication metadatum' do
    attributes = attributes_for(:publication)
    attributes[:publication_metadatum_attributes] = {
      publication_date: Date.parse("1805-10-21"),
      unique_reference: "unique-reference",
      isbn: "0140621431",
      research: true,
      order_url: "http://example.com/order-path"
    }

    post :create, document: attributes

    assert publication = Publication.last
    assert metadatum = publication.publication_metadatum
    assert_equal Date.parse("1805-10-21"), metadatum.publication_date
    assert_equal "unique-reference", metadatum.unique_reference
    assert_equal "0140621431", metadatum.isbn
    assert metadatum.research?
    assert_equal "http://example.com/order-path", metadatum.order_url
  end

  test 'creating should take the writer to the publication page' do
    post :create, document: attributes_for(:publication).merge(
      publication_metadatum_attributes: attributes_for(:publication_metadatum)
    )

    assert_redirected_to admin_publication_path(Publication.last)
    assert_equal 'The document has been saved', flash[:notice]
  end

  test 'creating with invalid data should leave the writer in the publication editor' do
    attributes = attributes_for(:publication)
    post :create, document: attributes.merge(title: '')

    assert_equal attributes[:body], assigns(:document).body, "the valid data should not have been lost"
    assert_template "documents/new"
  end

  test 'creating with invalid data should set an alert in the flash' do
    attributes = attributes_for(:publication)
    post :create, document: attributes.merge(title: '')

    assert_equal 'There are some problems with the document', flash.now[:alert]
  end

  test 'creating a publication with invalid data should not show any attachment info' do
    attributes = attributes_for(:publication)
    attributes[:attach_file] = fixture_file_upload('greenpaper.pdf')
    post :create, document: attributes.merge(title: '')

    assert_select "p.attachment", count: 0
  end

  test "creating a publication with invalid metadatum data" do
    attributes = attributes_for(:publication, title: "valid-title-to-keep")
    attributes[:publication_metadatum_attributes] = {
      unique_reference: "valid-reference-to-keep"
    }

    post :create, document: attributes

    assert_template "new"
    assert_select ".errors"
    assert_nil Publication.last
    assert_nil PublicationMetadatum.last
    assert_select "input[name='document[title]'][value='valid-title-to-keep']"
    assert_select "input[name='document[publication_metadatum_attributes][unique_reference]'][value='valid-reference-to-keep']"
  end

  test 'updating should save modified document attributes' do
    publication = create(:publication)

    put :update, id: publication.id, document: { title: "new-title", body: "new-body" }

    saved_publication = publication.reload
    assert_equal "new-title", saved_publication.title
    assert_equal "new-body", saved_publication.body
  end

  test 'updating a publication should attach file' do
    greenpaper_pdf = fixture_file_upload('greenpaper.pdf', 'application/pdf')
    publication = create(:publication)

    put :update, id: publication, document: publication.attributes.merge(attach_file: greenpaper_pdf)

    publication.reload
    assert_equal 1, publication.attachments.length
    attachment = publication.attachments.first
    assert_equal "greenpaper.pdf", attachment.carrierwave_file
    assert_equal "application/pdf", attachment.content_type
    assert_equal greenpaper_pdf.size, attachment.file_size
  end

  test "updating a publication should save modified metadatum attributes" do
    publication = create(:publication)
    new_metadatum_attributes = attributes_for(:publication_metadatum,
      publication_date: Date.parse("1815-06-18"),
      unique_reference: "new-reference",
      isbn: "0099532816",
      research: true,
      order_url: "https://example.com/new-order-path"
    )

    put :update, id: publication, document: publication.attributes.merge(
      publication_metadatum_attributes: new_metadatum_attributes
    )

    publication.reload
    assert metadatum = publication.publication_metadatum
    assert_equal Date.parse("1815-06-18"), metadatum.publication_date
    assert_equal "new-reference", metadatum.unique_reference
    assert_equal "0099532816", metadatum.isbn
    assert metadatum.research?
    assert_equal "https://example.com/new-order-path", metadatum.order_url
  end

  test 'updating should remove all organisations, related documents and ministerial roles if none in params' do
    org = create(:organisation)
    policy = create(:policy)
    minister = create(:ministerial_role)
    publication = create(:publication, organisations: [org], documents_related_to: [policy], ministerial_roles: [minister])

    put :update, id: publication, document: {}

    publication.reload
    assert_equal [], publication.organisations
    assert_equal [], publication.documents_related_to
    assert_equal [], publication.ministerial_roles
  end

  test 'updating should take the writer to the publication page' do
    publication = create(:publication)
    put :update, id: publication.id, document: {title: 'new-title', body: 'new-body'}

    assert_redirected_to admin_publication_path(publication)
    assert_equal 'The document has been saved', flash[:notice]
  end

  test 'updating with invalid data should not save the publication' do
    attributes = attributes_for(:publication)
    publication = create(:publication, attributes)
    put :update, id: publication.id, document: attributes.merge(title: '')

    assert_equal attributes[:title], publication.reload.title
    assert_template "documents/edit"
    assert_equal 'There are some problems with the document', flash.now[:alert]
  end

  test "updating with invalid metadatum data" do
    metadatum = create(:publication_metadatum, unique_reference: "original-reference")
    publication = create(:publication, title: "original-title", publication_metadatum: metadatum)

    put :update, id: publication.id, document: publication.attributes.merge(
      title: "valid-title-to-keep",
      publication_metadatum_attributes: {
        unique_reference: "valid-reference-to-keep"
      }
    )

    assert_template "edit"
    assert_select ".errors"
    publication.reload
    metadatum.reload
    assert_equal "original-title", publication.title
    assert_equal "original-reference", metadatum.unique_reference
    assert_select "input[name='document[title]'][value='valid-title-to-keep']"
    assert_select "input[name='document[publication_metadatum_attributes][unique_reference]'][value='valid-reference-to-keep']"
  end

  test 'updating a stale publication should render edit page with conflicting publication' do
    publication = create(:draft_publication)
    lock_version = publication.lock_version
    publication.touch

    put :update, id: publication, document: publication.attributes.merge(lock_version: lock_version)

    assert_template 'edit'
    conflicting_publication = publication.reload
    assert_equal conflicting_publication, assigns[:conflicting_document]
    assert_equal conflicting_publication.lock_version, assigns[:document].lock_version
    assert_equal %{This document has been saved since you opened it}, flash[:alert]
  end

  test "cancelling a new publication takes the user to the list of drafts" do
    get :new
    assert_select "a[href=#{admin_documents_path}]", text: /cancel/i, count: 1
  end

  test "cancelling an existing publication takes the user to that publication" do
    draft_publication = create(:draft_publication)
    get :edit, id: draft_publication
    assert_select "a[href=#{admin_publication_path(draft_publication)}]", text: /cancel/i, count: 1
  end

  test 'updating a submitted publication with bad data should show errors' do
    attributes = attributes_for(:submitted_publication)
    submitted_publication = create(:submitted_publication, attributes)
    put :update, id: submitted_publication, document: attributes.merge(title: '')

    assert_template 'edit'
  end

  test "should render the content using govspeak markup" do
    draft_publication = create(:draft_publication, body: "body-in-govspeak")
    Govspeak::Document.stubs(:to_html).with("body-in-govspeak").returns("body-in-html")

    get :show, id: draft_publication

    assert_select ".body", text: "body-in-html"
  end

  test "should display publication metadata" do
    metadatum = build(:publication_metadatum,
      publication_date: Date.parse("1916-05-31"),
      unique_reference: "unique-reference",
      isbn: "0099532816",
      research: true,
      order_url: "http://example.com/order-path"
    )
    publication = create(:publication, publication_metadatum: metadatum)

    get :show, id: publication

    assert_select ".document_view" do
      assert_select ".publication_date", text: "May 31st, 1916"
      assert_select ".unique_reference", text: "unique-reference"
      assert_select ".isbn", text: "0099532816"
      assert_select ".research", text: "Yes"
      assert_select "a.order_url[href='http://example.com/order-path']"
    end
  end

  test "should display PDF attachment metadata" do
    two_page_pdf = fixture_file_upload('two-pages.pdf', 'application/pdf')
    attachment = create(:attachment, file: two_page_pdf)
    publication = create(:publication, attachments: [attachment])

    get :show, id: publication

    assert_select_object(attachment) do
      assert_select ".type", "PDF"
      assert_select ".number_of_pages", "2 pages"
      assert_select ".size", "1.41 KB"
    end
  end

  test "should display CSV attachment metadata" do
    csv = fixture_file_upload('sample-from-excel.csv', 'text/csv')
    attachment = create(:attachment, file: csv)
    publication = create(:publication, attachments: [attachment])

    get :show, id: publication

    assert_select_object(attachment) do
      assert_select ".type", "CSV"
      assert_select ".number_of_pages", count: 0
      assert_select ".size", "121 Bytes"
    end
  end

  should_be_rejectable :publication
  should_be_force_publishable :publication
  should_be_able_to_delete_a_document :publication

  should_link_to_public_version_when_published :publication
  should_not_link_to_public_version_when_not_published :publication
end
