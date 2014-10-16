create temp view users as select user from osm_relations union select user from osm_nodes union select user from osm_ways group by user;
create temp view users_osm_nodes as select user,min(timestamp) mintime, max(timestamp) maxtime from osm_nodes where user in (select user from users) group by user;
create temp view users_osm_ways as select user,min(timestamp) mintime, max(timestamp) maxtime from osm_ways where user in (select user from users) group by user;
create temp view users_osm_relations as select user,min(timestamp) mintime, max(timestamp) maxtime from osm_relations where user in (select user from users) group by user;
create temp table timestamp_users as select * from users_osm_relations;
insert into timestamp_users select * from users_osm_nodes;
insert into timestamp_users select * from users_osm_ways;
create temp view activity as select distinct(user),min(mintime) as first,max(maxtime) as last from timestamp_users group by user;
create table activity_users as select user, (Round(JulianDay(max(last)))-(JulianDay(min(first)))) as days,max(last) as lastedit,min(first) as firstedit,Julianday(date('now'))-Julianday((max(last))) fromtoday from activity group by user;


