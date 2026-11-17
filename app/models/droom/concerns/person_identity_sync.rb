module Droom::Concerns::PersonIdentitySync
    def sync_with_person
      return if self.class.sync_in_progress || !saved_changes?

      self.class.sync_in_progress = true

      begin
        @person = person
        if @person
          [:title, :given_name, :family_name, :chinese_name, :gender, :email, :preferred_name, :hkid, :dob, :pob, :nationality].each do |col|
            if has_attribute?(col)
              next if @person.send(col) == send(col)
              if col == :given_name && @person.given_name.present? && !deliberate_given_name_change
                self.given_name = @person.given_name
              elsif send("saved_change_to_#{col}?")
                @person.send "#{col}=", send(col)
              elsif @person.send(col) != send(col)
                send "#{col}=", @person.send(col)
              end
            end
          end
          if @person.changed?
            @person.skip_user_sync = true
            @person.deliberate_given_name_change = true if deliberate_given_name_change
            raise 'Could not save the Croucher name in Core' unless @person.save
          end
          save if changed?
        end
      ensure
        self.class.sync_in_progress = false
        self.deliberate_given_name_change = false
      end
    end

end
