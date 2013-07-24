#!/usr/bin/env sh
# Run bundle install in every directory with a Gemfile but no Gemfile.lock

for i in `find . -name "Gemfile"`
do
	if [[ ! -f ${i}.lock ]]
	then
		echo "****************" $i
		pushd ${i%Gemfile}
		bundle install
		popd
	fi
done
