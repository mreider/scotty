#!/usr/bin/env ruby
#
# See http://semver.org/ for details
#
# Based on https://github.com/isaacs/node-semver/blob/master/semver.js
#

module Scotty; end
module Scotty::NodeVer

  NODE_VER = /(~>?)?((?:<|>)=?)?\s*[v=]*(\d+|x|X|\*)(?:\.(\d+|x|X|\*)(?:\.(\d+|x|X|\*)(?:\.(\d+|x|X|\*))?)?)?([a-zA-Z-][a-zA-Z0-9-\.:]*)?/
  #            ^spermy  ^gtlt       ^v   ^major           ^minor           ^patch           ^build            ^tag

  def self.parse(exp)
    return nil unless exp =~ NODE_VER

    # get match parts
    spm, gtlt, mm, m, p, b, t = $1, $2, $3, $4, $5, $6, $7

    # check for range
    rng = $~.post_match.strip
    if rng =~ NODE_VER
      # ignore
    end

    # replace x-s with zeros
    mm = is_wildcard?(mm) ? 0 : mm.to_i
    m = is_wildcard?(m) ? 0 : m.to_i
    p = is_wildcard?(p) ? 0 : p.to_i

    # check (<|>)=?
    case gtlt
      when '<'
        if p > 0
          p -= 1
        elsif m > 0
          m -= 1
        elsif mm > 0
          mm -= 1
        else
          # < 0.0.0 isn't valid; ignore
        end
      when '<=', '>=' then # ignore
      when '>' then p += 1
    end

    # return three-part version
    "#{mm}.#{m}.#{p}"
  end

  module_function

  # true if the expression is empty or one of the
  # wildcard characters
  def is_wildcard?(exp)
    exp.nil? || exp.downcase == 'x' || exp == '*'
  end

end

