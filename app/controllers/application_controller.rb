class ApplicationController < ActionController::API
  include ActionController::RequestForgeryProtection
  protect_from_forgery with: :null_session, only: Proc.new { |c| c.request.format.json? }
  before_action :configure_permitted_parameters, if: :devise_controller?

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) << :name
    devise_parameter_sanitizer.for(:sign_up) << :provider
    devise_parameter_sanitizer.for(:sign_up) << :uid
  end

  def current_user    
    if auth_present?
        payload = AuthToken.decode(token.strip!)           
        if (payload[0]['exp'] < Time.now.to_i)
            render json: {error: "Unauthorized: Your token has expired. Please sign back in."}, status: 401 
        else                     
            @current_user ||= User.find_by_display_name(payload[0]['display_name'])
        end
    else
        render json: {error: "Unauthorized: No token found."}, status: 401 
    end        
  end

  def auth_present?    
    !!request.env.fetch("HTTP_AUTHORIZATION","").scan(/Bearer/).flatten.first
  end

  def token
    request.env["HTTP_AUTHORIZATION"].scan(/Bearer(.*)$/).flatten.last
  end

  def logged_in?
    current_user != nil
  end 

  def authenticate_user!
    head :unauthorized unless logged_in?
  end
end

# https://www.bungie.net/en/OAuth/Authorize?client_id=22602&response_type=code&state=8fj30dajadj