=begin
                  Arachni
  Copyright (c) 2010-2012 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Plugins

#
# Logs content-types of all server responses.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.3
#
class ContentTypes < Arachni::Plugin::Base

    def prepare
        @results = {}
        @exclude = Regexp.new( @options['exclude'] )

        @logged = Set.new
    end

    def run
        @framework.http.add_on_complete {
            |res|

            next if @logged.include?( res.request.method.to_s.upcase + res.effective_url )
            next if !(type = res.headers_hash['Content-type'] ) || type.empty?

            type = type.join( ' - ' ) if type.is_a?( Array )

            if( !@options['exclude'].empty? && !type.match( @exclude ) ) ||
                @options['exclude'].empty?
                @results[type] ||= []
                @results[type] << {
                    :url    => res.effective_url,
                    :method => res.request.method.to_s.upcase,
                    :params => res.request.params
                }

                @logged << res.request.method.to_s.upcase + res.effective_url
            end
        }
    end

    def clean_up
        wait_while_framework_running
        register_results( @results )
    end

    def self.distributable?
        true
    end

    def self.merge( results )
        merged = {}
        results.each {
            |result|
            result.each {
                |type, val|
                merged[type] ||= []
                merged[type] |= val
            }
        }

        return merged
    end

    def self.info
        {
            :name           => 'Content-types',
            :description    => %q{Logs content-types of server responses.
                It can help you categorize and identify publicly available file-types
                which in turn can help you identify accidentally leaked files.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1.3',
            :options        => [
                Arachni::OptString.new( 'exclude', [ false,
                    'Exclude content-types that match this regular expression.', 'text' ]
                )
            ]
        }
    end

end

end
end
