# -*- coding: iso-8859-1 -*-
namespace :migrate do
  desc 'Search all Projects from board and create new acl9 role for the users'
  task :extract_prs_project => :environment do
    person_roles = PersonRole.find(:all, :include => [:person, :project])
    person_roles.each do |person_role|
      person = person_role.person
      role = person_role.role
      project = person_role.project

      if role.nil? || person.nil? || project.nil?
        p person_role.id
      else
        p person.has_role! role.name.to_sym, project
      end
    end
  end

  task :extract_prs_contexts => :environment do
    contexts = Context.all
    contexts.each do |context|
      # Hier sind jetzt alle Person Roles für die Contexte
      # in vips there may be more: deleted: context.vips
      c_person_roles = context.context_person_roles
      person_roles = c_person_roles.map{|cpr| cpr.person_role}.flatten.uniq
      person_roles.each do |person_role|
        person = person_role.person
        p person.has_role? :owner, context
      end
    end
  end

  desc 'Check for all person _roles'
  task :validates_person_roles => :environment do
    person_roles = PersonRole.find(:all, :include => [:person, :project])
    person_roles.each do |person_role|
      person = person_role.person
      role = person_role.role
      project = person_role.project

      if role.nil? || person.nil? || project.nil?
        p "Attention please for Person Role with ID #{person_role.id}"
      else
      p person.has_role? role.name.to_sym, project
      end
    end
  end


end
