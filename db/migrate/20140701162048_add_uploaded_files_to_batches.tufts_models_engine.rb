# This migration comes from tufts_models_engine (originally 20140418153039)
class AddUploadedFilesToBatches < ActiveRecord::Migration
  def change
    change_table(:batches) do |t|
      t.column :uploaded_files, :text
    end
  end
end
