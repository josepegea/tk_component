module TkComponent
  module Builder
    class GridMap
      def initialize
        @rows = []
        @row_weights = []
        @column_weights = []
      end

      def get(row, col)
        return nil if row >= @rows.size
        return nil if (cols = @rows[row]).nil? || col >= cols.size
        cols[col]
      end

      def set(row, col, val)
        @rows[row] = [] if row > @rows.size || @rows[row].nil?
        @rows[row][col] = val
      end

      def fill(row, col, rowspan, columnspan, val)
        for r in (row .. row + rowspan - 1) do
          for c in (col .. col + columnspan - 1) do
            set(r, c, val)
          end
        end
      end

      def row_weight(row)
        @row_weights[row] || 0
      end

      def column_weight(col)
        @column_weights[col] || 0
      end

      def set_weights(row, col, weights = {})
        hw = weights[:h_weight]
        @row_weights[row] = ((rw = @row_weights[row]).present? ? [rw, hw].max : hw) if hw
        vw = weights[:v_weight]
        @column_weights[col] = ((cw = @column_weights[col]).present? ? [cw, vw].max : vw) if vw
      end

      def row_indexes
        used_indexes(@rows)
      end

      def column_indexes
        @rows.reduce([]) { |accum, r| accum += used_indexes(r) }.uniq
      end

      def get_next_cell(current_row, current_col, going_down)
        if going_down
          while get(current_row, current_col) do current_row += 1 end
        else
          while get(current_row, current_col) do current_col += 1 end
        end
        [current_row, current_col]
      end

      def to_s
        @rows.to_s
      end

      private

      def used_indexes(array)
        return [] if array.nil?
        array.map.with_index { |o, i| o.present? ? i : nil }.compact
      end
    end
  end
end
