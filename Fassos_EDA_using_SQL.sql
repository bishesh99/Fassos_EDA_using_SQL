drop table if exists driver;
CREATE TABLE driver(driver_id integer,reg_date date); 

INSERT INTO driver(driver_id,reg_date) 
 VALUES (1,'01-01-2021'),
(2,'01-03-2021'),
(3,'01-08-2021'),
(4,'01-15-2021');


drop table if exists ingredients;
CREATE TABLE ingredients(ingredients_id integer,ingredients_name varchar(60)); 

INSERT INTO ingredients(ingredients_id ,ingredients_name) 
 VALUES (1,'BBQ Chicken'),
(2,'Chilli Sauce'),
(3,'Chicken'),
(4,'Cheese'),
(5,'Kebab'),
(6,'Mushrooms'),
(7,'Onions'),
(8,'Egg'),
(9,'Peppers'),
(10,'schezwan sauce'),
(11,'Tomatoes'),
(12,'Tomato Sauce');

drop table if exists rolls;
CREATE TABLE rolls(roll_id integer,roll_name varchar(30)); 

INSERT INTO rolls(roll_id ,roll_name) 
 VALUES (1	,'Non Veg Roll'),
(2	,'Veg Roll');

drop table if exists rolls_recipes;
CREATE TABLE rolls_recipes(roll_id integer,ingredients varchar(24)); 

INSERT INTO rolls_recipes(roll_id ,ingredients) 
 VALUES (1,'1,2,3,4,5,6,8,10'),
(2,'4,6,7,9,11,12');

drop table if exists driver_order;
CREATE TABLE driver_order(order_id integer,driver_id integer,pickup_time datetime,distance VARCHAR(7),duration VARCHAR(10),cancellation VARCHAR(23));
INSERT INTO driver_order(order_id,driver_id,pickup_time,distance,duration,cancellation) 
 VALUES(1,1,'01-01-2021 18:15:34','20km','32 minutes',''),
(2,1,'01-01-2021 19:10:54','20km','27 minutes',''),
(3,1,'01-03-2021 00:12:37','13.4km','20 mins','NaN'),
(4,2,'01-04-2021 13:53:03','23.4','40','NaN'),
(5,3,'01-08-2021 21:10:57','10','15','NaN'),
(6,3,null,null,null,'Cancellation'),
(7,2,'01-08-2020 21:30:45','25km','25mins',null),
(8,2,'01-10-2020 00:15:02','23.4 km','15 minute',null),
(9,2,null,null,null,'Customer Cancellation'),
(10,1,'01-11-2020 18:50:20','10km','10minutes',null);


drop table if exists customer_orders;
CREATE TABLE customer_orders(order_id integer,customer_id integer,roll_id integer,not_include_items VARCHAR(4),extra_items_included VARCHAR(4),order_date datetime);
INSERT INTO customer_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date)
values (1,101,1,'','','01-01-2021  18:05:02'),
(2,101,1,'','','01-01-2021 19:00:52'),
(3,102,1,'','','01-02-2021 23:51:23'),
(3,102,2,'','NaN','01-02-2021 23:51:23'),
(4,103,1,'4','','01-04-2021 13:23:46'),
(4,103,1,'4','','01-04-2021 13:23:46'),
(4,103,2,'4','','01-04-2021 13:23:46'),
(5,104,1,null,'1','01-08-2021 21:00:29'),
(6,101,2,null,null,'01-08-2021 21:03:13'),
(7,105,2,null,'1','01-08-2021 21:20:29'),
(8,102,1,null,null,'01-09-2021 23:54:33'),
(9,103,1,'4','1,5','01-10-2021 11:22:59'),
(10,104,1,null,null,'01-11-2021 18:34:49'),
(10,104,1,'2,6','1,4','01-11-2021 18:34:49');

select * from customer_orders;
select * from driver_order;
select * from ingredients;
select * from driver;
select * from rolls;
select * from rolls_recipes;



/*
a. roll metrices
b. driver and customer experience
c. ingredient optimisation
d. pricing and ratings
*/


/* a. roll metrices*/

/*Q.1 How many rolls were ordered? */

select count(roll_id) as roll_count  from customer_orders;

/*Q.2 How many unique customer orders were made?*/

select count(distinct customer_id) as unique_customer_count from customer_orders;

/*Q.3 How many successful orders were delivered by each driver? */

select driver_id, count(distinct order_id) as unique_orders from driver_order where cancellation not in('cancellation','customer cancellation')
group by driver_id;

/*Q.4 How many of each type of roll were delivered? */

select roll_id, count(roll_id) as roll_count from customer_orders where order_id in(
select order_id from
(select *, case when cancellation in('cancellation','Customer Cancellation') then 'c' else 'nc' end as order_cancel_details from driver_order) a
where order_cancel_details='nc')
group by roll_id;

/*Q.5 How many veg and Non-veg rolls were ordered by each customer? */

select a.*, b.roll_name from
(
select  customer_id,roll_id,count(roll_id) as roll_count from customer_orders
group by customer_id, roll_id) a inner join rolls b on a.roll_id=b.roll_id;

/*Q.6 What was the maximum number of rolls delivered in a single order? */


select * from
(
select *, rank() over(order by cnt desc) rnk from
(
select order_id, count(roll_id) as cnt
from (
select * from customer_orders where order_id in(
select order_id from
(select *, case when cancellation in('cancellation','Customer Cancellation') then 'c' else 'nc' end as order_cancel_details from driver_order) a
where order_cancel_details='nc'))b
group by order_id
)c)d where rnk=1;

/* Q.7 for each customer , how many delivered rolls had atleast one change and how amny had no changes? */

with temp_customer_orders (order_id, customer_id, roll_id, not_include_items, extra_items_included, order_date) as
(
select order_id, customer_id, roll_id, 
case when not_include_items is null or not_include_items =' ' then '0' else not_include_items end as new_not_include_items,
case when extra_items_included is null or extra_items_included =' ' or extra_items_included ='NaN' then '0' else extra_items_included end as new_extra_items_included,
order_date from customer_orders
)
,
temp_driver_order (order_id, driver_id, pickup_time, distance, duration, new_cancellation) as
(
select order_id, driver_id, pickup_time, distance, duration,
case when cancellation in('cancellation','Customer Cancellation') then 0 else 1 end as new_cancellation
from driver_order
)
select customer_id,chg_no_chg, count(order_id) as at_least_1_change from
(
select *, case when not_include_items ='0' and extra_items_included ='0' then 'No change' else 'change' end as chg_no_chg from temp_customer_orders where order_id in(
select order_id from temp_driver_order where new_cancellation !=0))a
group by customer_id, chg_no_chg;


/*Q.8 How many rolls were delivered that had both exclusions and extras? */

with temp_customer_orders (order_id, customer_id, roll_id, not_include_items, extra_items_included, order_date) as
(
select order_id, customer_id, roll_id, 
case when not_include_items is null or not_include_items =' ' then '0' else not_include_items end as new_not_include_items,
case when extra_items_included is null or extra_items_included =' ' or extra_items_included ='NaN' then '0' else extra_items_included end as new_extra_items_included,
order_date from customer_orders
)
,
temp_driver_order (order_id, driver_id, pickup_time, distance, duration, new_cancellation) as
(
select order_id, driver_id, pickup_time, distance, duration,
case when cancellation in('cancellation','Customer Cancellation') then 0 else 1 end as new_cancellation
from driver_order
)

select inc_exc, count(inc_exc) as both_inc_exc from
(select *, case when not_include_items !='0' and extra_items_included !='0' then 'both inc exc' else 'either 1 inc or exc' end as inc_exc from temp_customer_orders where order_id in(
select order_id from temp_driver_order where new_cancellation !=0))a
group by inc_exc;


/*Q.9 what was the total number of rolls ordered for each hour of the day? */

select hours_bucket,count(hours_bucket) as hour_wise_count from
(
select *, concat(cast(datepart(hour, order_date)as varchar),'-',cast(datepart(hour, order_date)+1 as varchar)) as hours_bucket from customer_orders)a
group by hours_bucket;


/*Q.10 what was the number of orers for each day of the week? */

select dow, count(distinct order_id) from
(select *, datename(dw, order_date) as dow from customer_orders)a
group by dow;

/* will update more metrices along with the time */