require "spec_helper"
require "rake"
require "gemsmith/rake/tasks"

describe Gemsmith::Rake::Tasks do
  subject { described_class.new }
  before do
    Rake::Task.clear
    Rake::Task.define_task :build
    Rake::Task.define_task :release
    Rake::Task.define_task "release:guard_clean"
    Rake::Task.define_task "release:rubygem_push"
  end

  describe ".setup" do
    let(:tasks) { instance_spy described_class }
    before { allow(described_class).to receive(:new).and_return(tasks) }

    it "installs rake tasks" do
      described_class.setup
      expect(tasks).to have_received(:install)
    end
  end

  describe "#install" do
    before { subject.install }

    it "installs readme:toc task" do
      expect(Rake::Task.task_defined?("readme:toc")).to eq(true)
    end

    it "installs clean task" do
      expect(Rake::Task.task_defined?(:clean)).to eq(true)
    end

    it "installs publish task" do
      expect(Rake::Task.task_defined?(:publish)).to eq(true)
    end
  end

  describe "rake tasks" do
    let(:build) { instance_spy Gemsmith::Rake::Build }
    let(:release) { instance_spy Gemsmith::Rake::Release }
    before do
      allow(Gemsmith::Rake::Build).to receive(:new).and_return(build)
      allow(Gemsmith::Rake::Release).to receive(:new).and_return(release)
      subject.install
    end

    describe "rake readme:toc" do
      it "builds/updates README table of contents" do
        Rake::Task["readme:toc"].invoke
        expect(build).to have_received(:table_of_contents)
      end
    end

    describe "rake clean" do
      it "cleans gem package" do
        Rake::Task[:clean].invoke
        expect(build).to have_received(:clean!)
      end
    end

    describe "rake build" do
      it "invokes clean task prerequisite" do
        Rake::Task[:build].invoke
        expect(build).to have_received(:clean!)
      end

      it "invokes readme:toc task prerequisite" do
        Rake::Task[:build].invoke
        expect(build).to have_received(:table_of_contents)
      end
    end

    describe "rake release" do
      it "invokes clean task" do
        Rake::Task[:release].invoke
        expect(build).to have_received(:clean!)
      end
    end

    describe "rake publish" do
      it "has prerequisites" do
        expect(Rake::Task[:publish].prerequisites).to contain_exactly("clean", "build", "release:guard_clean")
      end

      it "tags release" do
        Rake::Task[:publish].invoke
        expect(release).to have_received(:tag)
      end

      it "pushes tags" do
        Rake::Task[:publish].invoke
        expect(release).to have_received(:push)
      end
    end
  end
end