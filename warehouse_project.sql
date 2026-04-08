#create database warehouse;
use warehouse;
select * from logistics_data;
create view category_inventory_summary as 
select category,zone,count(item_id) as total_items_per_category ,round(avg(daily_demand),2) as avg_demand,
round(avg(holding_cost_per_unit_day),2) as avg_holdingcost, 
round(avg(forecasted_demand_next_7d),2) as avg_forecasted_demand,round(avg(item_popularity_score),3) as item_popularity,
round(avg(stock_level),0) as avg_stock from logistics_data
group by category,zone
order by avg_forecasted_demand desc;

#high risk items
create view high_risk_inventory_items as
select item_id , stock_level, reorder_point, category from logistics_data
where stock_level<=reorder_point
order by  item_id asc ;

#handling cost for last month items  
select item_id, category,(holding_cost_per_unit_day*total_orders_last_month) as handling_cost from logistics_data;

#holding cost and handling cost for present stock
create view item_operational_costs as
select item_id,category,round((stock_level*holding_cost_per_unit_day*30),2) as holding_cost_permonth,
round((holding_cost_per_unit_day*total_orders_last_month),2) as handling_cost ,
round((stock_level*holding_cost_per_unit_day*30+holding_cost_per_unit_day*total_orders_last_month),2)  as operational_cost  
from logistics_data;

# warhouse zone items
create view zone_inventory_cost_distribution as
select zone,count(item_id) as total_items, avg(stock_level) as avg_stock,
round(sum(holding_cost_per_unit_day*stock_level),2) as total_holding_cost_per_day_present,
round(avg(forecasted_demand_next_7d),0) as avg_forecasted_demand,
round((sum(stock_level*holding_cost_per_unit_day)*30+sum(holding_cost_per_unit_day*total_orders_last_month)),2)  as total_operational_cost_include_last_month,
round(avg(item_popularity_score),1) as avg_popularity from logistics_data
group by zone
order by zone asc ;

#create view stockout_critical_items as 
create view stock_reorder_items_present as
select item_id,stock_level,reorder_point from logistics_data
where  stock_level<=reorder_point
#group by stockout_count_last_month
order by stockout_count_last_month desc;

create view  zonewise_stockout_items as  
select zone,count(item_id) as total_out_of_stock_item from logistics_data
where stockout_count_last_month>0 and  stock_level<=reorder_point
group by zone 
order by zone;

-- select 
--   WHEN turnover_ratio < 2 THEN 'Overstocked'
--   WHEN turnover_ratio BETWEEN 2 AND 4 THEN 'Slow Moving'
--   WHEN turnover_ratio BETWEEN 4 AND 8 THEN 'Healthy'
--   WHEN turnover_ratio BETWEEN 8 AND 12 THEN 'Fast Moving'
--   ELSE 'Very Fast Moving'
-- END AS turnover_category

#next order day ,next_restock_date and day_stockout
create view item_restock_stockout_schedule as 
select item_id,last_restock_date,date_add(last_restock_date, INTERVAL reorder_frequency_days DAY ) as next_order_day,
date_add(date_add(last_restock_date, INTERVAL reorder_frequency_days DAY),INTERVAL lead_time_days DAY) as next_restock_date,
date_add(last_restock_date,INTERVAL (stock_level/daily_demand) DAY) as stockout_date
 from logistics_data l;
 
 create view  negative_buffer_items as
 select * from (select item_id,last_restock_date,date_add(last_restock_date, INTERVAL reorder_frequency_days DAY ) as next_order_day,
date_add(date_add(last_restock_date, INTERVAL reorder_frequency_days DAY),INTERVAL lead_time_days DAY) as next_restock_date,
date_add(last_restock_date,INTERVAL (stock_level/daily_demand) DAY) as stockout_date,
datediff((date_add(last_restock_date,INTERVAL (stock_level/daily_demand) DAY)),
(date_add(date_add(last_restock_date, INTERVAL reorder_frequency_days DAY),INTERVAL lead_time_days DAY)))
as buffer_days
 from logistics_data l) t
 where buffer_days<0
 order by buffer_days asc;

 #zone wise avg buffer days
 
create view zonewise_buffer_risk_summary  as
 with new_d as (select l.zone,item_id,last_restock_date,
date_add(last_restock_date, INTERVAL reorder_frequency_days DAY ) as next_order_day,
date_add(date_add(last_restock_date, INTERVAL reorder_frequency_days DAY),INTERVAL lead_time_days DAY) as next_restock_date,
date_add(last_restock_date,INTERVAL (stock_level/daily_demand) DAY) as stockout_date,
datediff((date_add(last_restock_date,INTERVAL (stock_level/daily_demand) DAY)),
(date_add(date_add(last_restock_date, INTERVAL reorder_frequency_days DAY),INTERVAL lead_time_days DAY)))
as buffer_days
 from logistics_data as l)
  select  n.Zone,count(item_id) as no_stockout_items,avg(buffer_days) as avg_buffer_days from  new_d n
 where buffer_days<0 #next_restock_date > stockout_date
 group by n.zone
 order by zone ASC;
 
 #present inventory value 
 create view inventory_value as
 select round((stock_level*unit_price),2) as revenue from logistics_data;
 
 #forcasted revenue 
 create view forecasted_revenue_items as
 select (forecasted_demand_next_7d*unit_price) as revenue from logistics_data;
 
 select item_id,round(greatest(0,forecasted_demand_next_7d-stock_level),0) as missing from logistics_data
 order by missing desc;
 
 select item_id,reorder_frequency_days,round(greatest(0,forecasted_demand_next_7d-stock_level),0) as missing from logistics_data
 where reorder_frequency_days>7 and round(greatest(0,forecasted_demand_next_7d-stock_level),0) > 0;
 
 #create view zone_inventory_shortage as
 select Zone,avg(reorder_frequency_days),round(avg(greatest(0,forecasted_demand_next_7d-stock_level)),0) as missing from logistics_data
 where reorder_frequency_days>7 and round(greatest(0,forecasted_demand_next_7d-stock_level),0) > 0
 group by zone
 order by missing desc;
 
 #create view short_cycle_shortage_items as 
  select item_id,reorder_frequency_days,round(greatest(0,forecasted_demand_next_7d-stock_level),0) as missing from logistics_data
 where reorder_frequency_days<7 and round(greatest(0,forecasted_demand_next_7d-stock_level),0) > 0;
 
 #create view immediate_demand_gap_items as
 select item_id,stock_level, round(reorder_frequency_days*forecasted_demand_next_7d/7,0) as demanded,
 round((reorder_frequency_days*forecasted_demand_next_7d/7-stock_level),0) as missing from logistics_data
 where reorder_frequency_days<=7 and round(reorder_frequency_days*forecasted_demand_next_7d/7-stock_level,0)>0
 order by missing;
 
 #create view overstocked_items as 
 select item_id,stock_level, round(reorder_frequency_days*forecasted_demand_next_7d/7,0) as demanded,
 round((reorder_frequency_days*forecasted_demand_next_7d/7-stock_level),0) as missing from logistics_data
 where reorder_frequency_days<=7 and round(reorder_frequency_days*forecasted_demand_next_7d/7-stock_level,0)<0
 order by missing;
 
 create view Reorder_point_buffer_risk as
 Select  item_id,stock_level,reorder_point,ROUND(reorder_frequency_days * forecasted_demand_next_7d / 7, 0) AS forecasted_demand_cycle,
    ROUND(reorder_point - (reorder_frequency_days * forecasted_demand_next_7d / 7),0) AS reorder_point_buffer
from logistics_data
where reorder_frequency_days <= 7
and reorder_point < (reorder_frequency_days * forecasted_demand_next_7d / 7)
order by reorder_point_buffer;

create view days_of_supply as 
select round((forecasted_demand_next_7d/7),0) as forecasted_dailyDemand,round((stock_level*7/forecasted_demand_next_7d),0) as days_of_supply
  from logistics_data;