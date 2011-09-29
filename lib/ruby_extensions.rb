class Float
  class RailsNumberHelpers
    extend ActionView::Helpers::NumberHelper
  end

  def formatted_with_limited_digits(decimal_places=nil, long_digits_limit = nil)
    number = self
    orig_decimal_places = decimal_places
    if !orig_decimal_places
      case
        when number.abs < 1
          decimal_places = 3
        when number.abs < 10
          decimal_places = 2
        when number.abs < 100
          decimal_places = 1
        else
          decimal_places = 0
      end
    end

    if !!long_digits_limit && (number != 0)
      digits = Math.log10(number.abs).to_i + 1
      digits_to_round = digits - long_digits_limit #round after the first N digits so that only first N digits matter in formatting
      if digits_to_round > 0
        scale = (10**digits_to_round)
        number = (number / scale).round * scale
      end
    end

    s = Float::RailsNumberHelpers.number_to_currency(number, :unit => '', :precision => decimal_places)
    s = (s =~ /\./) ? s.gsub(/0+$/, '').gsub(/\.$/, '') : s unless orig_decimal_places # remove trailing zeroes if any; remove trailing decimal point, if any
    s
  end

  def formatted(decimal_places=nil, long_digits_limit = nil)
    formatted_with_limited_digits(decimal_places, long_digits_limit)
  end
end

class Numeric
  def radians
    self * Math::PI / 180
  end

  def degrees
    self * 180 / Math::PI
  end
end

class String
  def format_if_numeric(long_digits_limit = nil)
    begin
      num = Float(self)
    rescue
      return self
    end
    return num.formatted(nil, long_digits_limit)
  end
end
