select 	p.ID as product_id, 
		if(post_type = 'product_variation', post_parent, 0) as is_variation, 
        sk.meta_value as product_sku,
        p.post_title as product_title,
        round(ifnull(s.meta_value, 0), 0) as product_stock_amount,
        st.meta_value as product_stock_status,
        period_sales_report.total_qty_sold
from wp_posts p 
left join wp_postmeta s on s.post_id = p.ID and s.meta_key = '_stock'
left join wp_postmeta st on st.post_id = p.ID and st.meta_key = '_stock_status'
left join wp_postmeta sk on sk.post_id = p.ID and sk.meta_key = '_sku'
left join (select distinct post_parent as id from wp_posts where post_type like 'product%') pt on pt.id = p.ID
# Get Sales
left join (select omp.meta_value as product_id, omv.meta_value as variation_id, sum(omq.meta_value) as total_qty_sold from wp_posts o 
	join wp_woocommerce_order_items oi on oi.order_item_type = 'line_item' and oi.order_id = o.ID
	join wp_woocommerce_order_itemmeta omv on omv.order_item_id = oi.order_item_id and omv.meta_key = '_variation_id'
	join wp_woocommerce_order_itemmeta omp on omp.order_item_id = oi.order_item_id and omp.meta_key = '_product_id'
	join wp_woocommerce_order_itemmeta omq on omq.order_item_id = oi.order_item_id and omq.meta_key = '_qty'
		where 
			o.post_type = 'shop_order'
            # Interval is managed here
			and o.post_date >= DATE(NOW()) - INTERVAL 1 WEEK
			and o.post_status in (
				# You can decide which order types to include to sold quantity amount
				'wc-pending', 
                'wc-processing', 
                'wc-on-hold', 
                'wc-completed', 
                #'wc-cancelled',
                'wc-refunded',
                #'wc-failed', 
                '-'
            )
	group by 1,2) period_sales_report on (period_sales_report.product_id = p.ID or period_sales_report.variation_id = p.ID)
where post_type like 'product%' and pt.id is null
order by total_qty_sold desc;