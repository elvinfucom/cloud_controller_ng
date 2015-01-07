require 'spec_helper'

module VCAP::Services
  module ServiceBrokers
    module V2
      module Errors
        describe ServiceBrokerApiUnreachable do
          let(:uri) { 'http://www.example.com/' }
          let(:error) { SocketError.new('some message') }

          before do
            error.set_backtrace(['/socketerror:1', '/backtrace:2'])
          end

          it 'generates the correct hash' do
            exception = ServiceBrokerApiUnreachable.new(uri, 'PUT', error)
            exception.set_backtrace(['/generatedexception:3', '/backtrace:4'])

            expect(exception.to_h).to eq({
              'description' => 'The service broker API could not be reached: http://www.example.com/',
              'backtrace' => ['/generatedexception:3', '/backtrace:4'],
              'http' => {
                'uri' => uri,
                'method' => 'PUT'
              },
              'source' => {
                'description' => error.message,
                'backtrace' => ['/socketerror:1', '/backtrace:2']
              }
            })
          end
        end
      end
    end
  end
end
