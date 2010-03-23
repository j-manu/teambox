class Comment

  def save_uploads(params)
    params[:uploads].if_defined.each do |upload_id|
      if upload = Upload.find(upload_id)
        upload.comment_id = self.id
        upload.description = truncate(h(upload.comment.body), :length => 80)
        upload.save(false)
      end
    end
    clean_deleted_uploads(params)
  end

  def save_google_docs(params,current_user,session)
    current_docs = session[:current_google_docs] || Gdata.new(current_user.email).list
    if session[:google_mp] &&  !params[:google_doc_ids].blank? && current_docs
      current_docs.each do |doc|
        if params[:google_doc_ids].include?(doc.doc_id)
           doc.comment_id = self.id
           doc.user_id = current_user.id
           doc.save
        end
      end
    end
    session[:current_google_docs] = nil
  end

  protected

    def clean_deleted_uploads(params)
      params[:uploads_deleted].if_defined.each do |upload_id|
        upload = Upload.find(upload_id)
        upload.destroy if upload
      end
    end

end
