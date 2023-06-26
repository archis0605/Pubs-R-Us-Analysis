/* 1. How many pubs are located in each country? */
select country, count(pub_id) as total_pubs
from pubs
group by 1;

/* 2. What is the total sales amount for each pub, including the beverage price and quantity sold? */
with cte as(
	select s.pub_id, s.beverage_id, s.quantity, b.price_per_unit, 
		(s.quantity * b.price_per_unit) as revenue
	from sales s
	inner join beverages b using(beverage_id)
	order by 1)
select pub_id, beverage_id, quantity, price_per_unit, 
	sum(revenue) over(partition by pub_id) as total_sales
from cte;

/* 3. Which pub has the highest average rating? */
select p.pub_id, p.pub_name, round(avg(r.rating),1) as avg_rating
from pubs p
inner join ratings r using(pub_id)
group by 1,2 order by 3 desc
limit 1;

/* 4. What are the top 5 beverages by sales quantity across all pubs? */
select b.beverage_id, b.beverage_name, sum(s.quantity) as total_sales
from beverages b
inner join sales s using(beverage_id)
group by 1,2 order by 3 desc
limit 5;

/* 5. How many sales transactions occurred on each date? */
select transaction_date, count(*) as total_sales_occurred
from sales
group by 1;

/* 6. Find the name of someone that had cocktails and which pub they had it in. */
select r.customer_name, p.pub_name
from ratings r
inner join pubs p using(pub_id)
where review like "%cocktails%";

/* 7. What is the average price per unit for each category of beverages, excluding the category 'Spirit'? */
select category, round(avg(price_per_unit),2) as avg_price_per_unit
from beverages b
where category <> "Spirit"
group by 1 order by 1;

/* 8. Which pubs have a rating higher than the average rating of all pubs? */
select p.pub_name, round(avg(r.rating),1) as rating
from ratings r
inner join pubs p using(pub_id)
where r.rating > (select round(avg(rating),1) as average_rating
					from ratings)
group by 1 order by 2 desc;

/* 9. What is the running total of sales amount for each pub, ordered by the transaction date? */
with cte as (
	select s.pub_id, s.transaction_date, b.price_per_unit, 
		(s.quantity * b.price_per_unit) as total_sales
	from sales s
	inner join beverages b using(beverage_id)
	order by 1 asc)
select distinct pub_id, transaction_date,  
	sum(total_sales) over(partition by pub_id order by transaction_date asc) as running_total_sales
from cte;

/* 10. For each country, what is the average price per unit of beverages in each category, and 
what is the overall average price per unit of beverages across all categories? */
with cte as (
	select p.country, b.category, round(avg(b.price_per_unit),2) as avg_price_per_unit
	from sales s
	inner join pubs p using(pub_id)
	inner join beverages b using(beverage_id)
	group by 1,2)
select *,
	round(avg(avg_price_per_unit) over(partition by country),2) as overall_average_price
from cte
order by 1;

/* 11. For each pub, what is the percentage contribution of each category of 
beverages to the total sales amount, and what is the pub's overall sales amount? */
with cte1 as (
	select p.pub_name, b.category, 
		sum(s.quantity*b.price_per_unit) as total_sales
	from sales s
	inner join beverages b using(beverage_id)
	inner join pubs p using(pub_id)
	group by 1, 2),
cte2 as (
	select *, sum(total_sales) over(partition by pub_name) as overall_total_sales
	from cte1)
select pub_name, category, 
	concat(round((total_sales*100/overall_total_sales),2)," %") as percentage_contribution,
    overall_total_sales
from cte2;
