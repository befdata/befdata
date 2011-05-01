class Xlsreader
  attr_accessor :filename
  def initialize(filename)
    @filename = filename
    load_workbook
  end

  def columnheader

    @columnheader  = Array(@book.worksheet(4).row(0)).compact
    @columnheader
  end

  private

  def load_workbook
    @book = Spreadsheet.open filename
    @book.io.close
  end
end
