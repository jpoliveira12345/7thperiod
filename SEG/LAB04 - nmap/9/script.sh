sites=( "187.17.111.103" "201.48.198.80" "201.48.198.4" "201.48.198.5" "201.48.199.11" "201.48.199.14" "201.48.199.14")



for i in {0..5}
do
	nmap -oN ${sites[$i]} ${sites[$i]};
done

