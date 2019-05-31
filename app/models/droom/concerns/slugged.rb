module Droom::Concerns::Slugged
  extend ActiveSupport::Concern
  
  def slug_from_name
    ensure_presence_of_unique(:slug, name.parameterize)
  end

  def slug_from_name_and_year
    ensure_presence_of_unique(:slug, "#{year} #{name}".parameterize)
  end

  def ensure_presence_of_unique(column, base, skope=self.class.all)
    unless self.send "#{column}?".to_sym
      value = base
      addendum = 1
      existing_record = skope.order(created_at: 'desc').where("#{column} like ?", "#{value}%").pluck(column.to_sym).first
      while existing_record
        record_number = existing_record.split('_').last
        if record_number = Integer(record_number) rescue false
          addendum+=record_number.to_i
        end
        value = "#{base}_#{addendum}"
        existing_record = skope.order(created_at: 'desc').where("#{column} like ?", "#{value}%").pluck(column.to_sym).first
      end
      self.send :"#{column}=", value
    end
  end

end