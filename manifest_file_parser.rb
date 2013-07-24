# Manifest File Parser
#
# Figure out what packages are being used based on the jobs in a manifest file.

require 'yaml'

cf_release_dir = "/Users/killian/development/cloudfoundry/cf-release"
bosh_release_dir = "/Users/killian/development/cloudfoundry/bosh/release"

def get_packages_from_manifest(manifest, release_dir)

  jobs = manifest["jobs"].map{|job| job["template"]}.flatten.uniq unless manifest["jobs"].nil?

  packages = []
  jobs.each do |job|
    begin
      job_info = YAML.load_file(File.join(release_dir, "jobs", job, "spec"))
      job_info["packages"].each do |pkg|
        pkg_info = YAML.load_file(File.join(release_dir, "packages", pkg, "spec"))
        packages += pkg_info["files"]
      end
    rescue Exception => e
      puts "Problem finding packages for job #{job} in release directory #{release_dir}"
    end
  end
  packages.uniq!
end


micro_bosh_manifest = YAML.load_file('micro_bosh.yml')
bosh_manifest = YAML.load_file('bosh.yml')
cf_manifest = YAML.load_file('cf.yml')

bosh_packages = get_packages_from_manifest(bosh_manifest, bosh_release_dir)
cf_packages = get_packages_from_manifest(cf_manifest, cf_release_dir)

puts "*"*80
puts "BOSH Packages"
bosh_packages.each do |pkg|
  puts pkg
end

puts "*"*80
puts "CF Packages"
cf_packages.each do |pkg|
  puts pkg
end


