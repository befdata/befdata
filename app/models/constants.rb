module Constants

  class Categorystatus

    CATEGORY_SHEET = 1
    MANUALLY_APPROVED = 2

    def initialize

    end
    def Category_Sheet
      return CATEGORY_SHEET
    end

    def Manually_Approved
      return MANUALLY_APPROVED
    end
  end

  class Sheetcellstatus
    VALID = 1
    INVALID = 2
    PORTALMATCH = 3
    SHEETMATCH = 4
  end

end