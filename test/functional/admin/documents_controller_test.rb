require 'test_helper'

class Admin::DocumentsControllerTest < ActionController::TestCase
  setup do
    @user = login_as :policy_writer
  end

  test_controller_is_a Admin::BaseController

  test 'should distinguish between document types when viewing the list of draft documents' do
    policy = create(:draft_policy)
    publication = create(:draft_publication)
    get :draft

    assert_select_object(policy) { assert_select ".type", text: "Policy" }
    assert_select_object(publication) { assert_select ".type", text: "Publication" }
  end

  test "should order by most recently updated" do
    policy = create(:draft_policy, updated_at: 3.days.ago)
    newer_policy = create(:draft_policy, updated_at: 1.minute.ago)
    get :draft

    assert_equal [newer_policy, policy], assigns(:documents)
  end

  test 'should distinguish between document types when viewing the list of submitted documents' do
    policy = create(:submitted_policy)
    publication = create(:submitted_publication)
    get :submitted

    assert_select_object(policy) { assert_select ".type", text: "Policy" }
    assert_select_object(publication) { assert_select ".type", text: "Publication" }
  end

  test 'should distinguish between document types when viewing the list of published documents' do
    policy = create(:published_policy)
    publication = create(:published_publication)
    get :published

    assert_select_object(policy) { assert_select ".type", text: "Policy" }
    assert_select_object(publication) { assert_select ".type", text: "Publication" }
  end

  test 'viewing the list of submitted policies should not show draft policies' do
    draft_document = create(:draft_policy)
    get :submitted

    refute assigns(:documents).include?(draft_document)
  end

  test 'viewing the list of published policies should only show published policies' do
    published_documents = [create(:published_policy)]
    get :published

    assert_equal published_documents, assigns(:documents)
  end

  test 'submitting should set submitted on the document' do
    draft_document = create(:draft_policy)
    post :submit, id: draft_document

    assert draft_document.reload.submitted?
  end

  test 'submitting should redirect back to show page' do
    draft_document = create(:draft_policy)
    post :submit, id: draft_document

    assert_redirected_to admin_policy_path(draft_document)
    assert_equal "Your document has been submitted for review by a second pair of eyes", flash[:notice]
  end

  test "revising the published document should create a new draft document" do
    published_document = create(:published_policy)
    Document.stubs(:find).returns(published_document)
    draft_document = create(:draft_policy)
    published_document.expects(:create_draft).with(@user).returns(draft_document)
    draft_document.expects(:valid?).returns(true)

    post :revise, id: published_document
  end

  test "revising a published document redirects to edit for the new draft" do
    published_document = create(:published_policy)

    post :revise, id: published_document

    draft_document = Document.last
    assert_redirected_to edit_admin_policy_path(draft_document.reload)
  end

  test "failing to revise an document should redirect to the existing draft" do
    published_document = create(:published_policy)
    existing_draft = create(:draft_policy, document_identity: published_document.document_identity)

    post :revise, id: published_document

    assert_redirected_to edit_admin_policy_path(existing_draft)
    assert_equal "There is already an active draft for this document", flash[:alert]
  end

  test "should be able to filter by policies when viewing list of documents" do
    policy = create(:draft_policy)
    publication = create(:draft_publication)
    get :draft, filter: 'policy'

    assert_select_object(policy) { assert_select ".type", text: "Policy" }
    assert_select ".type", text: "Publication", count: 0
  end

  test "should be able to filter by publications when viewing list of documents" do
    policy = create(:draft_policy)
    publication = create(:draft_publication)
    get :draft, filter: 'publication'

    assert_select_object(publication) { assert_select ".type", text: "Publication" }
    assert_select ".type", text: "Policy", count: 0
  end

  test "should be able to filter by speeches when viewing list of documents" do
    policy = create(:draft_policy)
    speech_types = [
      :speech_transcript,
      :speech_draft_text,
      :speech_speaking_notes,
      :speech_written_statement,
      :speech_oral_statement
    ]
    instances_of_each_speech_type = speech_types.map {|t| create(t) }

    get :draft, filter: 'speech'

    instances_of_each_speech_type.each do |speech|
      assert_select_object(speech) { assert_select ".type", text: speech.type.titleize }
    end

    assert_select ".type", text: "Policy", count: 0
  end

  test "should be able to filter by news articles when viewing list of documents" do
    policy = create(:draft_policy)
    news = create(:news_article)
    get :draft, filter: 'news_article'

    assert_select_object(news) { assert_select ".type", text: "News Article" }
    assert_select ".type", text: "Policy", count: 0
  end

  test "should be able to filter by consultations when viewing list of documents" do
    policy = create(:draft_policy)
    consultation = create(:consultation)
    get :draft, filter: 'consultation'

    assert_select_object(consultation) { assert_select ".type", text: "Consultation" }
    assert_select ".type", text: "Policy", count: 0
  end

  test "should be able to show only documents authored by user when viewing list of documents" do
    user = create(:policy_writer)
    authored_policy = create(:draft_policy, creator: user)
    other_policy = create(:draft_policy)

    get :draft, author: user

    assert_select_object authored_policy
    assert_select_object other_policy, count: 0
  end

  test "should be able to show only documents related to an organisation" do
    organisation = create(:organisation)
    user = create(:policy_writer, organisation: organisation)

    policy_in_organisation = create(:draft_policy, organisations: [organisation])
    other_policy = create(:draft_policy, organisations: [create(:organisation)])

    get :draft, organisation: organisation

    assert_select_object policy_in_organisation
    assert_select_object other_policy, count: 0
  end

  test "should remember standard filter options" do
    get :draft, filter: 'consultation'
    assert_equal 'consultation', session[:document_filters][:filter]
  end

  test "should remember author filter options" do
    get :draft, author: @user
    assert_equal @user.to_param, session[:document_filters][:author]
  end

  test "should remember organisation filter options" do
    organisation = create(:organisation)
    get :draft, organisation: organisation
    assert_equal organisation.to_param, session[:document_filters][:organisation]
  end

  test "should remember state filter options" do
    get :draft
    assert_equal 'draft', session[:document_filters][:action]
  end

  test "index should redirect to remembered filtered options if available" do
    organisation = create(:organisation)
    session[:document_filters] = { action: :submitted, author: @user.to_param, organisation: organisation.to_param }
    get :index
    assert_redirected_to submitted_admin_documents_path(author: @user, organisation: organisation)
  end

  test "index should redirect to submitted in my department if logged an editor has no remembered filters" do
    organisation = create(:organisation)
    editor = login_as create(:departmental_editor, organisation: organisation)
    get :index
    assert_redirected_to submitted_admin_documents_path(organisation: organisation)
  end

  test "index should redirect to drafts I have written if a writer has no remembered filters" do
    writer = login_as create(:policy_writer)
    get :index
    assert_redirected_to draft_admin_documents_path(author: writer)
  end

  test "index should redirect to drafts if filtered options don't form a route" do
    session[:document_filters] = { action: :unknown }
    get :index
    assert_redirected_to draft_admin_documents_path
  end
end
