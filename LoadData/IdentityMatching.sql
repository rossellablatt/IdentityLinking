
select
  c.customer_key
, c.customer_id
, c.customer_first_name
, c.customer_middle_name
, c.customer_last_name
, c.customer_signup_date_key
, c.customer_city
, c.customer_zip
, c.customer_state
, c.customer_corridor_key
, c.customer_kyc_status
, c.customer_date_of_birth_date_key
, c.customer_inferred_source
, c.customer_mobile_number
, c.customer_email
, c.customer_geo_location_country
, c.customer_address_line_1
, c.customer_address_line_2
, c.customer_address_city
, c.customer_address_state
, c.customer_normalized_address_line_1
, c.customer_normalized_address_latitude
, c.customer_normalized_address_longitude
, t.transaction_fee_discount -- different from 0 when discount?
, t.transaction_fee_discount
, t.transaction_kount_geo_key
, t.transaction_kount_device_key
, rec.receiver_key
, rec.receiver_mobile_number
, rec.receiver_first_name
, rec.receiver_last_name
, r.delivery_type
, r.device_1
, r.l4ssn
, r.rec_name -- receiver "first name last name"
, r.sum_all_promo_discount
, r.remitly_fraud_model_score
from customer_dimension c
     join transactions t on c.customer_key = t.transaction_customer_key
     join receiver_dimension rec ON t.transaction_receiver_key = rec.receiver_key
     join risk_rule_management r on r.transaction_id = t.transaction_id
where t.transaction_created_pacific_datetime >= '2016-01-01'
and t.transaction_created_pacific_datetime < '2016-02-01'