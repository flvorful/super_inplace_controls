# Install hook code here
puts "Copying Files."

['public/javascripts/calendar_date_select', 'public/stylesheets/calendar_date_select', 'public/images/calendar_date_select'].each{|dir|
  dest = File.join(RAILS_ROOT, dir)
  src_dir = File.dirname(__FILE__) + "/" + dir
  FileUtils.mkdir_p(dest)
  FileUtils.cp_r(Dir.glob(src_dir + '/*.*'), dest)
  print "."
} 
FileUtils.cp File.join(File.dirname(__FILE__), "public/stylesheets/in_place_styles.css"), "#{RAILS_ROOT}/public/stylesheets/" unless File.exists?("#{RAILS_ROOT}/public/stylesheets/in_place_styles.css")
print "."
FileUtils.cp File.join(File.dirname(__FILE__), "public/images/spinner.gif"), "#{RAILS_ROOT}/public/images/spinner.gif" unless File.exists?("#{RAILS_ROOT}/public/images/spinner.gif")
print "."
puts "\nFiles copied. Installation Complete"