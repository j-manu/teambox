class GoogleDocsController < ApplicationController
  skip_before_filter :load_project
  def index
    @docs = session[:google_mp] ? Gdata.new(current_user.email).list : []
    # Not sure about the performance impact of storing the docs list in session
    # currently clearing it after creation of comment
    session[:current_google_docs] = @docs
    respond_to do |format|
      format.js
    end
  end

  def show
    doc = GoogleDoc.find(params[:id])
    # collecting ids and then checking for include because checking with objects
    # was unreliable in my experience
    if doc.comment.project.users.collect {|u| u.id}.include?(current_user.id)
        gd = Gdata.new(doc.user.email)
        resp = gd.add_acl_member(doc.acl_link,current_user.email)
        unless [201,409].include?(resp.code.to_i)
          flash.now[:error] = "Access denied to the document"
        end
    else
      flash.now[:error] = "You will not be able to view this document because you are not among the project users"
    end
  end

end
