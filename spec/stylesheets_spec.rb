require 'spec_helper'

describe 'stylesheets' do
  let(:import_options) {
    {style: :compact, load_paths: [Apropos::STYLESHEETS_DIR], syntax: :scss}
  }
  let(:css_file) {
    Sass::Engine.new(@scss_file, import_options).render
  }

  def stub_files(*files)
    Dir.stub(:glob).with(Pathname.new("hero.*.jpg")).and_return(files)
  end

  it "can be imported" do
    @scss_file = %Q{
      @import "apropos";
      .foo {
        @include apropos-bg-variants('hero.jpg');
      }
    }
    css_file.strip.should == ".foo { background-image: url('/hero.jpg'); }"
  end

  describe "hidpi stylesheet" do
    it "generates default hidpi rules" do
      stub_files("./hero.2x.jpg")
      @scss_file = %Q{
        @import "apropos";
        .foo {
          @include apropos-bg-variants('hero.jpg');
        }
      }
      css_file.should include('(-webkit-min-device-pixel-ratio: 1.75), (min-resolution: 168dpi)')
      css_file.should include("'/hero.2x.jpg'")
    end

    it "allows customizing hidpi extension and query" do
      stub_files("./hero.hidpi.jpg")
      @scss_file = %Q{
        $apropos-hidpi-extension: 'hidpi';
        $apropos-hidpi-query: '(min-resolution: 300dpi)';
        @import "apropos";
        .foo {
          @include apropos-bg-variants('hero.jpg');
        }
      }
      css_file.should_not include('(-webkit-min-device-pixel-ratio: 1.75)')
      css_file.should include('(min-resolution: 300dpi)')
      css_file.should include("'/hero.hidpi.jpg'")
    end
  end

  describe "breakpoints stylesheet" do
    before :each do
      stub_files("./hero.medium.jpg", "./hero.large.jpg")
    end

    it "doesn't generate any defaults" do
      @scss_file = %Q{
        @import "apropos";
        .foo {
          @include apropos-bg-variants('hero.jpg');
        }
      }
      css_file.should_not include('/hero.medium.jpg')
      css_file.should_not include('/hero.large.jpg')
    end

    it "allows setting breakpoints" do
      stub_files("./hero.medium.jpg", "./hero.large.jpg")
      @scss_file = %Q{
        $apropos-breakpoints: (medium, 768px), (large, 1024px);
        @import "apropos";
        .foo {
          @include apropos-bg-variants('hero.jpg');
        }
      }
      css_file.should include("@media (min-width: 768px) { .foo { background-image: url('/hero.medium.jpg'); } }")
      css_file.should include("@media (min-width: 1024px) { .foo { background-image: url('/hero.large.jpg'); } }")
    end
  end

  describe "breakpoints and hidpi" do
    it "can be combined" do
      stub_files("./hero.large.2x.jpg", "./hero.medium.2x.jpg")
      @scss_file = %Q{
        $apropos-breakpoints: (medium, 768px), (large, 1024px);
        @import "apropos";
        .foo {
          @include apropos-bg-variants('hero.jpg');
        }
      }
      css_file.should include("@media (min-width: 768px) and (-webkit-min-device-pixel-ratio: 1.75), (min-width: 768px) and (min-resolution: 168dpi) { .foo { background-image: url('/hero.medium.2x.jpg'); } }")
      css_file.should include("@media (min-width: 1024px) and (-webkit-min-device-pixel-ratio: 1.75), (min-width: 1024px) and (min-resolution: 168dpi) { .foo { background-image: url('/hero.large.2x.jpg'); } }")
    end

    it "sorts breakpoints vs. retina correctly" do
      # filesystem sort order
      files = %w[2x large.2x large medium.2x medium].map {|f| "./hero.#{f}.jpg" }
      stub_files(*files)
      @scss_file = %Q{
        $apropos-breakpoints: (medium, 768px), (large, 1024px);
        @import "apropos";
        .foo {
          @include apropos-bg-variants('hero.jpg');
        }
      }
      images = css_file.scan(/hero.+jpg/)
      sorted_images = %w[2x medium medium.2x large large.2x].map {|f| "hero.#{f}.jpg" }
      images.should == ["hero.jpg"] + sorted_images
    end
  end
end
