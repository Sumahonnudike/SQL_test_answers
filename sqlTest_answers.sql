-- 1. Find out the airline company which has a greater number of flight movement.
		mysql> select  Carrier_code,  count(*) as noOfFlights
			-> from flight_Detail fd
			-> join carrier_Detail cd on fd.carrierdid = cd.Carrier_ID
			-> group by carrierdId
			-> order by noOfFlights desc limit 1;
		+--------------+-------------+
		| Carrier_code | noOfFlights |
		+--------------+-------------+
		| WN           |      214624 |
		+--------------+-------------+
		1 row in set (2.43 sec)
		
-- 2. Get the details of the first five flights that has high airtime.

	mysql> SELECT  distinct flightid,  Carrier_code, airtime FROM flight_Detail fd
		-> join carrier_Detail cd on fd.carrierdid = cd.Carrier_ID
		-> ORDER BY airtime DESC limit 5;
	+----------+--------------+---------+
	| flightid | Carrier_code | airtime |
	+----------+--------------+---------+
	|   362528 | CO           |     664 |
	|   556380 | CO           |     655 |
	|   556384 | CO           |     654 |
	|   556378 | CO           |     654 |
	|   556376 | CO           |     652 |
	+----------+--------------+---------+
	5 rows in set (6.57 sec)
		
-- 3. Compute the maximum difference between the scheduled and actual arrival and departure time for the flights and categorize it by the airline companies.

		mysql> select  carrier_code,
    ->         max(CASE
    ->          WHEN TIMESTAMPDIFF(MINUTE,arrivaltime,scheduledarrivaltime)*-1 > 1400
    ->           THEN (1440 - (TIMESTAMPDIFF(MINUTE,arrivaltime,scheduledarrivaltime)*-1) )
    -> ELSE TIMESTAMPDIFF(MINUTE,arrivaltime,scheduledarrivaltime)*-1
    -> END) AS max_diffarrival,
    ->         max(CASE
    ->          WHEN TIMESTAMPDIFF(MINUTE,departuretime,scheduleddeparturetime)*-1 > 1400
    ->           THEN (1440 - (TIMESTAMPDIFF(MINUTE,departuretime,scheduleddeparturetime)*-1) )
    -> ELSE TIMESTAMPDIFF(MINUTE,departuretime,scheduleddeparturetime)*-1
    -> END) AS max_diffdeparture
    ->         from flight_detail  fd
    ->         join carrier_Detail cd on fd.carrierdid = cd.Carrier_ID
    ->         group by carrierdid order by carrierdid ;
		+--------------+-----------------+-------------------+
		| carrier_code | max_diffarrival | max_diffdeparture |
		+--------------+-----------------+-------------------+
		| WN           |             507 |               516 |
		| XE           |             714 |               859 |
		| YV           |             606 |               607 |
		| OH           |             670 |               960 |
		| OO           |             763 |               996 |
		| UA           |             942 |               629 |
		| US           |             689 |               699 |
		| DL           |            1385 |               716 |
		| EV           |             823 |               965 |
		| F9           |             706 |               703 |
		| FL           |             674 |               655 |
		| HA           |             530 |               833 |
		| MQ           |             876 |               927 |
		| NW           |            1021 |               940 |
		| 9E           |             973 |              1021 |
		| AA           |            1124 |               864 |
		| AQ           |             338 |               336 |
		| AS           |             679 |               947 |
		| B6           |             631 |               846 |
		| CO           |            1001 |               891 |
		+--------------+-----------------+-------------------+
		20 rows in set (5.04 sec)
		Note : If we consider arrivaldelay column in the table, then the resultset will be little different as the 
		       arrival time sometimes not defined in the 24 hour clock
			   
	   mysql>  select  carrier_code,
    ->              max(arrivaldelay) AS max_diffarrival,
    ->              max(departuredelay) AS max_diffdeparture
    ->              from flight_detail  fd
    ->              join carrier_Detail cd on fd.carrierdid = cd.Carrier_ID
    ->             group by carrierdid order by carrierdid ;
		+--------------+-----------------+-------------------+
		| carrier_code | max_diffarrival | max_diffdeparture |
		+--------------+-----------------+-------------------+
		| WN           |             637 |               539 |
		| XE           |             838 |               859 |
		| YV           |             606 |               607 |
		| OH           |             955 |               960 |
		| OO           |             990 |               996 |
		| UA           |            1267 |              1268 |
		| US           |             876 |               886 |
		| DL           |             863 |               901 |
		| EV           |             940 |               965 |
		| F9           |             706 |               703 |
		| FL           |             917 |               939 |
		| HA           |             864 |               866 |
		| MQ           |            1707 |              1710 |
		| NW           |            2461 |              2467 |
		| 9E           |            1094 |              1105 |
		| AA           |            1525 |              1521 |
		| AQ           |             338 |               336 |
		| AS           |             948 |               947 |
		| B6           |             834 |               846 |
		| CO           |            1001 |              1011 |
		+--------------+-----------------+-------------------+
		20 rows in set (7.52 sec)
		
-- 4. 	Find the month in which the flight delays happened to be more.		
       
	mysql> WITH month_data
    -> AS
    -> (select flight_month as mon , count(*) noofdelays
    -> from flight_Detail
    -> where (  carrierdelay+weatherdelay+NASdelay+securitydelay) > 0
    -> group by flight_month order by noofdelays desc limit 1  )
    -> select  monthname(str_to_date(mon ,'%m')) as month, noofdelays
    -> from month_data;
	+-------+------------+
	| month | noofdelays |
	+-------+------------+
	| March |     110447 |
	+-------+------------+
	1 row in set (2.04 sec)
	
-- 5. 	Get the flight count for each state and identify the top 1.

	mysql> select state_code,  count(*) as numFlights
    ->      from flight_Detail fb
	->      join route_Detail rt on fb.routeid = rt.route_ID
    ->      join airport_detail ad on rt.origincode = ad.locationId
    ->      join state_Detail sd on ad.stateId = sd.stateId
    ->      group by sd.stateId
    ->      order by numFlights desc
    ->  limit 1;
	+------------+------------+
	| state_code | numFlights |
	+------------+------------+
	| TX         |     125315 |
	+------------+------------+
	1 row in set (3.05 sec)

-- 6a. A customer wants to book a flight under an emergency situation. Which airline would you suggest him to book.  Justify your answer
    
	mysql> with flightwithlessdelay
    -> as
    ->     (select
    ->       carrierdid, count(*) as fcnt
    ->     from flight_detail
    ->      where arrivaldelay <= 0 group by carrierdid)
    ->      select carrier_code from flightwithlessdelay
    ->      join carrier_Detail cd on carrierdid = cd.carrier_id limit 3;
	+--------------+
	| carrier_code |
	+--------------+
	| WN           |
	| XE           |
	| YV           |
	+--------------+
	3 rows in set (1.98 sec)

	
-- 6b. Which delay cause is affecting for delay in each month?

	mysql>    with month_data
    -> as
    -> ( select flight_month as mon ,
    ->      sum(carrierdelay) as totcarrierdelay,
    ->  sum(weatherdelay) as totweatherdelay,
    ->  sum(NASdelay) as totNASdelay,
    ->  sum(securitydelay) as totsecuritydelay
    -> from flight_Detail
    -> group by flight_month)
    -> select monthname(str_to_date(mon ,'%m')) as month, @max_val:= GREATEST(totcarrierdelay, totweatherdelay, totNASdelay,
    -> totsecuritydelay) AS highestdelay,
    -> CASE @max_val WHEN totcarrierdelay THEN 'Carrier Delay'
    ->  WHEN totweatherdelay THEN 'Weather Delay'
    ->  WHEN totNASdelay THEN 'NAS delay'
    ->  WHEN totsecuritydelay THEN 'Security Delay'
    -> END AS reason_for_highestdelay
    ->    from month_data;
	+----------+--------------+-------------------------+
	| month    | highestdelay | reason_for_highestdelay |
	+----------+--------------+-------------------------+
	| January  |      2337749 | Carrier Delay           |
	| February |      2382656 | Carrier Delay           |
	| March    |      2513682 | Carrier Delay           |
	| April    |      1919024 | Carrier Delay           |
	| May      |      1712409 | Carrier Delay           |
	| June     |      2074518 | Carrier Delay           |
	+----------+--------------+-------------------------+
	6 rows in set, 1 warning (2.61 sec)
	   
	   
-- 7a. Find the dates in each month on which the flight delays are more.

    mysql> select flight_month, flight_date, count(*) as delcnt
    ->     from flight_detail
    ->     where arrivaldelay > 0 or departuredelay > 0
    ->     group by flight_month, flight_date order by  flight_month, delcnt desc, flight_date;
	+--------------+-------------+--------+
	| flight_month | flight_date | delcnt |
	+--------------+-------------+--------+
	|            1 | 2008-01-02  |  10857 |
	|            1 | 2008-01-03  |   9225 |
	|            1 | 2008-01-01  |   8354 |
	|            1 | 2008-01-06  |   8179 |
	|            1 | 2008-01-21  |   7859 |
	|            1 | 2008-01-17  |   7454 |
	|            1 | 2008-01-31  |   7352 |
	|            1 | 2008-01-18  |   7323 |
	|            1 | 2008-01-04  |   7071 |
	|            1 | 2008-01-05  |   7005 |
	|            1 | 2008-01-27  |   7002 |
	...
	...
	...

-- 7b. Effect of distance between the airports for delay?
   
  mysql> select distinct  distance, sum(carrierdelay+weatherdelay+NASdelay+securitydelay) as totdelay
    ->    from flight_Detail
    ->    group by distance
    ->    order by totdelay desc;
	+----------+----------+
	| distance | totdelay |
	+----------+----------+
	|      733 |   185287 |
	|      264 |   132186 |
	|      337 |   129363 |
	|      599 |   123963 |
	|      719 |   119694 |
	|      528 |   117351 |
	...
	...
	 There is no dependency based on distance
	 
-- 8a. Calculate the percentage of flights that are delayed compared to flights that arrived on time.

	mysql> with flight_delayed as
    ->     ( select  count(flightid) as delaycount
    ->   from flight_detail
    ->   where arrivaldelay > 0 or departuredelay > 0),
    ->     flight_ontime as
    ->     (  select  count(*) as arrivalcount
    ->   from flight_detail
    ->   where arrivaldelay <=0 )
    ->     select Concat("Percentage flight delay  :  ", delaycount *100/ (select count(*) as totalcnt from flight_detail) )   as Percenatge from flight_delayed
    ->     union
    ->     select Concat("Percentage flight delay  :  ",arrivalcount *100/ (select count(*) as totalcnt from flight_detail) ) as Percentage from flight_ontime;
	+--------------------------------------+
	| Percenatge                           |
	+--------------------------------------+
	| Percentage flight delay  :  100.0000 |
	| Percentage flight delay  :  10.3324  |
	+--------------------------------------+
	2 rows in set (10.44 sec)

	
-- 8b. How accurate is the CRS estimation compared to actual time?

    mysql> with elapsedata
    ->     as
    ->     (select 1 as id, Actualelaspedtime, scheduledelapsedtime, (Actualelaspedtime-scheduledelapsedtime) as difft
    ->     from flight_Detail ),
    ->     accuracydata
    ->     as
    ->     (select 1 as id, count(*) as accuracy  from elapsedata where difft <= 0)
    ->      select accuracy, (accuracy * 100/ (select count(*) from flight_detail)) as "Percentage of Accuray"
    ->     from  accuracydata ;
	+----------+-----------------------+
	| accuracy | Percentage of Accuray |
	+----------+-----------------------+
	|   658550 |               62.8043 |
	+----------+-----------------------+
	1 row in set (5.25 sec)
    
-- 9a.	Identify the routes that has more delay time.


mysql> with routedetails
    ->       as
    ->      ( select routeid, count(*) as totroute
    ->       from flight_detail
    ->       where arrivaldelay > 0 or departuredelay >0
    ->       group by routeid  )
    ->      select ad1.airport_name, ad2.airport_name
    ->      from routedetails  fd
    ->          join route_Detail rd on fd.routeId = rd.route_id
    ->        join airport_detail ad1 on rd.origincode = ad1.locationid
    ->        join airport_detail ad2 on rd.destinationcode = ad2.locationid;
	+----------------------------------------------------------------------------------+----------------------------------------------------------------------------------+
	| airport_name                                                                     | airport_name                                                                     |
	+----------------------------------------------------------------------------------+----------------------------------------------------------------------------------+
	| McCarran International Airport                                                   | Albuquerque International Sunport                                                |
	| San Antonio International Airport                                                | Albuquerque International Sunport                                                |
	| George Bush Intercontinental Airport                                             | Albuquerque International Sunport                                                |
	| Cleveland Hopkins International Airport                                          | Lehigh Valley International Airport                                              |
	| Chicago O''Hare International Airport                                             | Lehigh Valley International Airport                                              |
	| Hartsfield-Jackson Atlanta International Airport                                 | Lehigh Valley International Airport                                              |
	| Cincinnati/Northern Kentucky International Airport                               | Lehigh Valley International Airport                                              |
	| San Francisco International Airport                                              | Arcata Airport                                                                   |
	| San Francisco International Airport                                              | Albuquerque International Sunport                                                |
	| Sacramento International Airport                                                 | Arcata Airport                                                                   |
	| Del Norte County AirportÃ?Â (Jack McNamara Field)                                | Arcata Airport                                                                   |
	| Washington Dulles International Airport                                          | Albuquerque International Sunport                                                |
	...
	....
	....

-- 9b. During which part of day delays are more?
	
	mysql> with arrivaldata
    -> as
    -> (select arrivaltime,
    -> count(*) as totdelay
    -> from flight_detail
    -> where carrierdelay > 0 or weatherdelay > 0 or NASdelay > 0 or securitydelay > 0 or Late_aircraft_delay > 0
    -> group by arrivaltime
    -> order by totdelay desc limit 1)
    -> select case
    -> when cast(replace(date_format(arrivaltime,'%H:%i'),":","") as unsigned) between 1200 and 1599 then "Afternoon"
    -> when cast(replace(date_format(arrivaltime,'%H:%i'),":","") as unsigned) between 1600 and 1999 then "Evening"
    -> when cast(replace(date_format(arrivaltime,'%H:%i'),":","") as unsigned) between 2000 and 2399 then "Night"
    -> when cast(replace(date_format(arrivaltime,'%H:%i'),":","") as unsigned) between 0 and 399 then "Mid Night"
    -> when cast(replace(date_format(arrivaltime,'%H:%i'),":","") as unsigned) between 400 and 799 then "Early Morning" 
    -> when cast(replace(date_format(arrivaltime,'%H:%i'),":","") as unsigned) between 800 and 1199 then "Morning"
    -> end as daytime, totdelay from arrivaldata;
	+---------+----------+
	| daytime | totdelay |
	+---------+----------+
	| Night   |     1140 |
	+---------+----------+
	1 row in set (1.88 sec)
	
-- 10a	Find out on which day of week the flight delays happen more.
	
	with weekday_Delays 
    as 
     (select dayweek,dayname(flight_date) as day_name, count(*) as totdelay 
      from flight_detail  
      where arrivaldelay > 0 or departuredelay >0 
      group by dayweek  order by totdelay desc limit 1) 
      select day_name from weekday_Delays; 
	  
	  mysql> with weekday_Delays
    ->     as
    ->      (select dayweek,dayname(flight_date) as day_name, count(*) as totdelay
    ->       from flight_detail
    ->       where arrivaldelay > 0 or departuredelay >0
    ->       group by dayweek  order by totdelay desc limit 1)
    ->       select day_name from weekday_Delays;
	+----------+
	| day_name |
	+----------+
	| Friday   |
	+----------+
	1 row in set (2.29 sec)
	 
-- 10b. Airtime vs distance 

     select distinct  distance, sum(airtime) as totairtime
    ->     from flight_Detail
    ->       group by distance
    ->     order by totairtime desc;
	+----------+------------+
	| distance | totairtime |
	+----------+------------+
	|     2475 |     747508 |
	|     1745 |     683579 |
	|     2586 |     666125 |
	|     1846 |     569204 |
	|      733 |     551997 |
	|     1024 |     543285 |
	|      861 |     519117 |
	|     1235 |     511410 |
	|      761 |     465602 |
	|     1946 |     451034 |
	....
	...
	....

-- 11a	Identify at which part of day flights arrive late.

	mysql> with arrivaldata
    -> as
    -> (select arrivaltime,
    -> count(*) as totdelay
    -> from flight_detail
    -> where carrierdelay > 0 or weatherdelay > 0 or NASdelay > 0 or securitydelay > 0 or Late_aircraft_delay > 0
    -> group by arrivaltime
    -> order by totdelay desc limit 1)
    -> select case
    -> when cast(replace(date_format(arrivaltime,'%H:%i'),":","") as unsigned) between 1200 and 1599 then "Afternoon"
    -> when cast(replace(date_format(arrivaltime,'%H:%i'),":","") as unsigned) between 1600 and 1999 then "Evening"
    -> when cast(replace(date_format(arrivaltime,'%H:%i'),":","") as unsigned) between 2000 and 2399 then "Night"
    -> when cast(replace(date_format(arrivaltime,'%H:%i'),":","") as unsigned) between 0 and 399 then "Mid Night"
    -> when cast(replace(date_format(arrivaltime,'%H:%i'),":","") as unsigned) between 400 and 799 then "Early Morning" 
    -> when cast(replace(date_format(arrivaltime,'%H:%i'),":","") as unsigned) between 800 and 1199 then "Morning"
    -> end as daytime, totdelay from arrivaldata;
	+---------+----------+
	| daytime | totdelay |
	+---------+----------+
	| Night   |     1140 |
	+---------+----------+
	1 row in set (1.88 sec)

-- 11b. The wait period between arrival and departure delay?


   #####
  

-- 12a. Compute the maximum, minimum and average TaxiIn and TaxiOut time.

	mysql> select
    ->       max(taxiin) as "Maximum Taxi-in",
    ->       max(taxiout) as "Maximum Taxi-out",
    ->   min(taxiin) as "Minimum Taxi-in",
    ->       min(taxiout) as "Minimum Taxi-out",
    ->   avg(taxiin) as "Average Taxi-in",
    ->       avg(taxiout) as "Average Taxi-out"
    -> from flight_detail;
	+-----------------+------------------+-----------------+------------------+-----------------+------------------+
	| Maximum Taxi-in | Maximum Taxi-out | Minimum Taxi-in | Minimum Taxi-out | Average Taxi-in | Average Taxi-out |
	+-----------------+------------------+-----------------+------------------+-----------------+------------------+
	|             207 |              383 |               0 |                0 |          6.6810 |          17.9985 |
	+-----------------+------------------+-----------------+------------------+-----------------+------------------+
	1 row in set (2.05 sec)

    
-- 12b.	Between which locations delay is more?

    mysql> select  ad1.airport_name,
    ->             ad2.airport_name, count(*) as delay
    ->     from flight_Detail fb
    ->     join route_Detail rt on fb.routeid = rt.route_ID
    ->     join airport_detail ad1 on rt.origincode = ad1.locationId
    ->     join airport_detail ad2  on rt.destinationcode = ad2.locationId
    ->     where carrierdelay > 0 or weatherdelay > 0 or NASdelay > 0 or securitydelay > 0 or Late_aircraft_delay > 0
    ->     group by routeid order by delay desc limit 10;
	+--------------------------------------------------+----------------------------------------------+-------+
	| airport_name                                     | airport_name                                 | delay |
	+--------------------------------------------------+----------------------------------------------+-------+
	| Chicago O''Hare International Airport             | LaGuardia Airport (Marine Air Terminal)      |  1920 |
	| Los Angeles International Airport                | San Francisco International Airport          |  1770 |
	| LaGuardia Airport (Marine Air Terminal)          | Chicago O''Hare International Airport         |  1615 |
	| San Francisco International Airport              | Los Angeles International Airport            |  1606 |
	| Hartsfield-Jackson Atlanta International Airport | LaGuardia Airport (Marine Air Terminal)      |  1419 |
	| McCarran International Airport                   | Los Angeles International Airport            |  1358 |
	| Chicago O''Hare International Airport             | Minneapolis-Saint Paul International Airport |  1301 |
	| William P. Hobby Airport                         | Dallas Love Field                            |  1276 |
	| Chicago O''Hare International Airport             | Newark Liberty International Airport         |  1253 |
	| Minneapolis-Saint Paul International Airport     | Chicago O''Hare International Airport         |  1201 |
	+--------------------------------------------------+----------------------------------------------+-------+
    10 rows in set (2.98 sec)
	
-- 13a	Get the details of origin and destination with maximum flight movement

	mysql> with routedetails
    ->       as
    ->       ( select routeid, count(*) as totroute
    ->       from flight_detail group by routeid order by totroute desc limit 1)
    ->          select ad1.iata_code as "Origin IATA code", ad1.airport_name "Origin aiportnme",
    ->     ad1.city as "Origin city",ad2.iata_code as "Destination IATA code", ad2.airport_name "Destination aiportnme",
    ->     ad2.city as "Destination city"
    ->       from routedetails  fd
    ->          join route_Detail rd on fd.routeId = rd.route_id
    ->        join airport_detail ad1 on rd.origincode = ad1.locationid
    ->        join airport_detail ad2 on rd.destinationcode = ad2.locationid  ;
	+------------------+-----------------------------------+-------------+-----------------------+-------------------------------------+------------------+
	| Origin IATA code | Origin aiportnme                  | Origin city | Destination IATA code | Destination aiportnme               | Destination city |
	+------------------+-----------------------------------+-------------+-----------------------+-------------------------------------+------------------+
	| LAX              | Los Angeles International Airport | Los Angeles | SFO                   | San Francisco International Airport | San Francisco    |
	+------------------+-----------------------------------+-------------+-----------------------+-------------------------------------+------------------+
	1 row in set (2.04 sec)
       
	
-- 13b.	Descriptive statics for Taxi in and Taxi Out time
 
    mysql> select 'Taxi-In' as descriptio, sum(taxiin) as 'No of cases',
    -> avg(taxiin) as mean , stddev(taxiin) as Standarddeviation from flight_Detail f1
    -> union
    -> select 'Taxi-Out' as descriptio, sum(taxiout) as 'No of cases',
    -> avg(taxiout) as mean , stddev(taxiout) as Standarddeviation from flight_Detail f2   ;
	+------------+-------------+---------+-------------------+
	| descriptio | No of cases | mean    | Standarddeviation |
	+------------+-------------+---------+-------------------+
	| Taxi-In    |     7005509 |  6.6810 |  4.94403891660251 |
	| Taxi-Out   |    18872786 | 17.9985 | 13.73946491799164 |
	+------------+-------------+---------+-------------------+
	2 rows in set (2.99 sec)
	
-- 14a.	Find out which delay cause occurrence is maximum.

	mysql> with delaycategories
    -> as
    -> (select sum(carrierdelay) "Carrier_delay", sum(weatherdelay) "Weather_delay", sum(NASdelay) "NAS_delay",
    -> sum(securitydelay) "Security_delay", sum(Late_aircraft_delay) "Late_aircraft_delay" from flight_detail)
    -> SELECT CASE greatest(Carrier_delay, Weather_delay, NAS_delay, Security_delay, Late_aircraft_delay)
    ->   WHEN Carrier_delay      THEN 'Carrier delay'
    ->   WHEN Weather_delay     THEN 'Weather delay'
    ->   WHEN NAS_delay    THEN 'NAS delay'
    ->   WHEN Security_delay      THEN 'Security delay'
    ->   WHEN Late_aircraft_delay  THEN 'Late aircraft delay'
    ->    END AS "Maximum Delay cause"
    -> FROM   delaycategories;
	+---------------------+
	| Maximum Delay cause |
	+---------------------+
	| Late aircraft delay |
	+---------------------+
	1 row in set (2.11 sec)
	
-- 14b.	Effect of holidays in flight movements and delays

	No holiday data available
	
-- 15a.	Get details of flight whose speed is between 400 to 600 miles/hr for each airline company.

	mysql> select
    ->    fd.flightid, carrier_code
    -> from  flight_detail fd
    ->  join  carrier_detail cd   on fd.carrierdId = cd.Carrier_ID
    -> where speed between 400 and  600;
	+----------+--------------+
	| flightid | carrier_code |
	+----------+--------------+
	|        1 | WN           |
	|        2 | WN           |
	
-- 15b.	Any particular flight that gets delayed most frequently?


  #####
  
-- 16a.	Identify the best time in a day to book a flight for a customer to reduce the delay.

	mysql> with arrivaldata     as   
	 ->(select arrivaltime,    count(*) as totdelay     from flight_detail   
	 -> where carrierdelay > 0 or weatherdelay > 0 or NASdelay > 0 or securitydelay > 0 or Late_aircraft_delay > 0   
	 -> group by arrivaltime     order by totdelay asc limit 1)    
	 -> select case     when cast(replace(date_format(arrivaltime,'%H:%i'),":","") as unsigned) between 1200 and 1599 then "Afternoon"  
	 -> when cast(replace(date_format(arrivaltime,'%H:%i'),":","") as unsigned) between 1600 and 1999 then "Evening"    
	 -> when cast(replace(date_format(arrivaltime,'%H:%i'),":","") as unsigned) between 2000 and 2399 then "Night"     
	 -> when cast(replace(date_format(arrivaltime,'%H:%i'),":","") as unsigned) between 0 and 399 then "Mid Night"    
	 -> when cast(replace(date_format(arrivaltime,'%H:%i'),":","") as unsigned) between 400 and 799 then "Early Morning"     
	 -> when cast(replace(date_format(arrivaltime,'%H:%i'),":","") as unsigned) between 800 and 1199 then "Morning"     
	 -> end as daytime, totdelay from arrivaldata;
	+---------------+----------+
	| daytime       | totdelay |
	+---------------+----------+
	| Early Morning |        1 |
	+---------------+----------+
	1 row in set (2.20 sec)


-- 16b.	Which flight has maximum airtime?

	mysql> select flightid from flight_Detail
    -> where airtime=(select max(airtime) from flight_Detail);
	+----------+
	| flightid |
	+----------+
	|   362528 |
	+----------+
	1 row in set (6.23 sec)
	
-- 17.	Get the route details with airline company code ‘AQ’

    select distinct ad1.iata_code, ad1.airport_name, ad1.city, 
         ad2.iata_code, ad2.airport_name, ad2.city 
    from flight_Detail fd 
    join carrier_Detail cd on fd.carrierdid = cd.carrier_id 
    join route_Detail rd on fd.routeid = rd.route_id 
    join airport_Detail ad1 on ad1.locationid = rd.origincode 
    join airport_Detail ad2 on ad2.locationid = rd.destinationcode 
	where carrier_Code ='AQ';mysql> select distinct ad1.iata_code, ad1.airport_name, ad1.city,
    ->          ad2.iata_code, ad2.airport_name, ad2.city
    ->     from flight_Detail fd
    ->     join carrier_Detail cd on fd.carrierdid = cd.carrier_id
    ->     join route_Detail rd on fd.routeid = rd.route_id
    ->     join airport_Detail ad1 on ad1.locationid = rd.origincode
    ->     join airport_Detail ad2 on ad2.locationid = rd.destinationcode
    -> where carrier_Code ='AQ';
	+-----------+------------------------------------------------------+-------------+-----------+------------------------------------------------------+-------------+
	| iata_code | airport_name                                         | city        | iata_code | airport_name                                         | city        |
	+-----------+------------------------------------------------------+-------------+-----------+------------------------------------------------------+-------------+
	| HNL       | Honolulu International Airport                       | Honolulu    | LIH       | Lihue Airport                                        | Lihue       |
	| OGG       | Kahului Airport                                      | Kahului     | KOA       | Kona International Airport at Keahole                | Kailua/Kona |
	| LAS       | McCarran International Airport                       | Las Vegas   | OAK       | Oakland International Airport                        | Oakland     |
	| OGG       | Kahului Airport                                      | Kahului     | OAK       | Oakland International Airport                        | Oakland     |
	| SAN       | San Diego International AirportÃ?Â (Lindbergh Field) | San Diego   | OGG       | Kahului Airport                                      | Kahului     |
	| OGG       | Kahului Airport                                      | Kahului     | SAN       | San Diego International AirportÃ?Â (Lindbergh Field) | San Diego   |
	| HNL       | Honolulu International Airport                       | Honolulu    | SNA       | John Wayne AirportÃ?Â (Orange County Airport)        | Santa Ana   |
	| SNA       | John Wayne AirportÃ?Â (Orange County Airport)        | Santa Ana   | RNO       | Reno/Tahoe International Airport                     | Reno        |
	| SNA       | John Wayne AirportÃ?Â (Orange County Airport)        | Santa Ana   | KOA       | Kona International Airport at Keahole                | Kailua/Kona |
	| SAN       | San Diego International AirportÃ?Â (Lindbergh Field) | San Diego   | KOA       | Kona International Airport at Keahole                | Kailua/Kona |
	| HNL       | Honolulu International Airport                       | Honolulu    | ITO       | Hilo International Airport                           | Hilo        |
	| SNA       | John Wayne AirportÃ?Â (Orange County Airport)        | Santa Ana   | SAN       | San Diego International AirportÃ?Â (Lindbergh Field) | San Diego   |
	| KOA       | Kona International Airport at Keahole                | Kailua/Kona | LIH       | Lihue Airport                                        | Lihue       |
	| SMF       | Sacramento International Airport                     | Sacramento  | OGG       | Kahului Airport                                      | Kahului     |
	| KOA       | Kona International Airport at Keahole                | Kailua/Kona | HNL       | Honolulu International Airport                       | Honolulu    |
	| LIH       | Lihue Airport                                        | Lihue       | HNL       | Honolulu International Airport                       | Honolulu    |
	| OGG       | Kahului Airport                                      | Kahului     | SNA       | John Wayne AirportÃ?Â (Orange County Airport)        | Santa Ana   |
	| HNL       | Honolulu International Airport                       | Honolulu    | OAK       | Oakland International Airport                        | Oakland     |
	| SNA       | John Wayne AirportÃ?Â (Orange County Airport)        | Santa Ana   | SMF       | Sacramento International Airport                     | Sacramento  |
	| RNO       | Reno/Tahoe International Airport                     | Reno        | SNA       | John Wayne AirportÃ?Â (Orange County Airport)        | Santa Ana   |
	| HNL       | Honolulu International Airport                       | Honolulu    | OGG       | Kahului Airport                                      | Kahului     |
	| LIH       | Lihue Airport                                        | Lihue       | SNA       | John Wayne AirportÃ?Â (Orange County Airport)        | Santa Ana   |
	| OAK       | Oakland International Airport                        | Oakland     | LAS       | McCarran International Airport                       | Las Vegas   |
	| LIH       | Lihue Airport                                        | Lihue       | OGG       | Kahului Airport                                      | Kahului     |
	| SMF       | Sacramento International Airport                     | Sacramento  | SNA       | John Wayne AirportÃ?Â (Orange County Airport)        | Santa Ana   |
	| OGG       | Kahului Airport                                      | Kahului     | LIH       | Lihue Airport                                        | Lihue       |
	| SNA       | John Wayne AirportÃ?Â (Orange County Airport)        | Santa Ana   | OGG       | Kahului Airport                                      | Kahului     |
	| OAK       | Oakland International Airport                        | Oakland     | OGG       | Kahului Airport                                      | Kahului     |
	| OGG       | Kahului Airport                                      | Kahului     | SMF       | Sacramento International Airport                     | Sacramento  |
	| LIH       | Lihue Airport                                        | Lihue       | SAN       | San Diego International AirportÃ?Â (Lindbergh Field) | San Diego   |
	| HNL       | Honolulu International Airport                       | Honolulu    | KOA       | Kona International Airport at Keahole                | Kailua/Kona |
	| OAK       | Oakland International Airport                        | Oakland     | KOA       | Kona International Airport at Keahole                | Kailua/Kona |
	| SAN       | San Diego International AirportÃ?Â (Lindbergh Field) | San Diego   | LIH       | Lihue Airport                                        | Lihue       |
	| SNA       | John Wayne AirportÃ?Â (Orange County Airport)        | Santa Ana   | LIH       | Lihue Airport                                        | Lihue       |
	| KOA       | Kona International Airport at Keahole                | Kailua/Kona | OGG       | Kahului Airport                                      | Kahului     |
	| SNA       | John Wayne AirportÃ?Â (Orange County Airport)        | Santa Ana   | HNL       | Honolulu International Airport                       | Honolulu    |
	| OGG       | Kahului Airport                                      | Kahului     | HNL       | Honolulu International Airport                       | Honolulu    |
	| KOA       | Kona International Airport at Keahole                | Kailua/Kona | SAN       | San Diego International AirportÃ?Â (Lindbergh Field) | San Diego   |
	| LIH       | Lihue Airport                                        | Lihue       | KOA       | Kona International Airport at Keahole                | Kailua/Kona |
	| OAK       | Oakland International Airport                        | Oakland     | HNL       | Honolulu International Airport                       | Honolulu    |
	| KOA       | Kona International Airport at Keahole                | Kailua/Kona | OAK       | Oakland International Airport                        | Oakland     |
	| ITO       | Hilo International Airport                           | Hilo        | HNL       | Honolulu International Airport                       | Honolulu    |
	| KOA       | Kona International Airport at Keahole                | Kailua/Kona | SNA       | John Wayne AirportÃ?Â (Orange County Airport)        | Santa Ana   |
	+-----------+------------------------------------------------------+-------------+-----------+------------------------------------------------------+-------------+
	43 rows in set (2.42 sec)

-- 18a.	Identify on which dates in a year flight movement is large.	

	mysql> with routedetails
    ->     as
    ->     ( select routeid, count(*) as totroute
    ->       from flight_detail group by routeid order by totroute desc limit 1)
    ->      select airport_name
    ->  from routedetails  fd
    ->      join route_Detail rd on fd.routeId = rd.route_id
    ->      join airport_detail ad on rd.origincode = ad.locationid ;
	+-----------------------------------+
	| airport_name                      |
	+-----------------------------------+
	| Los Angeles International Airport |
	+-----------------------------------+
	1 row in set (1.78 sec)
	
-- 18b. What is the maximum delay period and when was it, location and cause?

    mysql> select flightId, "Arrival delay", flight_date as "Date",  dayname(flight_date) as "Week day", airport_name,
    ->   city, arrivaldelay as delay,  carrierdelay, weatherdelay, NASdelay, securitydelay, Late_aircraft_delay
    ->   From flight_Detail fd
    ->   join route_Detail rd on fd.routeId = rd.route_id
    ->   join airport_detail ad on rd.origincode = ad.locationid
    ->   where (arrivaldelay) = ( select max(arrivaldelay) from flight_Detail )
    ->  union
    ->  select flightId, "Departure delay", flight_date as "Date",  dayname(flight_date) as "Week day", airport_name,
    ->   city, departuredelay as delay,  carrierdelay, weatherdelay, NASdelay, securitydelay, Late_aircraft_delay
    ->   From flight_Detail fd
    ->   join route_Detail rd on fd.routeId = rd.route_id
    ->   join airport_detail ad on rd.origincode = ad.locationid
    ->   where (departuredelay) = ( select max(departuredelay) from flight_Detail );
	+----------+-----------------+------------+----------+-----------------------------------------+-----------+-------+--------------+--------------+----------+---------------+---------------------+
	| flightId | Arrival delay   | Date       | Week day | airport_name                            | city      | delay | carrierdelay | weatherdelay | NASdelay | securitydelay | Late_aircraft_delay |
	+----------+-----------------+------------+----------+-----------------------------------------+-----------+-------+--------------+--------------+----------+---------------+---------------------+
	|   322515 | Arrival delay   | 2008-02-03 | Sunday   | Honolulu International Airport          | Honolulu  |  2461 |         1455 |            0 |        4 |             0 |                1002 |
	|   686013 | Departure delay | 2008-04-10 | Thursday | Charlotte Douglas International Airport | Charlotte |  2467 |         2436 |            0 |        0 |             0 |                  17 |
	+----------+-----------------+------------+----------+-----------------------------------------+-----------+-------+--------------+--------------+----------+---------------+---------------------+
	2 rows in set (8.23 sec)

-- 19a.	Find out which delay cause is occurring more for each airline company.	

	mysql> with delaycategories
    ->      as
    ->     (select carrierdid, sum(carrierdelay) "Carrier_delay", sum(weatherdelay) "Weather_delay", sum(NASdelay) "NAS_delay",
    ->     sum(securitydelay) "Security_delay", sum(Late_aircraft_delay) "Late_aircraft_delay" from flight_detail
    ->     group by carrierdid)
    ->     SELECT carrier_code,
    ->     CASE greatest(Carrier_delay, Weather_delay, NAS_delay, Security_delay, Late_aircraft_delay)
    ->      WHEN Carrier_delay      THEN 'Carrier delay'
    ->       WHEN Weather_delay     THEN 'Weather delay'
    ->        WHEN NAS_delay    THEN 'NAS delay'
    ->        WHEN Security_delay      THEN 'Security delay'
    ->        WHEN Late_aircraft_delay  THEN 'Late aircraft delay'
    ->         END AS "Maximum Delay cause"
    ->      FROM   delaycategories dc
    ->      join carrier_Detail cd on dc.carrierdid = cd.carrier_id;
	+--------------+---------------------+
	| carrier_code | Maximum Delay cause |
	+--------------+---------------------+
	| WN           | Late aircraft delay |
	| XE           | Late aircraft delay |
	| YV           | Carrier delay       |
	| OH           | Carrier delay       |
	| OO           | Late aircraft delay |
	| UA           | Late aircraft delay |
	| US           | Late aircraft delay |
	| DL           | Late aircraft delay |
	| EV           | Carrier delay       |
	| F9           | NAS delay           |
	| FL           | Late aircraft delay |
	| HA           | Carrier delay       |
	| MQ           | Late aircraft delay |
	| NW           | Carrier delay       |
	| 9E           | Late aircraft delay |
	| AA           | Late aircraft delay |
	| AQ           | Carrier delay       |
	| AS           | Late aircraft delay |
	| B6           | Late aircraft delay |
	| CO           | NAS delay           |
	+--------------+---------------------+
	20 rows in set (3.12 sec)

-- 19b. Which delay cause is more on average for each carrier?

	mysql> select routeid, avg(carrierdid) "Avg CarrierDelay" , avg(weatherdelay) "Avg. Weather delay"
    -> , avg(NASdelay) "Avg. NAS delay", avg(securitydelay) "Avg. Security delay",
    -> avg(Late_aircraft_delay) as "Avg Late aircraft Delay"
    -> from flight_detail group by routeid;
	+---------+------------------+--------------------+----------------+---------------------+-------------------------+
	| routeid | Avg CarrierDelay | Avg. Weather delay | Avg. NAS delay | Avg. Security delay | Avg Late aircraft Delay |
	+---------+------------------+--------------------+----------------+---------------------+-------------------------+
	|       1 |           3.9482 |             3.2669 |         6.3386 |              0.3108 |                 19.0797 |
	|       2 |           1.0000 |             1.7000 |         4.8429 |              0.1214 |                 12.4000 |
	|       3 |           1.0000 |             0.0000 |         2.3750 |              0.1250 |                 29.0227 |
	|       4 |           3.8571 |             0.5306 |        11.5051 |              0.1735 |                 19.8929 |
	|       5 |           8.1245 |             0.8008 |         6.9544 |              0.1701 |                 17.2199 |
	|       6 |           1.0000 |             4.7073 |        11.4817 |              0.1159 |                 12.5061 |
	|       7 |           3.0303 |             0.6162 |         4.6717 |              0.4040 |                  8.3889 |
	....
	....
	....

-- 20a. Write a query that represent your unique observation in the database.

   ####

-- 20. Which airport has maximum flight movement?

	mysql> with routedetails
    ->     as
    ->     ( select routeid, count(*) as totroute
    ->       from flight_detail group by routeid order by totroute desc limit 1)
    ->      select airport_name
    ->  from routedetails  fd
    ->      join route_Detail rd on fd.routeId = rd.route_id
    ->      join airport_detail ad on rd.origincode = ad.locationid ;
	+-----------------------------------+
	| airport_name                      |
	+-----------------------------------+
	| Los Angeles International Airport |
	+-----------------------------------+
	1 row in set (1.78 sec)