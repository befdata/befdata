module ApplicationHelper
  include Acl9Helpers
  # and now for something completely different: mail address ciphering
  # kindly presented by unixmonkey.net (http://unixmonkey.net/?p=20)
  
  # Rot13 encodes a string
  def rot13(string)
    string.tr "A-Za-z", "N-ZA-Mn-za-m"
  end

  def html_obfuscate(string)
    lower = ('a'..'z').to_a
    upper = ('A'..'Z').to_a
    string.split('').map { |char|
      output = lower.index(char) + 97 if lower.include?(char)
      output = upper.index(char) + 65 if upper.include?(char)
      output ? "&##{output};" : char
    }.join
  end
  
  # Takes in an email address and (optionally) anchor text,
  # its purpose is to obfuscate email addresses so spiders and
  # spammers can't harvest them.
  def antispam_email_link(email, linktext=nil) 
    mail_to email, linktext, :encode => :hex unless email.blank?
  end
  
  def edit_page_link_to(page)
    link_to(image_tag("edit.gif",:alt => "Edit", :title => "Edit"), :controller => 'admin/pages', :action => 'edit', :id => page)
  end
  
  def display_page(page)
    prefix = "<span style=\"float: right;\">"
    postfix = "</span>"
    output = prefix
    
    if logged_in?
      if @current_user.has_role?("admin")
        output += edit_page_link_to(page)
      end
    end
    
    output += postfix
    output += page.content
    
    return output
  end

  def project_id(shortname)
    return shortname.split('sp').last.chop
  end

  # Asks if object is a valid float.
  def numeric?(object)
    true if Float(object) rescue false
  end

  # Asks if object is a valid integer.
  def integer?(object)
    if numeric?(object)
      object = object.to_f
      mod = object.modulo(1)
      if mod == 0
        true
      else
        false
      end
    else
      false
    end
  end


end
