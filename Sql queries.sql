/* 1.Provide the list of markets in which customer  "Atliq  Exclusive"  
operates its business in the  APAC  region.  */
select distinct(market)
from dim_customer 
where region="APAC" and customer= "Atliq Exclusive";

/* 2.What is the percentage of unique product increase in 2021 vs. 2020? The 
final output contains these fields, 
unique_products_2020 
unique_products_2021 
percentage_chg */
with cte1 as (
      select count(distinct case when fiscal_year=2020 then product_code end)
      as unique_products_2020,
      count(distinct case when fiscal_year=2021 then product_code end)
      as unique_products_2021 from fact_sales_monthly)
select unique_products_2020,
	   unique_products_2021,
       round((unique_products_2021 -unique_products_2020)/unique_products_2020*100,2)as percentage_chg
       from cte1 ;

/* 3.  Provide a report with all the unique product counts for each  segment  and 
sort them in descending order of product counts. The final output contains 
2 fields, 
segment 
product_count */
select segment,count(distinct product_code) as product_count
from dim_product
group by segment
order by product_count desc;

/* 4.Which segment had the most increase in unique products in 
2021 vs 2020? The final output contains these fields, 
segment product_count_2020 product_count_2021 difference */
with cte1 as (
select p.segment as segment ,
count(distinct case when fiscal_year=2020 then s.product_code end)
      as unique_products_2020,
      count(distinct case when fiscal_year=2021 then s.product_code end)
      as unique_products_2021 
      from fact_sales_monthly s
      join dim_product p
      on s.product_code=p.product_code
      group by p.segment )
select * ,
       round(unique_products_2021 - unique_products_2020,2) as difference
       from cte1
       order by difference desc;

/* Get the products that have the highest and lowest manufacturing costs. 
The final output should contain these fields, 
product_code product,manufacturing_cost */

select p.product_code, p.product,round(m.manufacturing_cost,2) as manufacturing_cost
 from fact_manufacturing_cost m 
 join dim_product p
 on m.product_code=p.product_code
 where m.manufacturing_cost= (select max(manufacturing_cost) 
 from fact_manufacturing_cost)
 or m.manufacturing_cost=(select min(manufacturing_cost) from fact_manufacturing_cost)
order by m.manufacturing_cost desc;

/*Generate a report which contains the top 5 customers who received an 
average high  pre_invoice_discount_pct  for the  fiscal  year 2021  and in the 
Indian  market. The final output contains these fields, 
customer_code customer average_discount_percentage */
select c.customer_code as customer_code,
c.customer,
round(avg(d.pre_invoice_discount_pct)*100,2)as average_discount_percentage
from fact_pre_invoice_deductions d
join dim_customer c 
on d.customer_code=c.customer_code
where d.fiscal_year=2021 and c.market="india"
group by customer_code,customer
order by average_discount_percentage desc limit 5;

/* 7.Get the complete report of the Gross sales amount for the customer  “Atliq 
Exclusive”  for each month  .  This analysis helps to  get an idea of low and 
high-performing months and take strategic decisions
The final report contains these columns, Month Year Gross sales Amount */

select monthname(s.date) as months, year(date) as years,
round(sum(s.sold_quantity* g.gross_price)/1000000,2) as gross_sales_amount_mln
 from fact_sales_monthly s
 join fact_gross_price g 
 on s.product_code=g.product_code 
 and s.fiscal_year=g.fiscal_year
 join dim_customer c
 on c.customer_code=s.customer_code
 where c.customer="atliq exclusive"
 group by months,years
 order by years;
 
 /* 8.  In which quarter of 2020, got the maximum total_sold_quantity? The final 
output contains these fields sorted by the total_sold_quantity, Quarter total_sold_quantity */
select 
     case
     when month(date) in (9,10,11) 
     then "Q1"
     when month(date) in (12,1,2) then 
     "Q2"
     when month(date) in (3,4,5) then 
     "Q3"
     else 
     "Q4"
     end as quarter_sold_quantity,
     sum(sold_quantity) as sold_quantity
     from fact_sales_monthly
     where fiscal_year=2020
     group by quarter_sold_quantity
     order by sold_quantity desc;
/*9.Which channel helped to bring more gross sales in the fiscal year 2021 
and the percentage of contribution?  The final output  contains these fields, 
channel gross_sales_mln percentage */

with cte1 as
(select c.channel as channel,round(sum(s.sold_quantity*g.gross_price)/1000000,2) as gross_sales_mln
from fact_sales_monthly s 
join fact_gross_price g 
on s.product_code=g.product_code and 
   s.fiscal_year=g.fiscal_year
join dim_customer c
on s.customer_code=c.customer_code
where s.fiscal_year=2021
group by c.channel
order by gross_sales_mln desc)
select *, concat(round(gross_sales_mln /sum(gross_sales_mln)over()*100 ,2),'%') as percentage
from cte1
order by percentage desc;

/* 10.  Get the Top 3 products in each division that have a high 
total_sold_quantity in the fiscal_year 2021? The final output contains these 
fields, division product_code */
with cte1 as
(select p.division as division,p.product_code  as product_code,
p.product as product ,sum(s.sold_quantity) as total_sold_qty
from dim_product p 
join fact_sales_monthly s 
on p.product_code=s.product_code 
where fiscal_year=2021
group by p.division,p.product_code,p.product
order by total_sold_qty desc),
cte2 as (select *,
dense_rank() over(partition by division order by total_sold_qty desc) as drnk
from cte1)
select * from cte2 where drnk<=3;











      
