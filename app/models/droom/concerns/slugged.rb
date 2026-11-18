module Droom::Concerns::Slugged
  extend ActiveSupport::Concern

  included do
    validates :slug, presence: true, uniqueness: true
  end

  def slug_from_title
    ensure_presence_of_unique(:slug, title.parameterize)
  end

  def slug_from_title_and_date
    date = created_at || Time.now.to_datetime
    datestring = I18n.l date, format: :filename
    ensure_presence_of_unique(:slug, "#{title} #{datestring}".parameterize)
  end

  def slug_from_name
    ensure_presence_of_unique(:slug, name.parameterize)
  end

  def slug_from_name_and_year
    ensure_presence_of_unique(:slug, "#{year} #{name}".parameterize)
  end

  def resolve_existing_slug_collision
    return unless persisted? && slug.present? && !will_save_change_to_slug?
    return unless self.class.where(slug: slug).where.not(id: id).exists?

    base = slug
    self.slug = nil
    ensure_presence_of_unique(:slug, base)
  end

  def ensure_presence_of_unique(column, base, skope=self.class.all)
    unless self.send "#{column}?".to_sym
      slug = base.presence || self.class.to_s.underscore
      addendum = 0
      while skope.find_by(slug: slug)
        addendum += 1
        slug = "#{base}_#{addendum}"
      end
      self.send :"#{column}=", slug
    end
  end

end