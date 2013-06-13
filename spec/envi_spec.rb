require 'ostruct'

describe Envi do
  it 'has a version number' do
    expect(Envi::VERSION).to_not be_nil
  end

  context 'when the configuration file exists' do
    before do
      YAML.should_receive(:load_file).with('config/envars.yml').and_return({
        'production' => [
          { 'name' => 'FOO' },
          { 'name' => 'BAR', 'message' => 'Bar must be set' }
        ],
        'development' => [
          { 'name' => 'BAZ' },
        ]
      })
    end

    context "and all keys are set" do
      before do
        stub_const('ENV', 'FOO' => 'bla', 'BAR' => 'bla')
      end

      it 'reads configuration from YAML file and values from ENV' do
        Envi.init
        expect(Envi::FOO).to eql('bla')
      end

      it 'raises error for unrequired keys' do
        Envi.init
        expect { Envi::BAZ }.to raise_error(NameError)
      end
    end

    context "when keys are missing" do
      it 'raises when required keys are missing' do
        stub_const('ENV', {})
        expect { Envi.init }.to raise_error(NameError, 'Required environment variable FOO is undefined')
      end

      it 'uses description from config file as error message' do
        stub_const('ENV', 'FOO' => 'qux')
        expect { Envi.init }.to raise_error(NameError, 'Bar must be set')
      end
    end

    it 'defaults to RAILS_ENV for environment' do
      stub_const('ENV', 'BAZ' => 'bla', 'RAILS_ENV' => 'development')
      Envi.init
      expect(Envi::BAZ).to eql('bla')
      expect { Envi::FOO }.to raise_error(NameError)
    end

    it 'defaults to RACK_ENV for environment' do
      stub_const('ENV', 'BAZ' => 'bla', 'RACK_ENV' => 'development')
      Envi.init
      expect(Envi::BAZ).to eql('bla')
      expect { Envi::FOO }.to raise_error(NameError)
    end

    it 'raises when configured environment does not exist' do
      stub_const('ENV', 'RACK_ENV' => 'hoeaap')
      expect { Envi.init }.to raise_error(Envi::UnknownEnvironment)
    end

    it 'allows defining a custom environment' do
      stub_const('ENV', 'BAZ' => 'bla')
      Envi.init(environment: 'development')
      expect(Envi::BAZ).to eql('bla')
      expect { Envi::FOO }.to raise_error(NameError)
    end

    it 'can preload environment variables from a file' do
      stub_const('ENV', 'BAR' => 'bla')
      File.should_receive(:readlines).with('.env').and_return(["FOO=qux\n"])
      Envi.init parse: '.env'
      expect(ENV['FOO']).to eql('qux')
    end
  end

  context "when using an existing object to call setters on" do
    subject { OpenStruct.new }

    before do
      YAML.should_receive(:load_file).with('config/envars.yml').and_return({
        'production' => [{ 'name' => 'FOO' }]
      })
      stub_const('ENV', 'FOO' => 'bar')
      Envi.init(use: subject)
    end

    its(:foo) { should eql('bar') }
  end

  it 'allows loading a custom configuration file' do
    YAML.should_receive(:load_file).with('foobar.yml').and_return({})
    expect { Envi.init(config: 'foobar.yml') }.to raise_error(Envi::UnknownEnvironment)
  end

  context 'when the configuration file cannot be found' do
    it 'raises an error' do
      expect { Envi.init }.to raise_error(Envi::FileNotFound)
    end
  end
end
