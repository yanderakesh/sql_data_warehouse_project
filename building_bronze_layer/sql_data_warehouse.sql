-- importing data from datasets
use bronze ;

select * from bronze.crm_cust_info ;

select * from bronze.crm_prod_info ;

select * from bronze.crm_sales_info;

select * from bronze.erm_cust_data;

select * from erm_location_data ;

select * from erm_product_data;

select * from crm_cust_info 
limit 1000 ;

select * from crm_prod_info
limit 1000 ;

select * from crm_sales_info 
limit 1000 ;


insert into silver.crm_cust_info 
select * from bronze.crm_cust_info ;


insert into silver.crm_prod_info 
select * from bronze.crm_prod_info ;

insert into silver.crm_sales_info
select *  from bronze.crm_sales_info ;

insert into silver.erm_cust_data
select * from bronze.erm_cust_data ;

insert into silver.erm_loca_data 
select * from bronze.erm_location_data ;

insert into silver.erm_product_data
select * from bronze.erm_product_data ;




















