#!/bin/bash
wget -c http://svn.openstreetmap.org/applications/utils/osm-extract/polygons/fast_complete_poly_filter.pl
chmod 755 fast_complete_poly_filter.pl
wget -c https://raw.githubusercontent.com/napo/poly2wkt/master/poly2wkt.py
chmod 755 poly2wkt.py

function calculate {
	f=$1
	n=`expr index "$f" 1-`
	n=`echo $n-1 | bc` 
	osm_name=${f:0:$n}
	db=`basename $osm_name .osm`.sqlite
	poly=`basename $f .osm.zip`.poly
	./poly2wkt.py -s -c $poly -o poly.sql
	utenti=`echo $osm_name`_utenti.csv
	today=`date +%Y-%m-%d`
	datasize=`ls -sk $f | awk '{ print $1 }'`
	unzip -o $f
	basename $f .osm.zip
	./fast_complete_poly_filter.pl `basename $f .zip` `basename $f .osm.zip`.poly $osm_name.osm
	spatialite_osm_raw -o $osm_name.osm -d $db
	spatialite $db < poly.sql
	spatialite $db < init.sql
	echo $db
	#spatialite -header -csv -silent $db < calculate.sql > $utenti
	#t=`cat $utenti  | wc -l`
	#tot_users=`echo $t-1 | bc`
	nusers=`spatialite $db "select count(*) from activity_users"`
	nusers30=`spatialite $db "select count(*) from activity_users where fromtoday <= 30;"`
	nusers90=`spatialite $db "select count(*) from activity_users where fromtoday <= 90;"`
	nusers180=`spatialite $db "select count(*) from activity_users where fromtoday <= 180;"`
	nusers360=`spatialite $db "select count(*) from activity_users where fromtoday <= 360;"`
	nnodes=`spatialite $db "select count(*) from osm_nodes;"`
	nways=`spatialite $db "select count(*) from osm_ways;"`
	nrelations=`spatialite $db "select count(*) from osm_relations;"`
	area=`spatialite $db "select round(area(transform(geom,23032))) from poly;"`
	tags_ways=`spatialite $db "select count(*) from osm_way_tags;"`
	tags_nodes=`spatialite $db "select count(*) from osm_node_tags;"`
	tags_rel=`spatialite $db "select count(*) from osm_relation_tags;"`
	oldestedit=`spatialite $db "select min(firstedit) from activity_users;"`
	lastedit=`spatialite $db "select max(lastedit) from activity_users;"`
	oldestedit=${oldestedit:0:10}
	lastedit=${lastedit:0:10}
	ntags=`echo $tags_ways + $tags_nodes | bc`
	ntags=`echo $ntags + $tags_rel | bc`
	
	echo "$osm_name,$datasize,$oldestedit,$lastedit,$nusers,$nusers30,$nusers90,$nusers180,$nusers360,$nnodes,$nways,$nrelations,$ntags,$area" >> stats.csv
	ls -sk $db | gawk '{print $1}' 
	rm $db
	rm -fr *.txt
	rm -fr *.osm
}
files=`cat data.csv`
echo "city,datasize,oldestedit,lastedit,tot_users,tot_users30,tot_users90,tot_users180,tot_users360,tot_nodes,tot_ways,tot_relations,tot_tags,area" > stats.csv
for f in $files
do
	wget -c http://osm-toolserver-italia.wmflabs.org/estratti/comuni/osm/$f
	fp=`basename $f .osm.zip`.poly
	wget -c http://osm-toolserver-italia.wmflabs.org/estratti/comuni/poly/$fp
	calculate $f
done
