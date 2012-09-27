FactoryGirl.define do
  
  factory :event, :class => "Droom::Event"  do
    description "an event"
    
    factory :simple_event do
      name "Simple Event"
      start "2009-11-03 18:30:00"
    end

    factory :closed_event do
      sequence(:name)  {|n| "Event #{n}" }
      start "2009-11-03 10:30:00"
      finish "2009-11-03 18:30:00"
    end
    
    factory :repeating_event do
      name "Repeating Event"
      start "2009-11-03 18:30:00"
      finish "2009-11-03 20:00:00"
      after(:create) { |event|
        event.recurrence_rules.create(:period => "weekly", :interval => "1", :basis => 'count', :limiting_count => "4")
      }
    end

    factory :spanning_event do
      name "Simple Event"
      start "2009-11-03 09:00:00"
      finish "2009-11-04 17:00:00"
    end
    
    factory :allday_event do
      name "All Day Event"
      start "2009-11-03 09:00:00"
      finish "2009-11-04 17:00:00"
      all_day true
    end
    
  end
  
end
