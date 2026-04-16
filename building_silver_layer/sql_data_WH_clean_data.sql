use data_warehouse_project ;

create schema silver ;

use silver ;

----------------------------------------------------------------------------------------------
create table silver.crm_cust_info(
cst_id int ,
cst_key varchar(50), 
cst_firstname varchar(50), 
cst_lastname varchar(50) ,
cst_marital_status varchar(50), 
cst_gndr varchar(50) ,
cst_create_date varchar(50)) ;

select * from silver.crm_cust_info ;

-- finding duplicates in primary key 
select cst_id , count(*) as counting from silver.crm_cust_info 
group by cst_id 
having count(*) > 1 ;

select * from silver.crm_cust_info 
where cst_id = 29466 ;

with rankes as ( 
select * , row_number()over(partition by cst_id order by cst_create_date desc ) as rn 
from silver.crm_cust_info )
delete from silver.crm_cust_info 
where cst_id in ( select  cst_id  from rankes where rn > 1 ) ;
-- chech unwanted spaces 
-- remove the unwanted spaces 

select cst_firstname from silver.crm_cust_info 
where cst_firstname != trim(cst_firstname) ;

select cst_firstname , cst_lastname from silver.crm_cust_info ;

update silver.crm_cust_info 
set cst_firstname = case 
					when cst_firstname = '' then "Unknown"
                    else trim(cst_firstname) 
                    end ,
	cst_lastname = case 
					when cst_lastname = '' then "Unknown"
                    else trim(cst_lastname) 
                    end ;
                    
-- changeing the values in columns 

select distinct cst_marital_status from silver.crm_cust_info ;

update silver.crm_cust_info 
set cst_marital_status = case 
						when upper(trim(cst_marital_status)) = 'M' then 'Married'
                        when upper(trim(cst_marital_status)) = 'S' then "Single"
                        else  "Unkown"
                        end ;
                        
select distinct cst_gndr from silver.crm_cust_info ;

update silver.crm_cust_info 
set cst_gndr = case 
when upper(trim(cst_gndr)) = "M" then "Male"
when upper(trim(cst_gndr)) = "F" then "Female"
else "N/A"
end ;

alter table silver.crm_cust_info 
add column dwh_create_dt date ;

update silver.crm_cust_info 
set dwh_create_dt = current_date ;
------------------------------------------------------------------------------------------------
create table silver.crm_prod_info (
prd_id int ,
prd_key varchar(50),
prd_nm varchar(50),
prd_cost varchar(50), 
prd_line varchar(50),
prd_start_dt text,
prd_end_dt text ) ;

select * from silver.crm_prod_info ;

-- Finding duplicates in primary key 
select prd_id , count(*) as counting from silver.crm_prod_info 
group by prd_id 
having counting > 1 ;

-- adding new col cat_id 
alter  table silver.crm_prod_info 
add column cat_id varchar(50) 
after prd_key ;

update silver.crm_prod_info 
set cat_id=replace(substring(prd_key , 1, 5 ) , '-' , '_') ;

-- crating a column for produst_key another col 
alter table silver.crm_prod_info
add column prod_key varchar(50) 
after cat_id ;

update silver.crm_prod_info 
set prod_key = substring(prd_key , 7, length(prd_key)) ;

-- chech unwanted spaces in prd_name 
select prd_nm from silver.crm_prod_info 
where prd_nm  != trim(prd_nm) ;

-- check for null and negive numbers 

select prd_cost from silver.crm_prod_info 
where prd_cost < 0 or prd_cost = '' ;

update silver.crm_prod_info
set prd_cost = 0 
where prd_cost = '' ;

-- checking the prd_line and remove nulls giving a values
select distinct prd_line from silver.crm_prod_info ;

update silver.crm_prod_info 
set prd_line = case 
when upper(trim(prd_line)) = 'R' then 'Road'
when upper(trim(prd_line)) = 'S' then 'Other Sales'
when upper(trim(prd_line)) = 'M' then 'Mountain'
when upper(trim(prd_line)) = 'T' then 'Touring'
else 'N/A' 
end ;

-- checking the dates
select * from silver.crm_prod_info
where prd_end_dt < prd_start_dt ;

update silver.crm_prod_info t 
join ( 
select prd_key , prd_start_dt , lead(prd_start_dt)over(partition by prd_key 
order by prd_start_dt ) as k from silver.crm_prod_info ) s 
on t.prd_key = s.prd_key and 
t.prd_start_dt = s.prd_start_dt
set  t.prd_end_dt =s.k ;

alter table silver.crm_prod_info 
add column dwh_create_dt date ;

update silver.crm_prod_info 
set dwh_create_dt = current_date;

-------------------------------------------------------------------------------------
create table silver.crm_sales_info (
sls_ord_num varchar(50),
sls_prd_key varchar(50),
sls_cust_id int ,
sls_order_dt int ,
sls_ship_dt int ,
sls_due_dt int ,
sls_sales int ,
sls_quantity int ,
sls_price int ) ;

select * from silver.crm_sales_info ;

-- remove the unwanted spaces and upadeing
select sls_ord_num from silver.crm_sales_info 
where sls_ord_num != trim(sls_ord_num) ;

-- checking the sls_product_key in both tables like crm_sales_info and crm_prod_info

select * from bronze.crm_sales_info 
where sls_prd_key not in ( select prod_key from silver.crm_prod_info) ;

select * from bronze.crm_sales_info 
where sls_cust_id not in ( select cst_id from silver.crm_cust_info) ;

-- check vales dates
select sls_order_dt from silver.crm_sales_info 
where sls_order_dt <= 0 or 
length(sls_order_dt) != 8 or 
sls_order_dt > 20500101 or 
sls_order_dt < 19900101 ;

update silver.crm_sales_info
set sls_order_dt = case 
when sls_order_dt = 0 or length(sls_order_dt) > 8 then Null
else sls_order_dt
end ;

update silver.crm_sales_info 
set sls_order_dt = Null 
where length(sls_order_dt) < 8 ;

alter table silver.crm_sales_info
modify sls_order_dt date ;

UPDATE silver.crm_sales_info
SET sls_order_dt =
    CASE
        WHEN sls_order_dt LIKE '____-__-__' THEN sls_order_dt
        WHEN sls_order_dt REGEXP '^[0-9]{8}$'
        THEN STR_TO_DATE(sls_order_dt, '%Y%m%d')

        ELSE NULL
    END;
    
select sls_ship_dt from silver.crm_sales_info 
where sls_ship_dt <= 0 or 
length(sls_ship_dt) != 8 or 
sls_ship_dt > 20500101 or 
sls_ship_dt < 19900101 ;


alter table silver.crm_sales_info
modify sls_ship_dt date ;

UPDATE silver.crm_sales_info
SET sls_ship_dt =
    CASE
        WHEN sls_ship_dt LIKE '____-__-__' THEN sls_ship_dt
        WHEN sls_ship_dt REGEXP '^[0-9]{8}$'
        THEN STR_TO_DATE(sls_ship_dt, '%Y%m%d')
        ELSE NULL
    END;
    
select sls_due_dt from silver.crm_sales_info 
where sls_due_dt <= 0 or 
length(sls_due_dt) != 8 or 
sls_due_dt > 20500101 or 
sls_due_dt < 19900101 ;

alter table silver.crm_sales_info
modify sls_due_dt date ;

UPDATE silver.crm_sales_info
SET sls_due_dt =
    CASE
        WHEN sls_due_dt LIKE '____-__-__' THEN sls_ship_dt
        WHEN sls_due_dt REGEXP '^[0-9]{8}$'
        THEN STR_TO_DATE(sls_due_dt, '%Y%m%d')
        ELSE NULL
    END;

-- checking invalid date 
select * from silver.crm_sales_info
where sls_order_dt > sls_ship_dt or sls_order_dt > sls_due_dt ;

-- check data consistency between slaes , quantity , price 
-- >> sals=price * Quantity 
-- >> values must not be null , zeros or negitave 

select distinct
sls_sales ,
sls_quantity ,
sls_price from silver.crm_sales_info 
where sls_sales != sls_quantity * sls_sales or 
 sls_sales <=0 or sls_quantity <=0 or sls_price <= 0 or 
 sls_sales is null or sls_quantity is null or sls_price is null 
 order by sls_sales , sls_quantity , sls_price ;

update silver.crm_sales_info
set sls_sales = case 
when sls_sales <= 0 or sls_sales is null or sls_sales != abs(sls_price) * sls_quantity
	then abs(sls_price) * sls_quantity 
    else sls_sales 
    end ;
    
update silver.crm_sales_info 
set sls_price = case 
when  sls_price <= 0 or sls_price is null 
   then sls_sales / ifnull(sls_quantity , 0) 
   else sls_price 
   end ;
   
--------------------------------------------------------------------------------------------
create table silver.erm_cust_data (
CID varchar(50),
BDATE varchar(50),
GEN varchar(50) );

select * from silver.erm_cust_data ;

alter table silver.erm_cust_data 
add column c_id varchar(50) 
after cid ;

update silver.erm_cust_data 
set c_id = case 
when CID like 'NAS%' then substring(CID , 4 , length(CID))
else CID 
end ;

select * from bronze.erm_cust_data 
where cid not in ( select c_id from silver.erm_cust_data ) ;

-- chech date vallid dates then update 
select bdate from silver.erm_cust_data 
where bdate is null ;

select * from silver.erm_cust_data
where bdate != date_format(bdate , '%Y-%m-%d') ;

update silver.erm_cust_data
set bdate=case 
when bdate regexp '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' then str_to_date(bdate , '%d-%m-%Y')
when bdate regexp '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' then str_to_date(bdate , '%Y-%m-%d')
else bdate 
end ;

select * from silver.erm_cust_data 
where year(bdate) not between 1900 and 2000
or  year(bdate) > current_time ;

update silver.erm_cust_data 
set bdate = "Wrong_Birth_Date"
where year(bdate) not between 1900 and 2000
or  year(bdate) > current_time ;

-- check the data in gen column 

select distinct gen from silver.erm_cust_data ;

update silver.erm_cust_data 
set gen = case 
when upper(trim(gen)) in('M','Male') then "Male"
when upper(trim(gen)) in('F','Female') then "Female"
else "N/A" 
end ;

--------------------------------------------------------------------------------------------------
create table silver.erm_loca_data (
CID varchar(50), 
CNTRY varchar(50) ) ;

alter table silver.erm_loca_data 
add column dwh_create_date date ;

select * from silver.erm_loca_data ;

-- check the data at cid 
select replace(cid , '-' , '') as id from silver.erm_loca_data ;

update silver.erm_loca_data 
set cid = replace(cid , '-','') ;

-- check the country column

select distinct cntry from silver.erm_loca_data 
order by cntry ;

update silver.erm_loca_data 
set cntry = case 
when trim(cntry) = 'DE' then 'Germany'
when trim(cntry) in ('US','USA') then 'United States '
when trim(cntry) in ('') or cntry is null then 'N/A'
else cntry 
end ;

update silver.erm_loca_data 
set dwh_create_date = curdate();

------------------------------------------------------------------------------------------
create table silver.erm_product_data (
ID varchar(50),
CAT varchar(50),
SUBCAT varchar(50),
MAINTENANCE varchar(50) ) ;

select * from silver.erm_product_data ;

-- cecking for unwanted spaces 
select *  from silver.erm_product_data 
where trim(cat) != cat or 
trim(subcat) != subcat or 
trim(MAINTENANCE) != MAINTENANCE ;

-- data standards and consistency 
select distinct cat from silver.erm_product_data ;

select distinct SUBCAT from silver.erm_product_data ;

select distinct MAINTENANCE from silver.erm_product_data ;

-----------------------------------------------------------------------------------------
insert into gold.crm_cust_info 
select * from silver.crm_cust_info ;

insert into gold.crm_prod_info 
select * from silver.crm_prod_info ;

insert into gold.crm_sales_info 
select * from silver.crm_sales_info ;

insert into gold.erm_cust_data
select * from silver.erm_cust_data ;

insert into gold.erm_loca_data 
select * from silver.erm_loca_data ;

insert into gold.erm_product_data
select * from silver.erm_product_data ;