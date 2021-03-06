class RemoveNonSslEditionVideoUrls < ActiveRecord::Migration

  class EditionTable < ActiveRecord::Base
    set_table_name :editions
  end

  def change
    EditionTable.where("video_url LIKE 'http:%'").each do |edition|
      edition.update_attribute(:video_url, nil)
    end
  end
end
