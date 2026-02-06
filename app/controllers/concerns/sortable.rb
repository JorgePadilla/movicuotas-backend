# frozen_string_literal: true

module Sortable
  extend ActiveSupport::Concern

  private

  def set_sort_params(allowed_columns:, default_column:, default_direction: "desc")
    @sort_column = allowed_columns.include?(params[:sort]) ? params[:sort] : default_column
    @sort_direction = %w[asc desc].include?(params[:direction]) ? params[:direction] : default_direction
  end

  def sort_order_sql(column_mapping)
    sql_col = column_mapping[@sort_column] || column_mapping.values.first
    Arel.sql("#{sql_col} #{@sort_direction}")
  end
end
