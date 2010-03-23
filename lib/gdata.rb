class Gdata
  SEARCH_URL = 'http://docs.google.com/feeds/documents/private/full'
  LIST_URL = 'http://docs.google.com/feeds/documents/private/full'
  MAX_DOCS = 50
  def initialize(requestor_id)
    consumer = OAuth::Consumer.new(OAUTH_CONFIG['market_consumer_key'],OAUTH_CONFIG['market_consumer_secret'])
    @access_token = OAuth::AccessToken.new(consumer)
    @params = {:xoauth_requestor_id => requestor_id}
  end

  def search(query)
  end

  def list
    params = @params.merge({"start-index" => 1, "max-results" => MAX_DOCS})
    handle_response(@access_token.get(full_url(LIST_URL, params)))
  end

  def remove_acl_member(acl_link,email)
    acl_link += '/' + CGI.escape('user:' + email)
    @access_token.delete(full_url(acl_link,@params))
  end

  def add_acl_member(acl_link,email,type='writer')
    acl_entry = <<-EOF
    <entry xmlns="http://www.w3.org/2005/Atom" xmlns:gAcl='http://schemas.google.com/acl/2007'>
      <category scheme='http://schemas.google.com/g/2005#kind'
        term='http://schemas.google.com/acl/2007#accessRule'/>
      <gAcl:role value='#{type}'/>
      <gAcl:scope type='user' value='#{email}'/>
    </entry>
    EOF
    @access_token.post(full_url(acl_link,@params),acl_entry, { 'Content-Type' => 'application/atom+xml' })
  end

  private

  def full_url(url,params)
    url + '?' + convert_params(params)
  end

  def handle_response(res)
    docs = []
    if res.code == '200'
      document = Nokogiri::XML(res.body)
      entries = document.xpath("//atom:entry", "atom" => "http://www.w3.org/2005/Atom")
      entries.each do |entry|
        doc = GoogleDoc.new
        doc.doc_type,doc.doc_id = entry.xpath("./gd:resourceId", "gd" => "http://schemas.google.com/g/2005").text.split(':')
        doc.link = entry.xpath("./atom:link[@rel='alternate']", "atom" => "http://www.w3.org/2005/Atom").first["href"]
        doc.edit_link = entry.xpath("./atom:link[@rel='edit']", "atom" => "http://www.w3.org/2005/Atom").first["href"]
        doc.acl_link = entry.xpath("./gd:feedLink[@rel='http://schemas.google.com/acl/2007#accessControlList']","gd" => "http://schemas.google.com/g/2005").first["href"]
        doc.title = entry.xpath("./atom:title/text()", "atom" => "http://www.w3.org/2005/Atom").first.text
        docs << doc
      end
    end
    return docs
  end

  def convert_params(params)
    stack = []
    res = ''

    params.each do |k, v|
      if v.is_a?(Hash)
        stack << [k,v]
      else
        res << "#{k}=#{v}&"
      end
    end

    stack.each do |parent, hash|
      hash.each do |k, v|
        if v.is_a?(Hash)
          stack << ["#{parent}[#{k}]", v]
        else
          res << "#{parent}[#{k}]=#{v}&"
        end
      end
    end

    res.chop! # trailing &
    res
  end
end
