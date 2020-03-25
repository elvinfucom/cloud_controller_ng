require 'spec_helper'
require 'decorators/field_include_service_instance_space_organization_decorator'

module VCAP::CloudController
  RSpec.describe FieldIncludeServiceInstanceSpaceOrganizationDecorator do
    describe '.decorate' do
      let(:org1) { Organization.make }
      let(:org2) { Organization.make }

      let(:space1) { Space.make(organization: org1) }
      let(:space2) { Space.make(organization: org2) }

      let!(:service_instance_1) { ManagedServiceInstance.make(space: space1) }
      let!(:service_instance_2) { UserProvidedServiceInstance.make(space: space2) }

      context 'when spaces and relationship.organizations are requested' do
        let(:decorator) { described_class.new({'space': ['relationship.organization', 'guid'] })}

        it 'decorates the given hash with spaces and relationships to orgs from service instances' do
          undecorated_hash = { foo: 'bar', included: { monkeys: %w(zach greg) } }
          hash = decorator.decorate(undecorated_hash, [service_instance_1, service_instance_2])

          expect(hash).to match({
            foo: 'bar',
            included: {
              monkeys: %w(zach greg),
              spaces: [
                {
                  guid: space1.guid,
                  relationships: {
                    organization: {
                      data: {
                        guid: org1.guid
                      }
                    }
                  }
                },
                {
                  guid: space2.guid,
                  relationships: {
                    organization: {
                      data: {
                        guid: org2.guid
                      }
                    }
                  }
                }
              ]
            }
          })
        end

        context 'when instances share a space' do
          let!(:service_instance_3) { ManagedServiceInstance.make(space: space1) }

          it 'does not duplicate the space' do
            hash = decorator.decorate({}, [service_instance_1, service_instance_3])
            expect(hash[:included][:spaces]).to have(1).element
          end
        end

        # TODO: move this test to the other decorator
        # context 'when instances share an org' do
        #   let(:space3) { Space.make(organization: org1) }
        #   let!(:service_instance_3) { ManagedServiceInstance.make(space: space3) }
        #
        #   it 'does not duplicate the org' do
        #     hash = decorator.decorate({}, [service_instance_1, service_instance_3])
        #     expect(hash[:included][:organizations]).to have(1).element
        #   end
        # end
      end

      context 'when only spaces are requested' do
        it 'decorates the given hash with spaces guids' do
          decorator = described_class.new({'space': ['guid'] })
          undecorated_hash = { foo: 'bar', included: { monkeys: %w(zach greg) } }
          hash = decorator.decorate(undecorated_hash, [service_instance_1, service_instance_2])

          expect(hash).to match({
            foo: 'bar',
            included: {
              monkeys: %w(zach greg),
              spaces: [
                {
                  guid: space1.guid,
                },
                {
                  guid: space2.guid,
                }
              ]
            }
          })
        end

        it 'decorates the given hash with relationships to orgs' do
          decorator = described_class.new({'space': ['relationship.organization'] })
          undecorated_hash = { foo: 'bar', included: { monkeys: %w(zach greg) } }
          hash = decorator.decorate(undecorated_hash, [service_instance_1, service_instance_2])

          expect(hash).to match({
            foo: 'bar',
            included: {
              monkeys: %w(zach greg),
              spaces: [
                {
                  relationships: {
                    organization: {
                      data: {
                        guid: org1.guid
                      }
                    }
                  }
                },
                {
                  relationships: {
                    organization: {
                      data: {
                        guid: org2.guid
                      }
                    }
                  }
                }
              ]
            }
          })
        end

        it 'decorates the given hash with spaces guids and relationships to orgs' do
          decorator = described_class.new({'space': ['guid', 'relationship.organization'] })
          undecorated_hash = { foo: 'bar', included: { monkeys: %w(zach greg) } }
          hash = decorator.decorate(undecorated_hash, [service_instance_1, service_instance_2])

          expect(hash).to match({
            foo: 'bar',
            included: {
              monkeys: %w(zach greg),
              spaces: [
                {
                  guid: space1.guid,
                  relationships: {
                    organization: {
                      data: {
                        guid: org1.guid
                      }
                    }
                  }
                },
                {
                  guid: space2.guid,
                  relationships: {
                    organization: {
                      data: {
                        guid: org2.guid
                      }
                    }
                  }
                }
              ]
            }
          })
        end

      end

      # context 'when only orgs are requested' do
      #   it 'decorates the given hash with organization guids and names' do
      #     decorator = described_class.new({'space.organization': ['guid,name'] })
      #     undecorated_hash = { foo: 'bar', included: { monkeys: %w(zach greg) } }
      #     hash = decorator.decorate(undecorated_hash, [service_instance_1, service_instance_2])
      #
      #     expect(hash).to match({
      #       foo: 'bar',
      #       included: {
      #         monkeys: %w(zach greg),
      #         organizations: [
      #           {
      #             name: org1.name,
      #             guid: org1.guid
      #           },
      #           {
      #             name: org2.name,
      #             guid: org2.guid
      #           }
      #         ]
      #       }
      #     })
      #   end
      #
      #   it 'decorates the given hash with organization names' do
      #     decorator = described_class.new({'space.organization': ['name'] })
      #     undecorated_hash = { foo: 'bar', included: { monkeys: %w(zach greg) } }
      #     hash = decorator.decorate(undecorated_hash, [service_instance_1, service_instance_2])
      #
      #     expect(hash).to match({
      #       foo: 'bar',
      #       included: {
      #         monkeys: %w(zach greg),
      #         organizations: [
      #           {
      #             name: org1.name
      #           },
      #           {
      #             name: org2.name
      #           }
      #         ]
      #       }
      #     })
      #   end
      #
      # end


    end

    describe '.match?' do
      it 'matches hashes containing key symbol `space` and value `guid`' do
        expect(described_class.match?({ 'space': ['guid'], other: ['bar'] })).to be_truthy
      end

      it 'matches hashes containing key symbol `space` and value `relationship.organization`' do
        expect(described_class.match?({ 'space': ['relationship.organization'], other: ['bar'] })).to be_truthy
      end

      it 'does not match other values' do
        expect(described_class.match?({ other: ['bar'] })).to be_falsey
      end

      it 'does not match non-hashes' do
        expect(described_class.match?('foo')).to be_falsey
      end
    end
  end
end
