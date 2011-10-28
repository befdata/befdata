## The constants within Categorystatus class flag how the Category was created.
##
## CATEGORY_SHEET indicates a Category added from the the ImportCategory class during the validation process.
## MANUALLY_APPROVED indicates a Category added when an invalid "Sheetcell" value is manually approved.
class Categorystatus
  CATEGORY_SHEET = 1
  MANUALLY_APPROVED = 2
end