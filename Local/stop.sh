ps=$(ps aux | grep "skf\|nginx\|angular" | grep -v grep | awk {'print $2'})
con=$(echo $ps | awk 'NR==1{print $1}')
if [[ $con -ne 0 ]]; then
	kill $ps
   else
        exit 1
fi
