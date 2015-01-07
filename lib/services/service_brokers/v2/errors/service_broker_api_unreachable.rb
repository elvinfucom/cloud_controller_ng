require 'net/http'

module VCAP::Services
  module ServiceBrokers
    module V2
      module Errors
        class ServiceBrokerApiUnreachable < HttpRequestError
          def initialize(uri, method, source)
            super(
              "The service broker API could not be reached: #{uri}",
              uri,
              method,
              source
            )
          end
        end
      end
    end
  end
end
