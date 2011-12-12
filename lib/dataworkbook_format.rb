module DataworkbookFormat
  WBF = {
    # Version of File Format - Change when making changes here
    :wb_format_version => "on the way to 0.1.1",

    # Spreadsheet export formats
    :unapproved_format => Spreadsheet::Format.new(:size => 11, :horizontal_align => :left, :color => 'orange'),

    # Sheet numbers
    :metadata_sheet => 0,
    :people_sheet   => 1,
    :columns_sheet  => 2,
    :category_sheet => 3,
    :data_sheet     => 4,

    # Metadata sheet
    :meta_version_pos      => [0,2],
    :meta_title_pos        => [3,0],
    :meta_abstract_pos     => [6,0],
    :meta_comment_pos      => [9,0],
    :meta_projects_pos     => [11,1],
    :meta_owners_start_col => 1,
    :meta_owners_start_row => 14,

    :meta_usagerights_pos     => [22,0],
    :meta_published_pos       => [24,0],
    :meta_spatial_extent_pos  => [28,0],
    :meta_datemin_pos         => [32,0],
    :meta_datemax_pos         => [34,0],
    :meta_temporalextent_pos  => [36,0],
    :meta_taxonomicextent_pos => [39,0],
    :meta_design_pos          => [42,0],
    :meta_dataanalysis_pos    => [45,0],
    :meta_circumstances_pos   => [48,0],

    # Columns sheet
    :column_header_col           => 0,
    :column_definition_col       => 1,
    :group_methodvaluetype_col   => 2,
    :column_unit_col             => 3,
    :group_instrumentation_col   => 4,
    :group_informationsource_col => 5,
    :column_keywords_col         => 6,
    :group_title_col             => 7,
    :group_description_col       => 8,

    :column_comment_col          => 9, # not used, how much has this to do with keywords

    # People sheet
    :people_columnheader_col  => 0,
    :people_firstname_col     => 1,
    :people_lastname_col      => 2,
    :people_projects_col      => 3,
    :people_roles_col         => 4,

    # Category sheet
    :category_columnheader_col => 0,
    :category_short_col        => 1,
    :category_long_col         => 2,
    :category_description_col  => 3
  }
end