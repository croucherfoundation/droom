Rails.application.routes.draw do
  # Bopped application should not define a root route. 
  # Bop sweeps up everything unmatched.
  mount Bop::Engine => "/bop", :as => :bop
end
