SELECT
--環境条件
	dc.YMD_DATE as ymd_date,
	dc.DAY_OF_WEEK as day_of_week,
--ストア条件
    ri.store_id as store_id,
	ds.long_catalog_name as long_catalog_name,
	ds.mrating_excellent as mrating_excellent,
	ds.mrating_good as mrating_good,
	ds.mrating_ok as mrating_ok,
	ds.mrating_bad as mrating_bad,
	ds.mrating_awful as mrating_awful,
	ds.best_store as best_store,
	ds.store_introduction as store_introduction,
	ds.store_category1 as store_category1,
	ds.store_category2 as store_category2,
	ds.store_category3 as store_category3,
	ds.store_review_rate as store_review_rate,
	ds.pmall_status as pmall_status,
--商品条件
    ri.item_code as item_code,
    ri.item_type as item_type,
    ri.item_name as item_name,
    ri.original_price as original_price, -- メーカー希望小売価格
    ri.price as original_pricetax, -- 通常販売価格
    ri.headline as headline,
    ri.brand_code as brand_code,
    ri.delivery_type as delivery_type,
    ri.product_category_id as product_category_id,
    d_category.gpath1 as gpath1,
    d_category.gpath2 as gpath2,
    d_category.gpath3 as gpath3,
    d_category.gpath4 as gpath4,
    d_category.gpath5 as gpath5,
    ri.spec1 as spec1,
    ri.spec1 as spec2,
    ri.spec1 as spec3,
    ri.spec1 as spec4,
    ri.spec1 as spec5,
    ri.spec1 as spec6,
    ri.spec1 as spec7,
    ri.spec1 as spec8,
    ri.spec1 as spec9,
    ri.show_stock_type as show_stock_type,
    ri.final_pr_rate as final_pr_rate,
    ri.total_brand_id as brand_id,
    ri.total_jan_code as jan_code,
    ri.y_shopping_display_flag as y_shopping_display_flag,
    wish.wish_count as wish_count,
    0 as discount_rate -- ここに割引率を入れる
    -- 学習データではここに正解販売数が入る

FROM
    shopping.shp_r_item as ri

LEFT OUTER JOIN
--ストアIDと商品IDごとの、お気に入りに入れられている数
    (
    SELECT
        in_fav.store_id as store_id, in_fav.item_code as item_code, count(*) as wish_count
    FROM
        shopping.shp_r_favorite_item_manage as in_fav
    WHERE
        store_id='{store_id}' AND-- like moonstar
        temp_delete_flag=0 AND
        delete_flag=0
    GROUP BY
        in_fav.store_id, in_fav.item_code
    ) as wish
ON
    ri.store_id = wish.store_id
    AND
    ri.item_code = wish.item_code

LEFT OUTER JOIN
	shopping.shp_d_store as ds
ON
	ri.store_id = ds.store_account

LEFT OUTER JOIN
    shopping.shp_d_category as d_category
ON
    ri.product_category_id = d_category.product_category_id

CROSS JOIN
--日付と曜日をつけるためだけ
    shopping.shp_d_calendar as dc

WHERE
    ri.store_id = '{store_id}' AND-- like moonstar
    ri.delete_flag=0 AND
    ri.display_flag=1 AND
	dc.YMD_DATE BETWEEN '{start_date}' AND '{end_date}' -- like 20200303 - 20200310
;