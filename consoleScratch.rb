# -*- coding: iso-8859-1 -*-

## looping through projects to get associated paperproposals and fill the
## paperproposals projects link table
projects = Project.all
projects.each do |project|
  project_paperproposal_roles = project.role_objects.select { |ro| ro.authorizable_type == "Paperproposal" }
  project_paperproposal_roles.each do |role|
    paperproposal = Paperproposal.find(role.authorizable_id)
    paperproposal.update_attributes(:authored_by_project => project)
  end
end


## looping through projects to get associated datasets and fill the
## datasets projects link table
projects = Project.all
projects.each do |project|
  project_dataset_roles = project.role_objects.select { |ro| ro.authorizable_type == "Dataset" }
  project_dataset_roles.each do |role|
    dataset = Dataset.find(role.authorizable_id)
    dp = DatasetProject.create(:project => project,
                               :dataset => dataset)
  end
end


* # manipulating provenance

c=Context.find(106)
dcs = c.measurements_methodsteps

dcs.each do |dc|
  p dc.columnheader
  p "-------------"
  dc.people.each do |pers|
    p (["- ", pers.id, ", ", pers.firstname, " ", pers.lastname].to_s)
  end
  p
end


"stemTagab"
"-------------"
dc = dcs.select{|dc| dc.columnheader=="stemTagab"}[0]

kn = Person.find(23)
kn.has_role!(:responsible, dc)

"stemTag"
"-------------"
"- 2, Martin Baruffol"
"- 23, Karin Nadrowski"
dc = dcs.select{|dc| dc.columnheader=="stemTag"}[0]
kn.has_no_role!(:responsible, dc)


"length"
"-------------"
dc = dcs.select{|dc| dc.columnheader=="length"}[0]
kn.has_role!(:responsible, dc)


## remove Martin from the data columns
mb = Person.find(2)

dcs.each do |dc|
  mb.has_no_role!(:responsible, dc)
end






* # Genera are full of manually added errors, since import was
 # interrupted


c=Context.find(106)
dcs = c.measurements_methodsteps
dc = dcs.select{|dc| dc.columnheader == "Family"}[0]
# in den cell comments steht zwar valid, aber die categories sind dann
# "automatically generated"
cat_comments = dc.measurements.
  collect{|cell| cell.categoricvalue.comment}.uniq

problem_cells = dc.measurements.select do |cell|
  cell.value.nil?
end

problem_entries = problem_cells.collect{|pc| pc.import_value}.uniq

portal_cats = dc.methodstep.datacell_categories

entry = problem_entries[0]
matches = portal_cats.select{|c| c.short == entry}

similar = Categoricvalue.fuzzy_find(entry)
similar.collect{|c| c.short}

unless matches.blank?
  cat = matches[0]
  same_cells = problem_cells.select{|pc| pc.import_value == entry}
  same_cells.each do |cell|
    cell.update_attributes(:value => cat, :comment => "portal match")
  end
else # accept entry
  cat = Categoricvalue.create(:short => entry,
                              :long => entry,
                              :description => entry,
                              :comment => "manually approved")
  portal_cats << cat
  same_cells = problem_cells.select{|pc| pc.import_value == entry}
  same_cells.each do |cell|
    cell.update_attributes(:value => cat, :comment => "portal match")
  end
else # change entry
  cat = Categoricvalue.create(:short => "Unknown",
                              :long => "Unknown",
                              :description => "Unknown",
                              :comment => "manually approved")
  portal_cats << cat
  same_cells = problem_cells.select{|pc| pc.import_value == entry}
  same_cells.each do |cell|
    cell.update_attributes(:value => cat, :comment => "portal match")
  end
end



* # handle Dates


c=Context.find(106)
dcs = c.measurements_methodsteps
dc = dcs.select{|dc| dc.columnheader == "Date"}[0]
cells = dc.measurements

problem_cells = []
cells.each do |cell|
  # date umwandeln
  entry = Date.strptime(cell.import_value, '%d.%m.%Y')
  entry = entry.to_s
  value = Datetimevalue.new(:date => entry)
  # Kategorien l�schen
  if value.date.nil?
    problem_cells << cell
    p "Problem with cell #{cell.id}"
  else
    value.save
    cat = cell.categoricvalue
    cell.update_attributes(:value => value,
                           :comment => "valid")
    # this must come after the update, otherwise the category is still
    # linked to the cell
    cat.destroy unless cat.blank?
  end
end



# string.each("separator") geht


* # exchange categories

c=Context.find(106)
dcs = c.measurements_methodsteps
ch = "Species"
dc = dcs.select{|dc| dc.columnheader == ch}[0]

cat_old_id = 15616
cat_new_id = 155

cells_reps = dc.measurements.select{|cell| cell.value_id==cat_old_id}

cells_reps.each do |cell|
  cell.update_attributes(:value_id => cat_new_id)
end


cat_del = Categoricvalue.find(cat_old_id)

cat_del.import_categories
cat_del.measurements
cat_del.destroy



* # gradually deleting the context

c = Context.find(105)
dcs = c.measurements_methodsteps

dcs.each do |dc|
  dc.measurements.each do |cell|
    p [dc.columnheader, cell.id].join(": ")
    cell.destroy
  end
  p dc.columnheader
  dc.reload
  dc.destroy
end





* # importing the tags


c = Context.find(106)
dcs = c.measurements_methodsteps

dcs.each do |dc|
  tags_new = dc.comment
  unless tags_new.blank?
    dc.update_attributes(:tag_list => dc.comment)
  end
end


dcs.each do |dc|
  dc.comment = dc.tag_list.join(", ")
  dc.save
end




* # checking data groups

(10..29).each do |i|
  p i
  p [dcs[i].columnheader, dcs[i].definition].join(": ")
  p dcs[i].methodstep.title
end


* # changing categories on the console



## validate all categories
cells = Measurement.find_all_by_measurements_methodstep_id(693)
ivs = cells.collect{|c| c.import_value}.uniq
context_title = MeasurementsMethodstep.find(693).context.title

# checking
ivs.each do |iv|
  same_entry_cells = cells.select{|c| c.import_value == iv}
  p same_entry_cells.length
  p iv
  cat = same_entry_cells[0].categoricvalue
  approved = cat.comment == "manually approved"
  unless approved
    p iv + ": " + cat.short
  end
end


# approving
ivs.each do |iv|
  same_entry_cells = cells.select{|c| c.import_value == iv}
  p same_entry_cells.length
  p iv
  cat = same_entry_cells[0].categoricvalue
  approved = cat.comment == "manually approved"
  unless approved
    long = cat.long + " sp5"
    description = cat.description + " sp5: " + context_title
    cat.update_attributes(:comment => "manually approved",
                          :long => long,
                          :description => description)
    same_entry_cells.each do |cell|
      old_cat = cell.categoricvalue
      cell.update_attributes(:comment => "valid",
                             :value => cat)
      old_cat.destroy
    end
  end
end



## replace the import_value in column r3 with their integers
cells = dcs[3].measurements

cells.each do |cell|
  entry = cell.import_value.to_i.to_s if integer?(cell.import_value)
  p entry
  cell.import_value = entry
  cell.save
end

## replace the categoric values in column r2
cells = dcs[3].measurements
vals = cells.collect{|c| c.value}.uniq

vals.each do |val|
  entry = val.short
  p entry
  entry = entry.to_i.to_s if integer?(entry)
  p entry
  val.short = entry
  val.long = entry
  val.description = entry
  val.save
end








* # acl 9 ; migrating person roles



      c_person_roles = context.context_person_roles
      person_roles = c_person_roles.map{|cpr| cpr.person_role}.flatten.uniq
      person_roles.each do |person_role|
        person = person_role.person
        p person.has_role! :owner, context
      end

## all data columns of a project, for each one the same thing
data_columns = context.measurements_methodsteps



* # postgres

cd /





* ## rdoc


cd app
rdoc

# This command generates documentation for all the Ruby and C source
# files in and below the current directory. These will be stored in a
# documentation tree starting in the subdirectory 'doc'.



* ## starting tests

** ## tagging, adding and deleting taggings


ct1 = Context.create(:title => "test1",
                    :abstract => "test1",
                    :filename => "test1")


ct1.tag_list = "test, context"
ct1.language_list = "English"

ct1.save


** ## deleting contexts

ct1 = Context.create(:title => "test1",
                    :abstract => "test1",
                    :filename => "test1")

dg1 = Methodstep.find(:first)
dh1 = MeasurementsMethodstep.create(:columnheader => "test1",
                                   :definition => "test definition test definition test definition ",
                                   :columnnr => 1,
                                   :methodstep => dg1,
                                   :context => ct1)


val1 = Categoricvalue.create(:short => "d1",
                             :long => "c1",
                             :description => "c1")
ob1 = Observation.create(:rownr => 2)
dc1 = Measurement.create(:observation => ob1,
                         :value => val1,
                         :measurements_methodstep => dh1)
ic1 = ImportCategory.create(:categoricvalue => val1,
                            :measurements_methodstep => dh1)


ct1id = ct1.id
dh1id = dh1.id
dc1id = dc1.id
ob1id = ob1.id
ic1id = ic1.id
val1id = val1.id


## second set


ct2 = Context.create(:title => "test2",
                    :abstract => "test2",
                    :filename => "test2")

# dg1 = Methodstep.find(:first)
dh2 = MeasurementsMethodstep.create(:columnheader => "test2",
                                   :definition => "test definition test definition test definition ",
                                   :columnnr => 1,
                                   :methodstep => dg1,
                                   :context => ct2)


# val1 = Categoricvalue.create(:short => "d1",
#                              :long => "c1",
#                              :description => "c1")
ob2 = Observation.create(:rownr => 2)
dc2 = Measurement.create(:observation => ob2,
                         :value => val1,
                         :measurements_methodstep => dh2)
ic2 = ImportCategory.create(:categoricvalue => val1,
                            :measurements_methodstep => dh2)


ct2id = ct2.id
dh2id = dh2.id
dc2id = dc2.id
ob2id = ob2.id
ic2id = ic2.id

reload!

ct1 = Context.find(ct1id)
dh1 = MeasurementsMethodstep.find(dh1id)
dc1 = Measurement.find(dc1id)
ob1 = Observation.find(ob1id)
ic1 = ImportCategory.find(ic1id)
val1 = Categoricvalue.find(val1id)

ct2 = Context.find(ct2id)
dh2 = MeasurementsMethodstep.find(dh2id)
dc2 = Measurement.find(dc2id)
ob2 = Observation.find(ob2id)
ic2 = ImportCategory.find(ic2id)

ct1.destroy

Context.find(ct1id)
MeasurementsMethodstep.find(dh1id)
Measurement.find(dc1id)
Observation.find(ob1id)
ImportCategory.find(ic1id)
Categoricvalue.find(val1id)


Context.find(ct2id)
MeasurementsMethodstep.find(dh2id)
Measurement.find(dc2id)
Observation.find(ob2id)
ImportCategory.find(ic2id)
Categoricvalue.find(val1id) # this is the reused one

ct2.destroy


Context.find(ct2id)
MeasurementsMethodstep.find(dh2id)
Measurement.find(dc2id)
Observation.find(ob2id)
ImportCategory.find(ic2id)
Categoricvalue.find(val1id) # this is the reused one




* ## importing data, Context 14, inflated


cd /opt/production
ruby script/console

## paste all the files from the methods sheet:

## data from file; returns: @methodsheet, @respPeopleSheet,
## @categorySheet, @rawdatasheet, @columnheadersRaw
tmp = 'xls/z2_dbhdistCentralinflatedNonlinear02.xls'
provide_metasheets(tmp)



## context
co_id = 14
co = Context.find(co_id)

## observations; returns @obs
find_observations_for_context(co)

## for context 14 these are 9561 observations, beginning with
## observation 263, ending with observation 9823

@obs = {}
nobs = 9561
(1..nobs).each do |n|
  n2 = 262 + n
  ob = Observation.find(n2)
  @obs[n] = ob
end

# saved to the wrong mm
# 62759  up to Measurement 62817
(62759..62817).each do |i|
  m = Measurement.find(i)
  m.measurements_methodstep = measmeth
  m.save
  mm = m.measurements_methodstep
  p mm
end

cslookup["10"] = Categoricvalue.find(566)
cslookup["7"] = Categoricvalue.find(565)
cslookup["2"] = Categoricvalue.find(564)
cslookup["6"] = Categoricvalue.find(563)
cslookup["3"] = Categoricvalue.find(562)
cslookup["5"] = Categoricvalue.find(561)
cslookup["4"] = Categoricvalue.find(560)

cslookup["bow"] = Categoricvalue.find(567)
cslookup["7+8"] = Categoricvalue.find(568)
cslookup["3 snag"] = Categoricvalue.find(569)

ct = Categoricvalue.new
ct.short = "3 snag"
ct.long = "snag 2"
ct.description = "probably the same as category 3 of Anjas schema: Snag,  top broken but still hanging onto the snag = 2"
ct.save





* ## download priviledges for free contexts

## download priviledges for contexts and projects; -c is for subversion
ruby script/generate scaffold context_freeproject project_id:integer context_id:integer comment:text -c

svn commit

svn update local

associations in context_freeproject model
context model
project model

svn commit from local

svn update on beta

## migration code

ruby script/generate migration add_category_trigram_table


## runs the given migration and upwards
rake db:migrate:up VERSION=20110222125147
ruby script/console

## make first project context for free download connection
ct = Context.find(6) # diversity
ps = Project.find(:all)
ps.each do |p|
 cfpr = ContextFreeproject.new
 cfpr.context=ct
 cfpr.project=p
 cfpr.save
end

ContextFreeproject.find(:all)

Person roles who are part of a project -> include into vops in /models/Contexts

ct= Context.find(6)
ct.vops.length
## is different form ct.vops.uniq.length, at the moment I do not know why



@current_user= Person.find(20)
context = Context.find(6)
contextFreeProject_pr = context.context_freeprojects.collect{|cfp| cfp.project.person_roles}.flatten.uniq
contextFreeProject_p = contextFreeProject_pr.collect{|pr| pr.person}.uniq
contextFreeProject_p.include?(@current_user)

@current_user.person_roles


Person who is vop and is included into a project contained into context_freeprojects, give all Measmeth to it in ---> /controller/context_controller.rb

Done



## Remove all those cpr, that were added for reasons of free download:

cid= 8
adjustContextPersonRoles(cid)

addBEFprojectsToContext(cid)
Context.find(cid).title
Context.find(cid).context_freeprojects.length



def adjustContextPersonRoles(cid)
  ct = Context.find(cid)
  ct.context_person_roles.each do |cpr|
    p cpr
    p cpr.person_role.person
    p "---------------"
    p "Delete this context peron role\? (y/n)"
    STDOUT.flush
    yesno = gets.chomp
    p yesno
    cpr.destroy if yesno == "y"
  end
  ct = Context.find(cid)
  ct.context_person_roles.each{|cpr| p cpr}
end


## add all projects but "none" to a context

def addBEFprojectsToContext(cid)
  ct = Context.find(cid)
  ps = Project.find(:all)
  ps = ps.select{|p| p.shortname!="none"}
  ps.each do |p|
    cfproject = ContextFreeproject.new
    cfproject.context = ct
    cfproject.project = p
    cfproject.save
    p "saved context free project" + cfproject.id.to_s
  end
end



* ## missing columnheader issues "We are sorry"

## missing columnheader
mmsprs = MeasmethsPersonrole.find(:all)
mmsprs[0].measurements_methodstep.id
mmsprs.select{|mmspr| mmspr if mmspr.measurements_methodstep_id.nil?}

mmsprs.each{|mmspr| p mmspr.measurements_methodstep_id}; 1



## missing submethod title
tmp = MeasurementsMethodstep.find(:all)
tmp.select{|sm| sm if sm.methodstep.nil?}
Methodstep.find_with_ferret("H2O")


## submethod without context
tmp = MeasurementsMethodstep.find(:all)
tmp.select{|sm| sm if sm.context.nil?}

MeasurementsMethodstep.find_all_by_columnheader("Monostem")

MeasurementsMethodstep.find(302)



## changed a context person role in the backend

## results in keeping the ContextPersonRole but deleting the link to a
## personrole

## NoMethodError (undefined method `person' for nil:NilClass):
##  app/controllers/contexts_controller.rb:222:in `show'
role = ContextPersonRole.find(:all, :conditions => "context_id = 24")

msl = Person.find_by_firstname("Michael")
mslrs = msl.person_roles
mslr = mslrs[0]

cpr = ContextPersonRole.new
cpr.context = Context.find(24)
cpr.person_role = mslr
cpr.save


