create table gold.crm_cust_info (
cst_id int ,
cst_key varchar(50), 
cst_firstname varchar(50) ,
cst_lastname varchar(50) ,
cst_marital_status varchar(50) ,
cst_gndr varchar(50) ,
cst_create_date varchar(50) , 
dwh_create_dt date ) ;

select * from gold.crm_cust_info ;

------------------------------------------------------------------------------------------------
create table gold.crm_prod_info (
prd_id int ,
prd_key varchar(50) , 
cat_id varchar(50) ,
prod_key varchar(50) , 
prd_nm varchar(50) ,
prd_cost varchar(50) , 
prd_line varchar(50) ,
prd_start_dt text  ,
prd_end_dt text  ,
dwh_create_dt date ) ;

select * from gold.crm_prod_info ;

------------------------------------------------------------------------------------------------

create table gold.crm_sales_info (
sls_ord_num varchar(50) ,
sls_prd_key varchar(50) ,
sls_cust_id int ,
sls_order_dt date , 
sls_ship_dt date ,
sls_due_dt date ,
sls_sales int ,
sls_quantity int , 
sls_price int ) ;

select * from gold.crm_sales_info ;

---------------------------------------------------------------------------------------------------

create table gold.erm_cust_data(
CID varchar(50), 
c_id varchar(50), 
BDATE varchar(50), 
GEN varchar(50) ) ;

select * from gold.erm_cust_data ;

--------------------------------------------------------------------------------------------------
create table gold.erm_loca_data (
CID varchar(50) ,
CNTRY varchar(50) , 
dwh_create_date date ) ;

select * from gold.erm_loca_data ;

------------------------------------------------------------------------------------------------------
create table gold.erm_product_data(
ID varchar(50) ,
CAT varchar(50) ,
SUBCAT varchar(50) ,
MAINTENANCE varchar(50) ) ;

select * from gold.erm_product_data ;

-----------------------------------------------------------------------------------------------------
-- Creating customer dimension table
create table gold.dim_customer ( 
cust_key int ,
cust_id int ,
cust_num varchar(50) ,
cust_first_name varchar(50),
cust_last_name varchar(50) ,
cust_marital_status varchar(50),
cust_create_date date ,
cust_date_of_birth varchar(20) ,
cust_country varchar(50) ) ;

insert into gold.dim_customer ( 
cust_key,
cust_id  ,
cust_num  ,
cust_first_name ,
cust_last_name  ,
cust_marital_status ,
cust_gender ,
cust_create_date  ,
cust_date_of_birth ,
cust_country )
select
row_number()over(order by ct.cst_id ) as cust_key , 
ct.cst_id , 
ct.cst_key , 
ct.cst_firstname ,
ct.cst_lastname ,
ct.cst_marital_status ,
ct.cst_gndr ,
ct.cst_create_date,
cd.bdate,
ld.cntry   
 from gold.crm_cust_info ct left join  gold.erm_cust_data cd 
 on ct.cst_key = cd.c_id left join gold.erm_loca_data ld 
 on cd.c_id = ld.CID ;

 select * from gold.dim_customer;
 
 select distinct cust_gender from gold.dim_customer ;
 ----------------------------------------------------------------------------------------------------
 create table gold.dim_product ( 
 product_key int ,
 product_id int ,
 product_number varchar(50) ,
 product_name varchar(50) ,
 category_id varchar(50),
 category varchar(50),
 sub_catrgory varchar(50),
 maintenance varchar(50),
 cost int ,
 product_line varchar(50) ,
 start_date date ) ;
 
 select * from gold.dim_product ;
 
 insert into gold.dim_product(
 product_key  ,
 product_id  ,
 product_number  ,
 product_name  ,
 category_id ,
 category ,
 sub_catrgory ,
 maintenance ,
 cost  ,
 product_line  ,
 start_date ) 
 select  
row_number()over(order by pi.prd_start_dt , pi.prd_id ) as product_key ,
pi.prd_id ,
pi.prod_key,
pi.prd_nm ,
pd.id ,
pd.cat ,
pd.subcat ,
pd.maintenance ,
pi.prd_cost ,
pi.prd_line ,
pi.prd_start_dt 
from gold.crm_prod_info pi left join gold.erm_product_data pd 
on pi.cat_id = pd.ID ;

select * from gold.dim_product ;

--------------------------------------------------------------------------------------------------
-- createing fact table 
 create table gold.fact_sales(
 order_number varchar(50),
 product_key int ,
 customer_key int ,
 order_date date ,
 shipping_date date ,
 due_date date ,
 sales_amount int ,
 Quantity int ,
 price int ) ;
 
 insert into gold.fact_sales (
 order_number ,
 product_key  ,
 customer_key  ,
 order_date  ,
 shipping_date  ,
 due_date  ,
 sales_amount  ,
 Quantity  ,
 price  ) 
 select 
 s.sls_ord_num ,
 p.product_key ,
 c.cust_key ,
 s.sls_order_dt ,
 s.sls_ship_dt ,
 s.sls_due_dt ,
 s.sls_sales ,
 s.sls_quantity ,
 s.sls_price from silver.crm_sales_info s  left join gold.dim_product p
 on s.sls_prd_key = p.product_number left join gold.dim_customer c 
 on s.sls_cust_id = c.cust_id ;
 
 select * from gold.fact_sales ;
 
 ----------------------------------------------------------------------------------------------
 -- forekey key integrity (Dimensions) 
 
 select * from gold.dim_customer c left join gold.fact_sales f 
 on  c.cust_key = f.customer_key 
 where c.cust_key is null  ;
 