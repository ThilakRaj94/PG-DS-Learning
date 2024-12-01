use orders;	

-- Q1.

SELECT 
    CONCAT(CASE
                WHEN CUSTOMER_GENDER = 'F' THEN 'MS'
                WHEN CUSTOMER_GENDER = 'M' THEN 'MR'
            END,
            '. ',
            UPPER(customer_fname),
            ' ',
            UPPER(customer_lname)) AS CUSTOMER_NAME,
    CUSTOMER_EMAIL,
    CUSTOMER_CREATION_DATE,
    CASE
        WHEN YEAR(CUSTOMER_CREATION_DATE) < '2005' THEN 'Category A'
        WHEN
            YEAR(CUSTOMER_CREATION_DATE) >= '2005'
                AND YEAR(CUSTOMER_CREATION_DATE) < '2011'
        THEN
            'Category B'
        WHEN YEAR(CUSTOMER_CREATION_DATE) >= '2011' THEN 'Category C'
    END AS CATAGORY
FROM
    ONLINE_CUSTOMER;		
    
-- ---------------------------------------------------------------------
-- Q2.

SELECT 
    product_id,
    product_desc,
    product_quantity_avail,
    product_price,
    (product_quantity_avail * product_price) inventory_values,
    CASE
        WHEN product_price > '20000' THEN product_price - (product_price * 0.2)
        WHEN product_price > '10000' THEN product_price - (product_price * 0.15)
        WHEN product_price <= '10000' THEN product_price - (product_price * 0.1)
    END AS New_Price
FROM
    product
WHERE
    product_id NOT IN (SELECT DISTINCT
            (product_id)
        FROM
            order_items)
ORDER BY inventory_values DESC;
 
 -- ------------------------------------------------------------------------
 -- Q3.
	
SELECT 
    pc.product_class_code,
    pc.product_class_desc,
    COUNT(p.product_id) count_of_product_type,
    SUM(p.PRODUCT_QUANTITY_AVAIL * p.Product_price) AS Inventory_value
FROM
    product_class pc
        LEFT JOIN
    product p ON pc.product_class_code = p.product_class_code
GROUP BY pc.product_class_code
HAVING Inventory_value > 100000
ORDER BY Inventory_Value DESC;

-- ------------------------------------------------------------
-- Q4.

SELECT 
    oc.customer_id,
    CONCAT(customer_fname, ' ', customer_lname) AS Customer_Full_Name,
    oc.customer_email,
    oc.customer_phone,
    a.country
FROM
    online_customer oc
        LEFT JOIN
    address a ON oc.address_id = a.address_id
WHERE
    oc.customer_id IN (SELECT 
            customer_id
        FROM
            order_header
        WHERE
            order_status = 'Cancelled');
            
-- ---------------------------------------------------------
-- Q5

SELECT 
    s.shipper_name,
    a.city,
    COUNT(DISTINCT (oc.customer_id)) Customers_Catered,
    COUNT(oh.order_id) No_of_Consignments_Delivered
FROM
    shipper s
        JOIN
    order_header oh USING (shipper_id)
        JOIN
    online_customer oc USING (customer_id)
        JOIN
    address a USING (address_id)
WHERE
    s.shipper_name = 'DHL'
GROUP BY a.city;

-- ------------------------------------------------------------------
-- Q6

SELECT 
    p.product_id,
    p.product_desc,
    p.product_quantity_avail,
    IFNULL(s.qty_sold, 0) AS qty_sold,
    CASE
        WHEN
            PRODUCT_CLASS_CODE IN ('2050' , '2053')
        THEN
            CASE
                WHEN qty_sold IS NULL THEN 'No Sales in past, give discount to reduce inventory'
                WHEN product_quantity_avail < (0.1 * qty_sold) THEN 'Low inventory, need to add inventory'
                WHEN product_quantity_avail < (0.5 * qty_sold) THEN 'Medium inventory, need to add some inventory'
                WHEN product_quantity_avail >= (0.5 * qty_sold) THEN 'Sufficient inventory'
            END
        WHEN
            PRODUCT_CLASS_CODE IN ('2055' , '2057')
        THEN
            CASE
                WHEN qty_sold IS NULL THEN 'No Sales in past, give discount to reduce inventory'
                WHEN product_quantity_avail < (0.2 * qty_sold) THEN 'Low inventory, need to add inventory'
                WHEN product_quantity_avail < (0.6 * qty_sold) THEN 'Medium inventory, need to add some inventory'
                WHEN product_quantity_avail >= (0.6 * qty_sold) THEN 'Sufficient inventory'
            END
        ELSE CASE
            WHEN s.qty_sold IS NULL THEN 'No Sales in past, give discount to reduce inventory'
            WHEN product_quantity_avail < (0.3 * qty_sold) THEN 'Low inventory, need to add inventory'
            WHEN product_quantity_avail < (0.7 * qty_sold) THEN 'Medium inventory, need to add some inventory'
            WHEN product_quantity_avail >= (0.7 * qty_sold) THEN 'Sufficient inventory'
        END
    END AS Inventory_status
FROM
    product p
        LEFT JOIN
    (SELECT 
        product_id, COUNT(product_quantity) qty_sold
    FROM
        order_items
    GROUP BY product_id) AS s ON p.product_id = s.product_id
        LEFT JOIN
    product_class USING (product_class_code)
ORDER BY p.product_id;

-- --------------------------------------------------------------------------------------
-- Q7


SELECT 
    order_id,
    SUM(p.len * p.width * p.height) AS order_product_volume
FROM
    order_items oi
        JOIN
    product p USING (product_id)
GROUP BY order_id
HAVING order_product_volume <= (SELECT 
        (len * width * height)
    FROM
        carton
    WHERE
        carton_id = '10')
ORDER BY order_product_volume DESC
LIMIT 1;

-- ---------------------------------------------------------------------------
-- Q8

SELECT 
    *
FROM
    online_customer;
SELECT 
    oc.customer_id,
    CONCAT(oc.Customer_fname,
            ' ',
            oc.customer_lname) AS Customer_Full_Name,
    IFNULL(SUM(oi.product_quantity), 0) AS Total_Quantity,
    IFNULL(SUM(oi.product_quantity * product_price),
            0) AS Total_Shipped_Value
FROM
    online_customer oc
        LEFT JOIN
    order_header oh USING (customer_id)
        LEFT JOIN
    order_items oi USING (order_id)
        LEFT JOIN
    product p USING (product_id)
WHERE
    oh.payment_mode = 'Cash'
        AND oc.customer_lname LIKE 'G%'
GROUP BY oc.customer_id;

-- ------------------------------------------------------------------------------------
-- Q9

SELECT 
    p.product_id,
    p.product_desc,
    SUM(product_quantity) AS Total_quantity
FROM
    order_items oi
        LEFT JOIN
    product p USING (product_id)
        INNER JOIN
    (SELECT 
        order_id
    FROM
        order_items
    WHERE
        product_id = '201') a USING (order_id)
        LEFT JOIN
    order_header oh USING (order_id)
        LEFT JOIN
    online_customer oc USING (customer_id)
        LEFT JOIN
    address a USING (address_id)
WHERE
    p.product_id != '201'
        AND a.city NOT IN ('Bangalore' , 'New Delhi')
GROUP BY p.product_id
ORDER BY product_id;

-- --------------------------------------------------------------------
-- Q10.

SELECT 
    oh.order_id,
    oh.customer_id,
    CONCAT(oc.customer_fname,
            ' ',
            oc.customer_lname) AS Customer_Full_Name,
    IFNULL(SUM(oi.product_quantity), '0(Cancelled)') AS Product_Shipped_Quantity,
    a.pincode
FROM
    order_header oh
        LEFT JOIN
    online_customer oc USING (customer_id)
        LEFT JOIN
    order_items oi USING (order_id)
        LEFT JOIN
    address a USING (address_id)
WHERE
    (oh.order_id % 2) = 0
        AND a.pincode NOT LIKE '5%'
GROUP BY oh.order_id;
    
-- ---------------------------------------------------------------------------