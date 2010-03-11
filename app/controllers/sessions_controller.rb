# This controller handles the login/logout function of the site.
class SessionsController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  include AuthenticatedSystem

  skip_before_filter :login_required, :except => [ :destroy ]
  skip_before_filter :confirmed_user?
  skip_before_filter :load_project
  before_filter :set_page_title

  def new
    @signups_enabled = signups_enabled?
    respond_to do |format|
      format.html { redirect_to root_path if logged_in? }
      format.m
    end
  end

  def new_oauth
    consumer = get_consumer
    next_url = "http://#{APP_CONFIG['app_domain']}/session/create_oauth"
    request_token = consumer.get_request_token({:oauth_callback => next_url}, {:scope => "https://www.google.com/m8/feeds/"})
    session[:oauth_secret] = request_token.secret
    redirect_to request_token.authorize_url
  end

  def create_oauth
    logout_keeping_session!
    request_token = OAuth::RequestToken.new(get_consumer, params[:oauth_token], session[:oauth_secret])
    access_token = request_token.get_access_token(:oauth_verifier => params[:oauth_verifier])
    xml = XmlSimple.xml_in(access_token.get("https://www.google.com/m8/feeds/contacts/default/full/").body)
    email = xml["author"].first["email"].first
    user = User.find_by_email(email)
    if !user || !user.login
      user = user || User.new(:email => email)
      user.first_name = xml["author"].first["name"].first
      user.save(false)
      session[:new_google_user_id] = user.id
      redirect_to complete_profile_user_url(user)
      #user.oauth_token  =  access_token.token
      #user.oauth_secret =  access_token.secret
    else
      self.current_user = user
      flash[:error] = nil
      redirect_back_or_default root_path
    end
  end


  def create
    @signups_enabled = signups_enabled?
    logout_keeping_session!
    user = User.authenticate(params[:login], params[:password])
    if user
      # Protects against session fixation attacks, causes request forgery
      # protection if user resubmits an earlier form using back
      # button. Uncomment if you understand the tradeoffs.
      # reset_session
      self.current_user = user
      handle_remember_cookie! true
      flash[:error] = nil
      redirect_back_or_default root_path
    else
      note_failed_signin
      @login       = params[:login]
      @remember_me = true
      render :action => 'new'
    end
  end

  def destroy
    logout_killing_session!
    redirect_back_or_default root_path
  end

protected
  # Track failed login attempts
  def note_failed_signin
    flash[:error] = "Couldn't log you in as '#{params[:login]}'"
    logger.warn "Failed login for '#{params[:login]}' from #{request.remote_ip} at #{Time.now.utc}"
  end
end
