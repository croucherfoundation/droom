atom_feed :language => 'en-US' do |feed|
  feed.title "HKFx Stream"
  feed.updated Time.now

  @scraps.each do |scrap|
    feed.entry( scrap ) do |entry|
      entry.title scrap.name || "(#{scrap.scraptype})"

      if scrap.scraptype == 'link'
        entry.url scrap.url_with_protocol
      else
        entry.url droom.scrap_url(scrap)
      end
      
      if scrap.scraptype == "image"
        entry.icon request.host + scrap.image_url(:thumb)
      end
      
      entry.content [scrap.body, scrap.note].compact.join('<br />'), :type => 'html'

      # the strftime is needed to work with Google Reader.
      entry.updated(scrap.created_at.strftime("%Y-%m-%dT%H:%M:%SZ")) 
      entry.author scrap.created_by.name if scrap.created_by
    end
  end
end
