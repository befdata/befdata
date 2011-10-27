## The constants in the Sheetcellstatus class indicate the status of the Sheetcell data value.
##
## UNPROCESSED is the default status of a newly instantiated Sheetcell.
## SHEET_MATCH indicates category type Datatypes that have been matched with an ImportCategory during the validation process.
## PORTAL_MATCH indicates category type Datatypes that have been matched with an existing Category within the portal.
## VALID indicates year, text, number and date Datatypes that have have been validated during the validation process.
## INVALID indicates Sheetcell values that could not be validated.
class Sheetcellstatus
  UNPROCESSED = 1
  SHEET_MATCH = 2
  PORTAL_MATCH = 3
  VALID = 4
  INVALID = 5
end