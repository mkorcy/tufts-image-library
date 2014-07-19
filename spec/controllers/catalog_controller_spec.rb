require 'rails_helper'

describe CatalogController do
  let(:user) { FactoryGirl.create(:user) }
  let(:admin) { FactoryGirl.create(:admin) }

  describe "an unauthenticated user" do
    describe "GET index" do
      it "redirects to sign in" do
        get :index
        expect(response).to redirect_to new_user_session_path
      end
    end

    describe "GET show" do
      it "redirects to sign in" do
        get :show, id: 1
        expect(response).to redirect_to new_user_session_path
      end
    end
  end

  describe "authenticated user" do
    before { sign_in user }

    describe "GET index" do
      before do
        PersonalCollection.destroy_all
        CourseCollection.destroy_all
      end

      describe "the sidebar" do
        let!(:my_collection1) { FactoryGirl.create(:personal_collection, user: user) }
        let!(:my_collection2) { FactoryGirl.create(:personal_collection, user: user) }
        let!(:not_my_collection) { FactoryGirl.create(:personal_collection) }

        it "should be a great success" do
          get :index
          expect(response).to be_success
          expect(assigns[:my_collection]).to eq user.personal_collection_proxy
          expect(assigns[:root_collection]).to eq CourseCollectionSolrProxy.root
        end
      end

      describe "the search results" do
        let!(:course_collection) { FactoryGirl.create(:course_collection) }
        let!(:image) { FactoryGirl.create(:tufts_image, displays: ['tdil']) }
        let!(:template) { FactoryGirl.create(:tufts_template, displays: ['tdil']) }
        let!(:pdf) { FactoryGirl.create(:tufts_pdf, displays: ['tdil']) }

        it "only shows images and collections" do
          get :index
          found = assigns[:document_list].map(&:id)
          expect(found).to include(course_collection.pid, image.pid)
          expect(found).to_not include(template.pid)
          expect(found).to_not include(pdf.pid)
          expect(found).to_not include(CourseCollection::ROOT_PID)
        end

      end
    end

    describe "GET show" do
      context 'images with "tdil" display' do
        let(:tdil_img) { FactoryGirl.create(:image, displays: ['tdil']) }

        it 'is successful' do
          get :show, id: tdil_img.pid
          expect(response).to render_template(:show)
          expect(response).to be_successful
          expect(assigns[:document]).to_not be_nil
        end
      end

      context 'images with non-tdil display' do
        let(:dl_img) { FactoryGirl.create(:image, displays: ['dl']) }
        it 'denies access' do
          get :show, id: dl_img.pid
          expect(response).to redirect_to root_path
          expect(flash[:alert]).to match(/You do not have sufficient access/)
        end
      end
    end

    describe "PATCH add_to_collection" do
      let(:image) { FactoryGirl.create(:tufts_image, displays: ['tdil']) }
      it "adds to my collection" do
        collection = FactoryGirl.create(:personal_collection, user: user, displays: ['tdil'])
        patch :add_to_collection, id: image.id, collection_id: collection.id
        expect(response).to redirect_to(catalog_path(image))
        expect(collection.reload.members).to include(image)
      end

      it "doesn't add to another user's collection" do
        collection = FactoryGirl.create(:personal_collection, displays: ['tdil'])
        patch :add_to_collection, id: image.id, collection_id: collection.id
        expect(collection.reload.members).to_not include(image)
      end

      it "doesn't add to a course collection" do
        collection = FactoryGirl.create(:course_collection, displays: ['tdil'])
        patch :add_to_collection, id: image.id, collection_id: collection.id
        expect(collection.reload.members).to_not include(image)
      end
    end
  end

  describe "authenticated user" do
    let(:image) { FactoryGirl.create(:tufts_image, displays: ['tdil']) }
    before { sign_in admin }

    describe "PATCH add_to_collection" do
      it "adds to my collection" do
        collection = FactoryGirl.create(:personal_collection, user: admin, displays: ['tdil'])
        patch :add_to_collection, id: image.id, collection_id: collection.id
        expect(response).to redirect_to(catalog_path(image))
        expect(collection.reload.members).to include(image)
      end

      it "adds to another user's collection" do
        collection = FactoryGirl.create(:personal_collection, displays: ['tdil'])
        patch :add_to_collection, id: image.id, collection_id: collection.id
        expect(response).to redirect_to(catalog_path(image))
        expect(collection.reload.members).to include(image)
      end

      it "adds to a course collection" do
        collection = FactoryGirl.create(:course_collection, displays: ['tdil'])
        patch :add_to_collection, id: image.id, collection_id: collection.id
        expect(response).to redirect_to(catalog_path(image))
        expect(collection.reload.members).to include(image)
      end
    end
  end
end
