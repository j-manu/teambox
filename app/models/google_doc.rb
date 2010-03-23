class GoogleDoc < ActiveRecord::Base
  belongs_to :comment
  belongs_to :user

  before_save :strip_requestor_id

  private
  def strip_requestor_id
    self.acl_link = uri_remove_param(self.acl_link)
    self.edit_link = uri_remove_param(self.edit_link)
    self.link = uri_remove_param(self.link)
  end

  def uri_remove_param(uri, params = 'xoauth_requestor_id')
   return uri unless params
   params = [params] if params.class == String
   uri_parsed = URI.parse(uri)
   return uri unless uri_parsed.query
   escaped = uri_parsed.query.grep(/&amp;/).size > 0
   new_params = uri_parsed.query.gsub(/&amp;/, '&').split('&').reject { |q| params.include?(q.split('=').first) }
   uri = uri.split('?').first
   amp = escaped ? '&amp;' : '&'
   new_params.size > 0 ?  "#{uri}?#{new_params.join(amp)}" : uri
 end
end
