module AdminBaseHelper
  def display_name(item)
    de = {}
    de["projects"] = "Projects"
    de["pages"] = "Pages"
    de["people"] = "People"
    de["roles"] = "Roledefinitions"
    de["person_roles"] = "People's Roles"
    de["institutions"] = "Institutions"
    de["person_addresses"] = "People's Addresses"
    de["observations_measurements"] = "observations_measurements"
    de["categoricvalues"] = "categoricvalues"
    de["datetimevalues"] = "datetimevalues"
    de["textvalues"] = "textvalues"
    de["numericvalues"] = "numericvalues"
    de["measurements"] = "measurements"
    de["measmeths_personroles"] = "measmeths_personroles"
    de["measurements_methodsteps"] = "Submethods"
    de["methodsteps"] = "methodsteps"
    de["methods"] = "Methods"
    de["regioncoords"] = "regioncoords"
    de["locations"] = "locations"
    de["observations"] = "observations"
    de["context_person_roles"] = "context_person_roles"
    de["contexts"] = "Contexts"
    de[item] || item
  end
end