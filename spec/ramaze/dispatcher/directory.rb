#          Copyright (c) 2009 Michael Fellinger m.fellinger@gmail.com
# All files in this distribution are subject to the terms of the MIT license.

require File.expand_path('../../../../spec/helper', __FILE__)

spec_require 'nokogiri'

Ramaze.middleware(:spec) do
  run Rack::ETag.new(
    Rack::ConditionalGet.new(Rack::Directory.new(__DIR__('public'))),
    'public'
  )
end

describe 'Directory listing' do
  behaves_like :rack_test

  @hierarchy = %w[
    /test/deep/hierarchy/one.txt
    /test/deep/hierarchy/two.txt
    /test/deep/three.txt
    /test/deep/four.txt
    /test/five.txt
    /test/six.txt
  ]

  @hierarchy.each do |path|
    FileUtils.mkdir_p(__DIR__(:public, File.dirname(path)))
    FileUtils.touch(__DIR__(:public, path))
  end

  Ramaze.map('/', lambda{|env| [404, {}, ['not found']]})
  Ramaze.recompile_middleware(:spec)

  def build_listing(path)
    get('path').body
  end

  def check(url, title, list)
    got = get(url)

    got.status.should          == 200
    got['Content-Type'].should == 'text/html; charset=utf-8'

    doc = Nokogiri::HTML(got.body)

    doc.at(:title).inner_text.should == title

    urls = doc.css('td.name a').map do |a|
      ["/#{a[:href]}".squeeze('/'), a.inner_text]
    end

    urls.should == list
  end

  should 'dry serve root directory' do
    files = [
      ["/../", "Parent Directory"],
      ["/favicon.ico", "favicon.ico"],
      ["/file+name.txt", "file name.txt"],
      ["/test/", "test/"],
      ["/test_download.css", "test_download.css"]
    ]

    check '/', '/', files
  end

  should 'serve hierarchies' do
    files = [
      ["/../", "Parent Directory"],
      ["/test/deep/", "deep/"],
      ["/test/five.txt", "five.txt"],
      ["/test/six.txt", "six.txt"]
    ]

    check '/test', '/test', files
  end

  FileUtils.rm_rf(__DIR__('public/test'))
end
