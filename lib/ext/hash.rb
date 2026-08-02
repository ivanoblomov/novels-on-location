# frozen_string_literal: true

class Hash
  def to_params
    params = ''.dup
    stack = []

    each do |k, v|
      next if v.blank?

      if v.is_a?(Hash)
        stack << [k, v]
      elsif v.is_a?(Array)
        v.each { |_val| stack << ["#{k}[]", v] }
      else
        params << "#{k}=#{v}&"
      end
    end

    stack.each do |parent, hash|
      hash.each do |k, v|
        next if v.blank?

        if v.is_a?(Hash)
          stack << ["#{parent}[#{k}]", v]
        else
          params << "#{parent}[#{k}]=#{v}&"
        end
      end
    end

    params.chop!
    params
  end
end
