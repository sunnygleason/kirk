run lambda { |env|
  str = ""
  ENV.each do |k, v|
    str << "#{k} #{v}\n"
  end
  [ 200, { 'Content-Type' => 'text/plain' }, [str] ]
}
