#1 Atliq Exclusive in APAC region 
select distinct market from dim_customer where customer="Atliq Exclusive" and
region = "APAC";

#2 Percentage of unique product increase in 2021 vs 2020
with fy20 as 
(select count(distinct product_code) as fy_pc_20 from fact_gross_price
where fiscal_year='2020'),
fy21 as (select count(distinct product_code) as fy_pc_21 from fact_gross_price
where fiscal_year='2021')
select fy20.fy_pc_20 as unique_products_2020, fy21.fy_pc_21 as unique_products_2021,
concat(round((fy21.fy_pc_21 - fy20.fy_pc_20)*100/fy20.fy_pc_20,2),"%") as pct_inc
from fy20,fy21;

#3 Unique product count for each segment
select  segment, count(product) as product_count from dim_product
group by segment
order by product_count desc;

#4 Segment had the most increase in unique products in 2021 vs 2020
With f20 as 
(select p.segment, count(distinct p.product_code) as product_count_20 from dim_product as p
join fact_sales_monthly as s
on p.product_code=s.product_code
where s.fiscal_year ='2020'
group by p.segment, s.fiscal_year),
f21 as
(select p.segment, count(distinct p.product_code) as product_count_21 from dim_product as p
join fact_sales_monthly as s
on p.product_code=s.product_code
where s.fiscal_year ='2021'
group by p.segment, s.fiscal_year )
select f20.segment,f20.product_count_20, f21.product_count_21,
(f21.product_count_21 - f20.product_count_20) as difference from f20
join f21
on f20.segment=f21.segment;   

#5 The products that have the highest and lowest manufacturing costs
select p.product,p.product_code, m.manufacturing_cost from dim_product as p
join fact_manufacturing_cost as m
on p.product_code=m.product_code
where manufacturing_cost in (
select min(manufacturing_cost) from fact_manufacturing_cost
Union
select max(manufacturing_cost) from fact_manufacturing_cost
)
order by m.manufacturing_cost;


#6 Top 5 customers who received an average discount in 2021 & Indian market
select c.customer,c.customer_code,round((pid.pre_invoice_discount_pct*100),2)as avg_discount_percentage 
from dim_customer as c
join fact_pre_invoice_deductions as pid
on c.customer_code=pid.customer_code
where pid.fiscal_year= '2021' and c.market='India'
group by c.customer, c.customer_code
order by avg_discount_percentage desc
limit 5;

#7 Gross sales amount for the customer “Atliq Exclusive” for each month idea of low & high-performing months

select monthname(s.date) as month, year(s.date) as year, 
sum(s.sold_quantity*p.gross_price) as Gross_sales_amount
from fact_gross_price as p 
join fact_sales_monthly as s
on s.product_code = p.product_code
join dim_customer as c
on s.customer_code=c.customer_code
WHERE c.customer = 'Atliq Exclusive'
group by month, s.fiscal_year
order by year;

#8 In which quarter of 2020, got the maximum total_sold_quantity
select case 
when month(date) between 9 and 11 then "Q1"
when month(date) in (12,1,2) then "Q2"
when month(date) between 3 and 5 then "Q3"
when month(date) between 6 and 9 then "Q4"
end as Quarter,
sum(sold_quantity) as Total_sold_quantity from fact_sales_monthly
where fiscal_year='2020'
group by Quarter
order by Total_sold_quantity desc;

#9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution
with cs as(
select c.channel, round(sum(s.sold_quantity*g.gross_price/1000000),3) as gross_sales
from dim_customer as c
join fact_sales_monthly as s
on c.customer_code=s.customer_code
join fact_gross_price as g
on g.product_code=s.product_code
where s.fiscal_year = '2021'
group by c.channel
order by gross_sales desc
)
select *, concat(round(gross_sales * 100/(select sum(gross_sales) from cs),2),'%') as pct_contribution from cs ;

#10 Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021
with hd as ( 
select p.division, s.product_code,p.product, sum(s.sold_quantity) as total_sold_quantity from dim_product as p
join fact_sales_monthly as s
on p.product_code=s.product_code
where s.fiscal_year = 2021
group by p.division, p.product, s.product_code),
rt AS (
        SELECT *, RANK () OVER (PARTITION BY division ORDER BY total_sold_quantity DESC) AS rank_order FROM hd)

SELECT * from rt
    WHERE rank_order < 4
;



