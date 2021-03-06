SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE view employee_attendance
AS 
SELECT 	*
FROM 	oritms_trng.dbo.employee_attendance

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
create view employee_badge 
as select * from oritms_trng.dbo.employee_badge

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE view employee_schedule
AS
SELECT * 
FROM	oritms_trng.dbo.employee_schedule

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
create view employee_trxldg 
as select * from oritms_trng.dbo.employee_trxldg

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
create view OT_REQUISITION
AS 
SELECT 	*
FROM 	oritms_trng.dbo.OT_REQUISITION

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
create view replacement_dt as
select * from oritms_trng.dbo.replacement_dt

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
create view schedule_type as 
select * from oritms_trng.dbo.schedule_type

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE VIEW v_employee_schedule
as 
select 	* 
from 	oritms_trng.dbo.v_employee_schedule

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE VIEW [dbo].[V_EMPLOYEE_TRXLDG] AS
SELECT ID, BADGE_NO, EMPLOYEE_NO, TRX_DATE, TRX_TYPE, TRX_CODE, RATE, QTY, AMOUNT, POSTED_STATUS,
       CREATED_BY,CREATED_DATE,MODIFIED_BY, MODIFIED_DATE, OPTION_FLAG
FROM 	oritms_trng.dbo.EMPLOYEE_TRXLDG

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
create view v_holiday_tms as
select * from oritms_trng.dbo.HOLIDAY

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE VIEW V_MY_EA_EXEMPTED_AMOUNT
(YEAR, EMPLOYEE_ID, EMPLOYEE_NO, EA_LINENO, EXEMPTED_AMOUNT)
AS
SELECT	T.YEAR,
		T.EMPLOYEE_ID,
		T.EMPLOYEE_NO,		
		T.EA_LINENO,
		SUM(CASE WHEN (T.YEARLY_LIMIT - T.PRE_USAGE) < 0 
			THEN 0 
			ELSE 
				CASE WHEN (T.YEARLY_LIMIT - T.PRE_USAGE) - T.YEARLY_AMOUNT >= 0 
				THEN T.YEARLY_AMOUNT
				ELSE
					(T.YEARLY_LIMIT - T.PRE_USAGE)
				END
			END)
		AS EXEMPTED_AMOUNT
FROM
(
SELECT	V.YEAR,	
		V.EMPLOYEE_ID,
		V.EMPLOYEE_NO,
		V.EA_LINENO,
		V.YEARLY_AMOUNT,
		V.YEARLY_LIMIT,		
ISNULL((SELECT SUM(YEARLY_AMOUNT)
	FROM V_MY_EA_TRX_EXEMPTION VV
	WHERE	VV.YEAR = V.YEAR
		AND	VV.EMPLOYEE_NO = V.EMPLOYEE_NO
		AND VV.EXEMPTION_CODE = V.EXEMPTION_CODE
		AND VV.EA_LINENO < V.EA_LINENO
), 0) AS PRE_USAGE
FROM V_MY_EA_TRX_EXEMPTION V
)T
GROUP BY T.YEAR, T.EMPLOYEE_ID, T.EMPLOYEE_NO, T.EA_LINENO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE VIEW [dbo].[V_MY_EA_TRX_EXEMPTION]
(YEAR, EMPLOYEE_ID, EMPLOYEE_NO, EA_LINENO, EXEMPTION_CODE, YEARLY_AMOUNT, YEARLY_LIMIT)
AS
SELECT  V.YEAR, V.EMPLOYEE_ID, V.EMPLOYEE_NO, VE.EA_LINENO, I.EXEMPTION_CODE,
		SUM(V.AMOUNT) AS YEARLY_AMOUNT,
		MAX(I.VALUE) AS YEARLY_LIMIT
FROM	V_MY_PAYLDG_DETAIL V,
		MY_EA_TRX_MAPPING VE,
		INCOME_TAX_EXEMPTION I,
		ALLOWANCE A		
WHERE 	
	V.TRX_TYPE = VE.TRX_TYPE
AND V.TRX_CODE = VE.TRX_CODE
AND V.TRX_FLAG = VE.TRX_FLAG
AND (V.TRX_TYPE = 'A'
	AND V.TRX_CODE = A.ALLOWANCE_CODE
	AND V.TRX_FLAG = 'E'
)
AND I.EXEMPTION_CODE = A.EXEMPTION_CODE
AND VE.YEAR_FROM <= V.YEAR
AND (VE.YEAR_TO >= V.YEAR OR VE.YEAR_TO IS NULL)
GROUP BY V.YEAR, V.EMPLOYEE_ID, V.EMPLOYEE_NO, VE.EA_LINENO, I.EXEMPTION_CODE

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE VIEW [dbo].[V_MY_PAYLDG_DETAIL]
(	
	year_from,
	year_to,
	ea_lineno,
	ID, 
	EMPLOYEE_ID, 
	EMPLOYEE_NO, 
	MONTH, 
	YEAR,
	FREQUENCY, 
	TRX_FLAG, 
	TRX_TYPE, 
	TRX_CODE, 
	QTY, 
	RATE, 
	AMOUNT, 
	PARENT_ID, 
	TRANS_DATE, 
	RUN_SEQUENCE, 
	cost_center_code)
AS
SELECT	
		EA.year_from,
		EA.year_to,
		EA.ea_lineno,
		H.ID, 
		H.EMPLOYEE_ID, 
		H.EMPLOYEE_NO, 
		H.MONTH, 
		H.YEAR,
		H.FREQUENCY, 
		H.TRX_FLAG, 
		H.TRX_TYPE, 
		H.TRX_CODE, 
		H.QTY, 
		H.RATE, 	
		(CASE WHEN (H.TRX_TYPE IN ('D','L')) THEN h.amount * -1 ELSE h.amount END)AS AMOUNT2,
		H.PARENT_ID, 
		H.TRANS_DATE, 
		H.RUN_SEQUENCE, 
		H.cost_center_code
FROM 
		PAYLDG_DETAIL_HIS H,
		my_ea_trx_mapping ea,
		EMPLOYEE_EMPLOYMENT EE
WHERE
		H.trx_code=ea.trx_code AND
		H.trx_type=ea.trx_type AND
		H.trx_flag=ea.trx_flag AND
		EE.EMPLOYEE_ID = H.EMPLOYEE_ID

UNION ALL

SELECT	
		EA.year_from,
		EA.year_to,
		EA.ea_lineno,
		M.ID, 
		M.EMPLOYEE_ID, 
		M.EMPLOYEE_NO, 
		M.MONTH, 
		(SELECT CASE WHEN (M.MONTH = 1 AND GS.CLOSED_MONTH = 12) THEN GS.CLOSED_YEAR + 1 ELSE GS.CLOSED_YEAR END 
			FROM GENERAL_SPECIFICATION GS WHERE GS.COMPANY_CODE = EE.COMPANY_CODE 
		) AS YEAR,
		M.FREQUENCY, 
		M.TRX_FLAG, 
		M.TRX_TYPE, 
		M.TRX_CODE, 
		M.QTY, 
		M.RATE, 
		(CASE WHEN (M.TRX_TYPE IN ('D','L')) THEN M.amount * -1 ELSE M.amount END)AS AMOUNT2,
		M.PARENT_ID, 
		M.TRANS_DATE, 
		M.RUN_SEQUENCE, 
		M.cost_center_code
FROM 
		PAYLDG_DETAIL_MTH M,
		EMPLOYEE_EMPLOYMENT EE,
		my_ea_trx_mapping ea
WHERE 
		EE.EMPLOYEE_ID = M.EMPLOYEE_ID AND
		m.trx_code=ea.trx_code AND
		m.trx_type=ea.trx_type AND
		m.trx_flag=ea.trx_flag

UNION ALL

SELECT	
		EA.year_from,
		EA.year_to,
		EA.ea_lineno,
		M.ID, 
		M.EMPLOYEE_ID, 
		M.EMPLOYEE_NO, 
		month(M.posting_date) as month, 
		year(M.posting_date) AS YEAR,
		2 as frequency, 
		'E' as trx_flag, 
		'CLM' as trx_type, 
		M.claim_CODE as trx_code, 
		1 as qty, 
		1 as rate, 
		M.claim_amount AS AMOUNT2,
		0 as parent_id, 
		M.posting_DATE, 
		1 as run_sequence, 
		M.cost_center
FROM 
		CLAIM_TRANS M,
		EMPLOYEE_EMPLOYMENT EE,
		my_ea_trx_mapping ea
WHERE 
		EE.EMPLOYEE_ID = M.EMPLOYEE_ID AND
		m.claim_code=ea.trx_code AND
		ea.trx_type='CLM' AND
		ea.trx_flag='E'

UNION ALL

SELECT	
		EA.year_from,
		EA.year_to,
		EA.ea_lineno,
		M.ID, 
		M.EMPLOYEE_ID, 
		M.EMPLOYEE_NO, 
		month(M.posting_date) as month, 
		year(M.posting_date) AS YEAR,
		2 as frequency, 
		'E' as trx_flag, 
		'CLM' as trx_type, 
		M.claim_CODE as trx_code, 
		1 as qty, 
		1 as rate, 
		M.claim_amount AS AMOUNT2,
		0 as parent_id, 
		M.posting_DATE, 
		1 as run_sequence, 
		M.cost_center
FROM 
		CLAIM_TRANS_HIS M,
		EMPLOYEE_EMPLOYMENT EE,
		my_ea_trx_mapping ea
WHERE 
		EE.EMPLOYEE_ID = M.EMPLOYEE_ID AND
		m.claim_code=ea.trx_code AND
		ea.trx_type='CLM' AND
		ea.trx_flag='E'

SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE VIEW v_training_budget as
  SELECT hd.reference_no as reference_no,   
         hd.budget_desc as budget_desc,  
			v.employee_id as employee_id,
			'*' c1, 
			'*' c2, 
			convert(datetime,NULL) c3,
			convert(datetime,NULL) c4,
			0.00 c5,
			hd.year,
  			dt.item_code AS course_code,  
		   hd.budget_amount as budget_amount
    FROM tn_budget_dt dt,   
         tn_budget_hd hd,
			v_employee_binder v
   WHERE	( v.refer_id = hd.id ) and
			( v.refer_type = 'BTN' ) and
			( dt.item_type = 'C' ) and 
			( hd.id *= dt.refer_id ) and
			( dt.item_code	 not in ( select distinct b.course_code from employee_training b
							 where b.attented_status <> 'O' and
									 hd.year = convert(numeric(4),convert(char(4),b.start_date,112)) and
									 v.employee_id = b.employee_id ))


SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON

CREATE VIEW [dbo].[VNET_EMPLOYEE_RELATION]
(ID, EMPLOYEE_ID, RELATION_NAME, PARENT_ID, NATIONAL_ID1, 
 NATIONAL_ID2, NATIONAL_ID3, RELATION_CODE, MAIL_ADDRESS1, MAIL_ADDRESS2, 
 MAIL_ADDRESS3, MAIL_POST_CODE, MAIL_AREA_CODE, MAIL_STATE_CODE, MAIL_COUNTRY_CODE, 
 MEDIA_CONTACT1, MEDIA_CONTACT2, MEDIA_CONTACT3, BIRTH_DATE, SEX, 
 OCCUPATION, WORKING_FLAG, INCOME, INCOME_TAX_NO, MARITAL_STATUS, 
 MARRIED_DATE, EDUCATION_LEVEL, HANDICAPPED, TAX_COUNT, CREATED_BY, 
 CREATED_DATE, MODIFIED_BY, MODIFIED_DATE, AGENTID, MONITOR_ID, 
 WF_REMARKS, WF_STATUS, WF_MODE, ITEM_ID, DATASET, 
 WF_POSTED, RELATIVE_ID, NATIONAL_ID3_EXPIRE, SAME_ENTITY, SEQ_NO, 
 NATIONALITY_CODE)
AS
SELECT 	inter_employee_relation.id,
 	inter_employee_relation.employee_id,
 	inter_employee_relation.relation_name,
 	inter_employee_relation.parent_id,
 	inter_employee_relation.national_id1,
 	inter_employee_relation.national_id2,
 	inter_employee_relation.national_id3,
 	inter_employee_relation.relation_code,
 	inter_employee_relation.mail_address1,
 	inter_employee_relation.mail_address2,
 	inter_employee_relation.mail_address3,
 	inter_employee_relation.mail_post_code,
 	inter_employee_relation.mail_area_code,
 	inter_employee_relation.mail_state_code,
 	inter_employee_relation.mail_country_code,
 	inter_employee_relation.media_contact1,
 	inter_employee_relation.media_contact2,
 	inter_employee_relation.media_contact3,
 	inter_employee_relation.birth_date,
 	inter_employee_relation.sex,
 	inter_employee_relation.occupation,
 	inter_employee_relation.working_flag,
 	inter_employee_relation.income,
 	inter_employee_relation.income_tax_no,
 	inter_employee_relation.marital_status,
 	inter_employee_relation.married_date,
 	inter_employee_relation.education_level,
 	inter_employee_relation.handicapped,
 	inter_employee_relation.tax_count,
 	inter_employee_relation.created_by,
 	inter_employee_relation.created_date,
 	inter_employee_relation.modified_by,
 	inter_employee_relation.modified_date,
 	inter_employee_relation.agentid,
 	inter_employee_relation.monitor_id,
 	inter_employee_relation.wf_remarks,
 	inter_employee_relation.wf_status,
 	inter_employee_relation.wf_mode,
 	inter_employee_relation.item_id,
 	inter_employee_relation.dataset,
 	inter_employee_relation.wf_posted,
   	(select x.item_id from inter_employee_relation x where x.agentid = inter_employee_relation.agentid and x.monitor_id = 0 and x.agentid <>0) as relative_id,
	inter_employee_relation.national_id3_expire,
	inter_employee_relation.same_entity,
	inter_employee_relation.seq_no,
        inter_employee_relation.nationality_code
FROM 	inter_employee_relation, 				employee_employment
where 	inter_employee_relation.employee_id = employee_employment.employee_id
and 	employee_employment.employee_status = 'A'
and     	(( inter_employee_relation.wf_status = 'V' and inter_employee_relation.id =
	( select max( x.id) from inter_employee_relation x where x.item_id =
	inter_employee_relation.item_id and x.employee_id = inter_employee_relation.employee_id ))
	OR
          	( inter_employee_relation.wf_status in('P','A','R','T')))
union
SELECT 	employee_relation.id,
 	employee_relation.employee_id,
 	employee_relation.relation_name,
 	employee_relation.parent_id,
 	employee_relation.national_id1,
 	employee_relation.national_id2,
 	employee_relation.national_id3,
 	employee_relation.relation_code,
 	employee_relation.mail_address1,
 	employee_relation.mail_address2,
 	employee_relation.mail_address3,
 	employee_relation.mail_post_code,
 	employee_relation.mail_area_code,
 	employee_relation.mail_state_code,
 	employee_relation.mail_country_code,
 	employee_relation.media_contact1,
 	employee_relation.media_contact2,
 	employee_relation.media_contact3,
 	employee_relation.birth_date,
 	employee_relation.sex,
 	employee_relation.occupation,
 	employee_relation.working_flag,
 	employee_relation.income,
 	employee_relation.income_tax_no,
 	employee_relation.marital_status,
 	employee_relation.married_date,
 	employee_relation.education_level,
 	employee_relation.handicapped,
 	employee_relation.tax_count,
 	employee_relation.created_by,
 	employee_relation.created_date,
 	employee_relation.modified_by,
 	employee_relation.modified_date,
 	0,
 	-1,
   N'',
 	'O',
 	'',
 	employee_relation.id,
 	NULL,
 	'',
   	0,
	employee_relation.national_id3_expire,
	employee_relation.same_entity,
	employee_relation.seq_no,
	employee_relation.nationality_code
FROM 	employee_relation, 				employee_employment
where 	employee_relation.employee_id = employee_employment.employee_id
and 	employee_employment.employee_status = 'A'

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON

CREATE VIEW [dbo].[VNET_EMPLOYEE_SUPERIOR]
(
EMPLOYEE_ID,
EMPLOYEE_NO,
EMPLOYEE_NAME,
EMPLOYEE_STATUS,
SUPERIOR_ID,
SUPERIOR_NO,
SUPERIOR_NAME,
SUPERIOR_STATUS,
SUPERIOR_SEQNO,
LOCATION_ID,
CREATED_BY,
CREATED_DATE,
MODIFIED_BY,
MODIFIED_DATE
) AS
SELECT 	
	b.EMPLOYEE_ID,
	b.EMPLOYEE_NO,
	b.EMPLOYEE_NAME,
	b.EMPLOYEE_STATUS,
	b.SUPERIOR_ID,
	b.SUPERIOR_NO,
	b.SUPERIOR_NAME,
	b.SUPERIOR_STATUS,
	b.SUPERIOR_SEQNO,
	b.LOCATION_ID,
	b.CREATED_BY,
	b.CREATED_DATE,
	b.MODIFIED_BY,
	b.MODIFIED_DATE
FROM 	employee_superior b
UNION
SELECT 	
a.employee_id as employee_id,
a.employee_no as employee_no,
a.employee_name as employee_name,
b.employee_status as employee_status,
b.superior_id as superior_id,
c.employee_no as superior_no,
c.employee_name as superior_name,
d.employee_status as superior_status,
1 as superior_seqno,
b.location_id as location_id,
b.created_by as created_by,
b.created_date as created_date,
b.modified_by as modified_by,
b.modified_date as modified_date
FROM 	employee_biodata a, 	employee_employment b,
	employee_biodata c, 	employee_employment d
WHERE ( b.employee_status = 'A' )
	AND 	( a.employee_id = b.employee_id )
	AND 	( b.superior_id = c.employee_id)
	AND 	( c.employee_id = d.employee_id)
	AND 	( NOT EXISTS( SELECT 1 FROM EMPLOYEE_SUPERIOR t where t.employee_id = a.employee_id AND t.superior_id = b.superior_id))

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON

CREATE VIEW [dbo].[VNET_WFA_LIST]
(ID, REQUESTOR_ID, ACCOUNT_ID, AGENTID, WF_MODE, 
 WF_REMARKS, WF_STATUS, CREATED_BY, CREATED_DATE, MODIFIED_BY, 
 MODIFIED_DATE, EMPLOYEE_NO, EMPLOYEE_NAME, DATASET, MONITOR_ID, 
 MONITOR_ITEMS, PENDING_ITEMS, RECIPIENT_ITEMS, RECIPIENT_ID, PCDS)
AS
select 	distinct a.id,
   	a.requestor_id,
   	a.account_id,
   	a.agentid,
   	a.wf_mode,
   	a.remarks,
    	a.wf_status,
   	a.created_by,
   	a.created_date,
   	a.modified_by,
   	a.modified_date,
   	b.employee_no,
   	b.employee_name,
   	a.dataset,
   	d.monitor_id,
   	( select count(id) from inter_employee_leave_info x
         	where x.monitor_id = d.monitor_id and x.wf_status in ('P','A','R') and x.wf_referid=a.id),
   	( select count(id) from inter_employee_leave_info x
         	where x.monitor_id = d.monitor_id and x.wf_status = 'P' and x.wf_referid=a.id),
   	( select count(id) from wf_recipient x
         	where x.action_status='P' and x.monitor_id = d.monitor_id and x.entity_id = c.entity_id),
   	c.entity_id,
      	'FlowLeaveIM/IMUserLeaveRFA'
from 	user_leave_application_hd a, 	employee_biodata b,
	wf_recipient c, 			inter_employee_leave_info d
where 	( a.wf_status = 'P' )
and   	( ( select max( x.monitor_id) from inter_employee_leave_info x
           	where x.monitor_id > 0 and x.wf_status = 'P' and x.wf_referid=a.id) > 0 )
and   	( c.monitor_id > 0 )
and    	( c.action_status = 'P' )
and    	( a.requestor_id = b.employee_id)
and   	( c.monitor_id = d.monitor_id and d.wf_referid = a.id)
union
select 	distinct a.id,
   	a.requestor_id,
   	a.account_id,
   	a.agentid,
   	a.wf_mode,
   	a.remarks,
    	a.wf_status,
   	a.created_by,
   	a.created_date,
   	a.modified_by,
    	a.modified_date,
   	b.employee_no,
   	b.employee_name ,
    	a.dataset,
   	d.monitor_id,
   	( select count(id) from inter_employee_training x
         	where x.monitor_id = d.monitor_id and x.wf_status in ('P','A','R') and x.wf_referid=a.id),
   	( select count(id) from inter_employee_training x
         	where x.monitor_id = d.monitor_id and x.wf_status = 'P' and x.wf_referid=a.id),
   	( select count(id) from wf_recipient x
         	where x.action_status='P' and x.monitor_id = d.monitor_id and x.entity_id = c.entity_id),
   	c.entity_id,
      	'FlowTrainIM/IMUserTrainRFA'
from 	user_training_nomination_hd a, 	employee_biodata b,
	wf_recipient c, 			inter_employee_training d
where 	( a.wf_status = 'P' )
and   	( ( select max( x.monitor_id) from inter_employee_training x
	where x.monitor_id > 0 and x.wf_status = 'P' and x.wf_referid=a.id) > 0 )
and   	( c.monitor_id > 0 )
and    	( c.action_status = 'P' )
and    	( a.requestor_id = b.employee_id )
and   	( c.monitor_id = d.monitor_id )
and	( d.wf_referid = a.id )
union
select 	distinct a.id,
   	e.requestor_id,
   	e.account_id,
   	a.agentid,
   	a.wf_mode,
   	a.remarks,
    	a.wf_status,
   	a.created_by,
   	a.created_date,
   	a.modified_by,
    	a.modified_date,
   	b.employee_no,
   	b.employee_name ,
    	a.dataset,
   	d.monitor_id,
   	( select count(id) from inter_employee_leave_cancel x
         	where x.monitor_id = d.monitor_id and x.wf_status in ('P','A','R') and x.wf_referid=a.id),
   	( select count(id) from inter_employee_leave_cancel x
         	where x.monitor_id = d.monitor_id and x.wf_status = 'P' and x.wf_referid=a.id),
   	( select count(id) from wf_recipient x
         	where x.action_status='P' and x.monitor_id = d.monitor_id and x.entity_id = c.entity_id),
   	c.entity_id,
      	'FlowLeaveIM/IMUserLeaveRFA'
from 	inter_employee_leave_cancel a,	employee_biodata b,
	wf_recipient c,			inter_employee_leave_cancel d,
      	user_leave_cancellation_hd e
where 	( a.wf_status = 'P' )
and	( ( select max( x.monitor_id) from inter_employee_leave_cancel x
           	where x.monitor_id > 0 and x.wf_status = 'P' and x.wf_referid=e.id) > 0)
and	( a.id = (select max(y.id) from inter_employee_leave_cancel y
	where y.monitor_id > 0 and y.wf_status = 'P' and y.wf_referid=e.id))
and	( c.monitor_id > 0 )
and	( c.action_status = 'P' )
and	( e.id = a.wf_referid )
and	( a.id = d.id )
and    	( b.employee_id = e.requestor_id )
and   	( c.monitor_id = d.monitor_id and d.wf_referid = e.id)
union
select	distinct a.id,
   	a.requestor_id,
   	a.account_id,
   	a.agentid,
   	a.wf_mode,
   	a.remarks,
    	a.wf_status,
   	a.created_by,
   	a.created_date,
   	a.modified_by,
   	a.modified_date,
   	b.employee_no,
   	b.employee_name,
   	a.dataset,
   	d.monitor_id,
   	( select count(id) from inter_claim_trans x
         	where x.monitor_id = d.monitor_id and x.wf_status in ('P','A','R') and x.wf_referid=a.id),
   	( select count(id) from inter_claim_trans x
         	where x.monitor_id = d.monitor_id and x.wf_status = 'P' and x.wf_referid=a.id),
   	( select count(id) from wf_recipient x
         	where x.action_status='P' and x.monitor_id = d.monitor_id and x.entity_id = c.entity_id),
   	c.entity_id,
      	'FlowClaimIM/IMUserClaimRFA'
from 	user_claim_application_hd a, 	employee_biodata b,
	wf_recipient c, 			inter_claim_trans d
where 	( a.wf_status = 'P' )
and   	( (select max( x.monitor_id ) from inter_claim_trans x
	where x.monitor_id > 0 and x.wf_status = 'P' and x.wf_referid=a.id) > 0 )
and   	( c.monitor_id > 0 )
and    	( c.action_status = 'P' )
and    	( a.requestor_id = b.employee_id )
and   	( c.monitor_id = d.monitor_id and d.wf_referid = a.id )
and	( d.dataset = 'claimapplication' )
union
select	distinct a.id,
   	a.requestor_id,
   	a.account_id,
   	a.agentid,
   	a.wf_mode,
   	a.remarks,
    	a.wf_status,
   	a.created_by,
   	a.created_date,
   	a.modified_by,
   	a.modified_date,
   	b.employee_no,
   	b.employee_name,
   	a.dataset,
   	d.monitor_id,
   	( select count(id) from inter_claim_trans x
         	where x.monitor_id = d.monitor_id and x.wf_status in ('P','A','R') and x.wf_referid=a.id),
   	( select count(id) from inter_claim_trans x
         	where x.monitor_id = d.monitor_id and x.wf_status = 'P' and x.wf_referid=a.id),
   	( select count(id) from wf_recipient x
        	where x.action_status='P' and x.monitor_id = d.monitor_id and x.entity_id = c.entity_id),
   	c.entity_id,
      	'FlowClaimIM/IMUserClaimRFA'
from 	user_claim_application_hd a, 	employee_biodata b,
	wf_recipient c, 			inter_claim_trans d
where	( a.wf_status = 'P' )
and   	( (select max( x.monitor_id ) from inter_claim_trans x
	where x.monitor_id > 0 and x.wf_status = 'P' and x.wf_referid=a.id) > 0 )
and   	( c.monitor_id > 0 )
and    	( c.action_status = 'P' )
and    	( a.requestor_id = b.employee_id )
and   	( c.monitor_id = d.monitor_id and d.wf_referid = a.id )
and	( d.dataset <> 'claimapplication' )
union
select  distinct a.id,
      d.requestor_id,
      b.employee_id,
      a.agentid,
      a.wf_mode,
      d.remarks,
      a.wf_status,
      a.created_by,
      a.created_date,
      a.modified_by,
      a.modified_date,
      b.employee_no,
      b.employee_name ,
      a.dataset,
      a.monitor_id,
   	( select count(id) from inter_rc_rf_jobspec x
         	where x.monitor_id = a.monitor_id and x.wf_status in ('P','A','R') and x.wf_referid=d.id),
   	( select count(id) from inter_rc_rf_jobspec x
         	where x.monitor_id = a.monitor_id and x.wf_status = 'P' and x.wf_referid=d.id),
   	( select count(id) from wf_recipient x
        	where x.action_status='P' and x.monitor_id = a.monitor_id and x.entity_id = c.entity_id),
      c.entity_id,
      'FlowResIM/IMUserResourceRFA'
  from inter_rc_rf_jobspec a, employee_biodata b, wf_recipient c, inter_rc_rf_hd d
where ( a.wf_status = 'P' ) and
      ( d.requestor_id = b.employee_id ) and
      ( c.monitor_id = a.monitor_id ) and
      ( c.monitor_id > 0  ) and
      ( c.action_status = 'P' ) and
      ( a.monitor_id > 0 ) and
      ( d.id = a.refer_id ) and
      ( a.item_id = (select max( x.item_id) from inter_rc_rf_jobspec x
                      where x.monitor_id = a.monitor_id and x.wf_status = 'P') )
union
select  distinct a.id,
      d.requestor_id,
      b.employee_id,
      a.agentid,
      a.wf_mode,
      d.remarks,
      a.wf_status,
      a.created_by,
      a.created_date,
      a.modified_by,
      a.modified_date,
      b.employee_no,
      b.employee_name ,
      a.dataset,
      a.monitor_id,
   	( select count(id) from inter_rc_ro_dt x
         	where x.monitor_id = a.monitor_id and x.wf_status in ('P','A','R') and x.wf_referid=d.id),
   	( select count(id) from inter_rc_ro_dt x
         	where x.monitor_id = a.monitor_id and x.wf_status = 'P' and x.wf_referid=d.id),
   	( select count(id) from wf_recipient x
        	where x.action_status='P' and x.monitor_id = a.monitor_id and x.entity_id = c.entity_id),
      c.entity_id,
      'FlowResIM/IMUserResourceRFA'
  from inter_rc_ro_dt a, employee_biodata b, wf_recipient c, inter_rc_ro_hd d
where ( a.wf_status = 'P' ) and
      ( d.requestor_id = b.employee_id ) and
      ( c.monitor_id = a.monitor_id ) and
      ( c.monitor_id > 0 ) and
      ( c.action_status = 'P' ) and
      ( a.monitor_id > 0 ) and
      ( d.id = a.wf_referid ) and
      ( a.item_id = (select max( x.item_id) from inter_rc_ro_dt x
                      where x.monitor_id = a.monitor_id and x.wf_status = 'P') )
union
select	distinct a.id,
   	a.requestor_id,
   	a.account_id,
   	a.agentid,
   	a.wf_mode,
   	a.remarks,
    	a.wf_status,
   	a.created_by,
   	a.created_date,
   	a.modified_by,
   	a.modified_date,
   	b.employee_no,
   	b.employee_name,
   	a.dataset,
   	d.monitor_id,
   	( select count(id) from inter_loan_car x
         	where x.monitor_id = d.monitor_id and x.wf_status in ('P','A','R') and x.wf_referid=a.id),
   	( select count(id) from inter_loan_car x
         	where x.monitor_id = d.monitor_id and x.wf_status = 'P' and x.wf_referid=a.id),
   	( select count(id) from wf_recipient x
         	where x.action_status='P' and x.monitor_id = d.monitor_id and x.entity_id = c.entity_id),
   	c.entity_id,
      	'FlowLoanIM/IMUserLoanRFA'
from 	user_loan_application_hd a, 	employee_biodata b,
	wf_recipient c, 		inter_loan_car d
where 	( a.wf_status = 'P' )
and   	( (select max( x.monitor_id ) from inter_loan_car x
	where x.monitor_id > 0 and x.wf_status = 'P' and x.wf_referid=a.id) > 0 )
and   	( c.monitor_id > 0 )
and    	( c.action_status = 'P' )
and    	( a.requestor_id = b.employee_id )
and   	( c.monitor_id = d.monitor_id and d.wf_referid = a.id )
union
select	distinct a.id,
   	a.requestor_id,
   	a.account_id,
   	a.agentid,
   	a.wf_mode,
   	a.remarks,
    	a.wf_status,
   	a.created_by,
   	a.created_date,
   	a.modified_by,
   	a.modified_date,
   	b.employee_no,
   	b.employee_name,
   	a.dataset,
   	d.monitor_id,
   	( select count(id) from inter_loan_motorcycle x
         	where x.monitor_id = d.monitor_id and x.wf_status in ('P','A','R') and x.wf_referid=a.id),
   	( select count(id) from inter_loan_motorcycle x
         	where x.monitor_id = d.monitor_id and x.wf_status = 'P' and x.wf_referid=a.id),
   	( select count(id) from wf_recipient x
         	where x.action_status='P' and x.monitor_id = d.monitor_id and x.entity_id = c.entity_id),
   	c.entity_id,
      	'FlowLoanIM/IMUserLoanRFA'
from 	user_loan_application_hd a, 	employee_biodata b,
	wf_recipient c, 		inter_loan_motorcycle d
where 	( a.wf_status = 'P' )
and   	( (select max( x.monitor_id ) from inter_loan_motorcycle x
	where x.monitor_id > 0 and x.wf_status = 'P' and x.wf_referid=a.id) > 0 )
and   	( c.monitor_id > 0 )
and    	( c.action_status = 'P' )
and    	( a.requestor_id = b.employee_id )
and   	( c.monitor_id = d.monitor_id and d.wf_referid = a.id )
union
select	distinct a.id,
   	a.requestor_id,
   	a.account_id,
   	a.agentid,
   	a.wf_mode,
   	a.remarks,
    	a.wf_status,
   	a.created_by,
   	a.created_date,
   	a.modified_by,
   	a.modified_date,
   	b.employee_no,
   	b.employee_name,
   	a.dataset,
   	d.monitor_id,
   	( select count(id) from inter_loan_housing x
         	where x.monitor_id = d.monitor_id and x.wf_status in ('P','A','R') and x.wf_referid=a.id),
   	( select count(id) from inter_loan_housing x
         	where x.monitor_id = d.monitor_id and x.wf_status = 'P' and x.wf_referid=a.id),
   	( select count(id) from wf_recipient x
         	where x.action_status='P' and x.monitor_id = d.monitor_id and x.entity_id = c.entity_id),
   	c.entity_id,
      	'FlowLoanIM/IMUserLoanRFA'
from 	user_loan_application_hd a, 	employee_biodata b,
	wf_recipient c, 		inter_loan_housing d
where 	( a.wf_status = 'P' )
and   	( (select max( x.monitor_id ) from inter_loan_housing x
	where x.monitor_id > 0 and x.wf_status = 'P' and x.wf_referid=a.id) > 0 )
and   	( c.monitor_id > 0 )
and    	( c.action_status = 'P' )
and    	( a.requestor_id = b.employee_id )
and   	( c.monitor_id = d.monitor_id and d.wf_referid = a.id )
union
select	distinct a.id,
   	a.requestor_id,
   	a.account_id,
   	a.agentid,
   	a.wf_mode,
   	a.remarks,
    	a.wf_status,
   	a.created_by,
   	a.created_date,
   	a.modified_by,
   	a.modified_date,
   	b.employee_no,
   	b.employee_name,
   	a.dataset,
   	d.monitor_id,
   	( select count(id) from inter_loan_renovation x
         	where x.monitor_id = d.monitor_id and x.wf_status in ('P','A','R') and x.wf_referid=a.id),
   	( select count(id) from inter_loan_renovation x
         	where x.monitor_id = d.monitor_id and x.wf_status = 'P' and x.wf_referid=a.id),
   	( select count(id) from wf_recipient x
         	where x.action_status='P' and x.monitor_id = d.monitor_id and x.entity_id = c.entity_id),
   	c.entity_id,
      	'FlowLoanIM/IMUserLoanRFA'
from 	user_loan_application_hd a, 	employee_biodata b,
	wf_recipient c, 		inter_loan_renovation d
where 	( a.wf_status = 'P' )
and   	( (select max( x.monitor_id ) from inter_loan_renovation x
	where x.monitor_id > 0 and x.wf_status = 'P' and x.wf_referid=a.id) > 0 )
and   	( c.monitor_id > 0 )
and    	( c.action_status = 'P' )
and    	( a.requestor_id = b.employee_id )
and   	( c.monitor_id = d.monitor_id and d.wf_referid = a.id )
union
select	distinct a.id,
   	a.requestor_id,
   	a.account_id,
   	a.agentid,
   	a.wf_mode,
   	a.remarks,
    	a.wf_status,
   	a.created_by,
   	a.created_date,
   	a.modified_by,
   	a.modified_date,
   	b.employee_no,
   	b.employee_name,
   	a.dataset,
   	d.monitor_id,
   	( select count(id) from inter_loan_study x
         	where x.monitor_id = d.monitor_id and x.wf_status in ('P','A','R') and x.wf_referid=a.id),
   	( select count(id) from inter_loan_study x
         	where x.monitor_id = d.monitor_id and x.wf_status = 'P' and x.wf_referid=a.id),
   	( select count(id) from wf_recipient x
         	where x.action_status='P' and x.monitor_id = d.monitor_id and x.entity_id = c.entity_id),
   	c.entity_id,
      	'FlowLoanIM/IMUserLoanRFA'
from 	user_loan_application_hd a, 	employee_biodata b,
	wf_recipient c, 		inter_loan_study d
where 	( a.wf_status = 'P' )
and   	( (select max( x.monitor_id ) from inter_loan_study x
	where x.monitor_id > 0 and x.wf_status = 'P' and x.wf_referid=a.id) > 0 )
and   	( c.monitor_id > 0 )
and    	( c.action_status = 'P' )
and    	( a.requestor_id = b.employee_id )
and   	( c.monitor_id = d.monitor_id and d.wf_referid = a.id )
union
select	distinct a.id,
   	a.requestor_id,
   	a.account_id,
   	a.agentid,
   	a.wf_mode,
   	a.remarks,
    	a.wf_status,
   	a.created_by,
   	a.created_date,
   	a.modified_by,
   	a.modified_date,
   	b.employee_no,
   	b.employee_name,
   	a.dataset,
   	d.monitor_id,
   	( select count(id) from inter_loan_sundry x
         	where x.monitor_id = d.monitor_id and x.wf_status in ('P','A','R') and x.wf_referid=a.id),
   	( select count(id) from inter_loan_sundry x
         	where x.monitor_id = d.monitor_id and x.wf_status = 'P' and x.wf_referid=a.id),
   	( select count(id) from wf_recipient x
         	where x.action_status='P' and x.monitor_id = d.monitor_id and x.entity_id = c.entity_id),
   	c.entity_id,
      	'FlowLoanIM/IMUserLoanRFA'
from 	user_loan_application_hd a, 	employee_biodata b,
	wf_recipient c, 		inter_loan_sundry d
where 	( a.wf_status = 'P' )
and   	( (select max( x.monitor_id ) from inter_loan_sundry x
	where x.monitor_id > 0 and x.wf_status = 'P' and x.wf_referid=a.id) > 0 )
and   	( c.monitor_id > 0 )
and    	( c.action_status = 'P' )
and    	( a.requestor_id = b.employee_id )
and   	( c.monitor_id = d.monitor_id and d.wf_referid = a.id )
UNION
SELECT  distinct a.id,
   	a.requestor_id,
   	a.account_id,
   	a.agentid,
   	a.wf_mode,
   	a.remarks,
    	a.wf_status,
   	a.created_by,
   	a.created_date,
   	a.modified_by,
   	a.modified_date,
   	b.employee_no,
   	b.employee_name,
   	d.dataset,
   	d.monitor_id,
   	( select count(id) from inter_ot_requisition x
         where x.monitor_id = d.monitor_id and x.wf_status in ('P','A','R') and x.wf_referid=a.id),
   	( select count(id) from inter_ot_requisition x
         where x.monitor_id = d.monitor_id and x.wf_status = 'P' and x.wf_referid=a.id),
   	( select count(id) from wf_recipient x
         where x.action_status='P' and x.monitor_id = d.monitor_id and x.entity_id = c.entity_id),
   	c.entity_id,
      'FlowNetIM/IMUserOtr'
 FROM user_ot_application_hd a, 	employee_biodata b,
    	wf_recipient c, 		inter_ot_requisition d
WHERE ( a.wf_status = 'P' )
and   ( c.action_status = 'P' )
and 	( (select max( x.monitor_id ) from inter_ot_requisition x
	       where x.monitor_id > 0 and x.wf_status = 'P' and x.wf_referid=a.id) > 0 )
and   ( c.monitor_id > 0 )
and   ( a.requestor_id = b.employee_id)
and   ( c.monitor_id = d.monitor_id and d.wf_referid = a.id)

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE VIEW [dbo].[VNET_WFC_DONE]
(ID, REQUESTOR_ID, ACCOUNT_ID, AGENTID, WF_MODE, 
 WF_REMARKS, WF_STATUS, CREATED_BY, CREATED_DATE, MODIFIED_BY, 
 MODIFIED_DATE, EMPLOYEE_NO, EMPLOYEE_NAME, DATASET, MONITOR_ID, 
 MONITOR_ITEMS, COMPLETED_ITEMS, APPROVED_ITEMS, REJECTED_ITEMS, RECIPIENT_ITEMS, 
 RECIPIENT_ID, PCDS)
AS 
SELECT 	DISTINCT a.id,
   	a.requestor_id,
   	a.account_id,
   	a.agentid,
   	a.wf_mode,
   	a.remarks,
   	a.wf_status,
   	a.created_by,
   	a.created_date,
   	a.modified_by,
   	a.modified_date,
   	b.employee_no,
   	b.employee_name,
   	a.dataset,
   	d.monitor_id,
   	( select count(id) from inter_employee_leave_info x
         	where x.monitor_id = d.monitor_id and x.wf_status in ('P','A','R') and x.wf_referid=a.id),
   	( select count(id) from inter_employee_leave_info x
         	where x.monitor_id = d.monitor_id and x.wf_status <> 'P' and x.wf_referid=a.id),
   	( select count(id) from inter_employee_leave_info x
         	where x.monitor_id = d.monitor_id and x.wf_status = 'A' and x.wf_referid=a.id),
   	( select count(id) from inter_employee_leave_info x
         	where x.monitor_id = d.monitor_id and x.wf_status = 'R' and x.wf_referid=a.id),
   	( select count(id) from wf_recipient x
         	where x.action_status<>'P' and x.monitor_id = d.monitor_id and x.entity_id = c.entity_id),
   	c.entity_id,
      	'FlowLeaveIM/IMUserLeaveRFA'
FROM 	user_leave_application_hd a, employee_biodata b,
	   wf_recipient c, inter_employee_leave_info d
WHERE	( a.wf_status <> 'P' ) and
      ( c.id in ( select min( x.id) from wf_recipient x, wf_monitor y
         	       where x.monitor_id = y.id and
                         y.agentid = a.agentid
                   group by x.entity_id) ) and
      ( c.monitor_id > 0 ) and
      ( c.action_status <> 'P' ) and
      ( a.requestor_id = b.employee_id ) and
      ( c.monitor_id = d.monitor_id and d.wf_referid = a.id )
UNION
SELECT 	DISTINCT a.id,
	a.requestor_id,
	a.account_id,
	a.agentid,
	a.wf_mode,
	a.remarks,
	a.wf_status,
	a.created_by,
	a.created_date,
	a.modified_by,
	a.modified_date,
	b.employee_no,
	b.employee_name,
 	a.dataset,
	d.monitor_id,
	( select count(id) from inter_employee_training x
      	where x.monitor_id = d.monitor_id and x.wf_status in ('P','A','R') and x.wf_referid=a.id),
	( select count(id) from inter_employee_training x
      	where x.monitor_id = d.monitor_id and x.wf_status <> 'P' and x.wf_referid=a.id),
	( select count(id) from inter_employee_training x
      	where x.monitor_id = d.monitor_id and x.wf_status = 'A' and x.wf_referid=a.id),
	( select count(id) from inter_employee_training x
      	where x.monitor_id = d.monitor_id and x.wf_status = 'R' and x.wf_referid=a.id),
	( select count(id) from wf_recipient x
      	where x.action_status<>'P' and x.monitor_id = d.monitor_id and x.entity_id = c.entity_id),
	c.entity_id,
   	'FlowTrainIM/IMUserTrainRFA'
FROM 	user_training_nomination_hd a,	employee_biodata b,
	wf_recipient c,			inter_employee_training d
WHERE ( a.wf_status <> 'P' ) and
      ( c.id in ( select min( x.id) from wf_recipient x, wf_monitor y
         	       where x.monitor_id = y.id and
                         y.agentid = a.agentid
                   group by x.entity_id) ) and
      ( c.monitor_id > 0 ) and
      ( c.action_status <> 'P' ) and
      ( a.requestor_id = b.employee_id ) and
      ( c.monitor_id = d.monitor_id and d.wf_referid = a.id)
UNION
SELECT 	DISTINCT a.id,
   	a.requestor_id,
   	a.account_id,
   	a.agentid,
   	a.wf_mode,
   	a.remarks,
   	a.wf_status,
   	a.created_by,
   	a.created_date,
   	a.modified_by,
   	a.modified_date,
   	b.employee_no,
   	b.employee_name,
    	a.dataset,
   	d.monitor_id,
   	( select count(id) from inter_employee_leave_cancel x
         	where x.monitor_id = d.monitor_id and x.wf_status in ('P','A','R') and x.wf_referid=a.id),
   	( select count(id) from inter_employee_leave_cancel x
         	where x.monitor_id = d.monitor_id and x.wf_status <> 'P' and x.wf_referid=a.id),
	   ( select count(id) from inter_employee_leave_cancel x
         	where x.monitor_id = d.monitor_id and x.wf_status = 'A' and x.wf_referid=a.id),
	   ( select count(id) from inter_employee_leave_cancel x
         	where x.monitor_id = d.monitor_id and x.wf_status = 'R' and x.wf_referid=a.id),
   	( select count(id) from wf_recipient x
         	where x.action_status<>'P' and x.monitor_id = d.monitor_id and x.entity_id = c.entity_id),
   	c.entity_id,
      	'FlowLeaveIM/IMUserLeaveRFA'
FROM 	user_leave_cancellation_hd a,	employee_biodata b,
	wf_recipient c,			inter_employee_leave_cancel d
WHERE ( a.wf_status <> 'P' ) and
      ( c.id in ( select min( x.id) from wf_recipient x, wf_monitor y
         	       where x.monitor_id = y.id and
                         y.agentid = a.agentid
                   group by x.entity_id) ) and
    	( c.monitor_id > 0 ) and
    	( c.action_status <> 'P' ) and
    	( a.requestor_id = b.employee_id ) and
    	( c.monitor_id = d.monitor_id and d.wf_referid = a.id )
UNION
SELECT 	DISTINCT a.id,
   	a.requestor_id,
   	a.account_id,
   	a.agentid,
   	a.wf_mode,
   	a.remarks,
   	a.wf_status,
   	a.created_by,
   	a.created_date,
   	a.modified_by,
   	a.modified_date,
   	b.employee_no,
   	b.employee_name,
   	a.dataset,
   	d.monitor_id,
   	( select count(id) from inter_claim_trans x
	     where x.monitor_id = d.monitor_id and x.wf_status in ('P','A','R') and x.wf_referid=a.id),
   	( select count(id) from inter_claim_trans x
	     where x.monitor_id = d.monitor_id and x.wf_status <> 'P' and x.wf_referid=a.id),
	   ( select count(id) from inter_claim_trans x
	     where x.monitor_id = d.monitor_id and x.wf_status = 'A' and x.wf_referid=a.id),
	   ( select count(id) from inter_claim_trans x
	     where x.monitor_id = d.monitor_id and x.wf_status = 'R' and x.wf_referid=a.id),
   	( select count(id) from wf_recipient x
	     where x.action_status<>'P' and x.monitor_id = d.monitor_id and x.entity_id = c.entity_id),
   	c.entity_id,
      	'FlowClaimIM/IMUserClaimRFA'
FROM 	user_claim_application_hd a,	employee_biodata b,
   	wf_recipient c,			inter_claim_trans d
WHERE	( a.wf_status <> 'P' ) and
      ( c.id in ( select min( x.id) from wf_recipient x, wf_monitor y
         	       where x.monitor_id = y.id and
                         y.agentid = a.agentid
                   group by x.entity_id) ) and
 	  ( c.monitor_id > 0 ) and
	  ( c.action_status <> 'P' ) and
	  ( a.requestor_id = b.employee_id ) and
	  ( c.monitor_id = d.monitor_id and d.wf_referid = a.id ) and
	  ( a.dataset = 'claimapplication' )
UNION
SELECT 	DISTINCT a.id,
   	a.requestor_id,
   	a.account_id,
   	a.agentid,
   	a.wf_mode,
   	a.remarks,
   	a.wf_status,
   	a.created_by,
   	a.created_date,
   	a.modified_by,
   	a.modified_date,
   	b.employee_no,
   	b.employee_name,
   	a.dataset,
   	d.monitor_id,
   	( select count(id) from inter_claim_trans x
	     where x.monitor_id = d.monitor_id and x.wf_status in ('P','A','R') and x.wf_referid=a.id),
   	( select count(id) from inter_claim_trans x
        where x.monitor_id = d.monitor_id and x.wf_status <> 'P' and x.wf_referid=a.id),
   	( select count(id) from inter_claim_trans x
	     where x.monitor_id = d.monitor_id and x.wf_status = 'A' and x.wf_referid=a.id),
    	( select count(id) from inter_claim_trans x
        where x.monitor_id = d.monitor_id and x.wf_status = 'R' and x.wf_referid=a.id),
   	( select count(id) from wf_recipient x
        where x.action_status<>'P' and x.monitor_id = d.monitor_id and x.entity_id = c.entity_id),
   	c.entity_id,
      	'FlowClaimIM/IMUserClaimRFA'
FROM 	user_claim_application_hd a,	employee_biodata b,
   	wf_recipient c,			inter_claim_trans d
WHERE	( a.wf_status <> 'P' ) and
      ( c.id in ( select min( x.id) from wf_recipient x, wf_monitor y
         	       where x.monitor_id = y.id and
                         y.agentid = a.agentid
                   group by x.entity_id) ) and
      ( c.monitor_id > 0 ) and
      ( c.action_status <> 'P' ) and
      ( a.requestor_id = b.employee_id ) and
      ( c.monitor_id = d.monitor_id and d.wf_referid = a.id ) and
      ( a.dataset <> 'claimapplication' )
union
SELECT 	DISTINCT a.id,
	a.requestor_id,
	a.account_id,
	a.agentid,
	a.wf_mode,
	a.remarks,
	a.wf_status,
	a.created_by,
	a.created_date,
	a.modified_by,
	a.modified_date,
	b.employee_no,
	b.employee_name,
 	a.dataset,
	d.monitor_id,
	( select count(id) from inter_rc_rf_jobspec x
      	where x.monitor_id = d.monitor_id and x.wf_status in ('P','A','R') and x.wf_referid=a.id),
	( select count(id) from inter_rc_rf_jobspec x
      	where x.monitor_id = d.monitor_id and x.wf_status <> 'P' and x.wf_referid=a.id),
 	( select count(id) from inter_rc_rf_jobspec x
	     where x.monitor_id = d.monitor_id and x.wf_status = 'A' and x.wf_referid=a.id),
  	( select count(id) from inter_rc_rf_jobspec x
        where x.monitor_id = d.monitor_id and x.wf_status = 'R' and x.wf_referid=a.id),
	( select count(id) from wf_recipient x
      	where x.action_status<>'P' and x.monitor_id = d.monitor_id and x.entity_id = c.entity_id),
	c.entity_id,
   	'FlowResIM/IMUserResourceRFA'
FROM 	inter_rc_rf_hd a,	employee_biodata b,
   	wf_recipient c, inter_rc_rf_jobspec d
WHERE 	( a.wf_status <> 'P' ) and
      ( c.id in ( select min( x.id) from wf_recipient x, wf_monitor y
         	       where x.monitor_id = y.id and
                         y.agentid = a.agentid
                   group by x.entity_id) ) and
    	( c.monitor_id > 0 ) and
    	( c.action_status <> 'P' ) and
    	( a.requestor_id = b.employee_id ) and
    	( c.monitor_id = d.monitor_id and d.wf_referid = a.id)
UNION
SELECT 	DISTINCT a.id,
	a.requestor_id,
	a.account_id,
	a.agentid,
	a.wf_mode,
	a.remarks,
	a.wf_status,
	a.created_by,
	a.created_date,
	a.modified_by,
	a.modified_date,
	b.employee_no,
	b.employee_name,
 	a.dataset,
	d.monitor_id,
	( select count(id) from inter_rc_ro_dt x
      	where x.monitor_id = d.monitor_id and x.wf_status in ('P','A','R') and x.wf_referid=a.id),
	( select count(id) from inter_rc_ro_dt x
      	where x.monitor_id = d.monitor_id and x.wf_status <> 'P' and x.wf_referid=a.id),
 	( select count(id) from inter_rc_ro_dt x
	     where x.monitor_id = d.monitor_id and x.wf_status = 'A' and x.wf_referid=a.id),
  	( select count(id) from inter_rc_ro_dt x
        where x.monitor_id = d.monitor_id and x.wf_status = 'R' and x.wf_referid=a.id),
	( select count(id) from wf_recipient x
      	where x.action_status<>'P' and x.monitor_id = d.monitor_id and x.entity_id = c.entity_id),
	c.entity_id,
   	'FlowResIM/IMUserResourceRFA'
FROM 	inter_rc_ro_hd a,	employee_biodata b,
   	wf_recipient c, inter_rc_ro_dt d
WHERE 	( a.wf_status <> 'P' ) and
      ( c.id in ( select min( x.id) from wf_recipient x, wf_monitor y
         	       where x.monitor_id = y.id and
                         y.agentid = a.agentid
                   group by x.entity_id) ) and
      ( c.monitor_id > 0 ) and
      ( c.action_status <> 'P' ) and
      ( a.requestor_id = b.employee_id ) and
      ( c.monitor_id = d.monitor_id and d.wf_referid = a.id)
UNION
SELECT 	DISTINCT a.id,
   	a.requestor_id,
   	a.account_id,
   	a.agentid,
   	a.wf_mode,
   	a.remarks,
   	a.wf_status,
   	a.created_by,
   	a.created_date,
   	a.modified_by,
   	a.modified_date,
   	b.employee_no,
   	b.employee_name,
   	d.dataset,
   	d.monitor_id,
   	( select count(id) from inter_ot_requisition x
         where x.monitor_id = d.monitor_id and x.wf_status in ('P','A','R') and x.wf_referid=a.id),
   	( select count(id) from inter_ot_requisition x
         where x.monitor_id = d.monitor_id and x.wf_status <> 'P' and x.wf_referid=a.id),
    	( select count(id) from inter_ot_requisition x
	      where x.monitor_id = d.monitor_id and x.wf_status = 'A' and x.wf_referid=a.id),
     	( select count(id) from inter_ot_requisition x
         where x.monitor_id = d.monitor_id and x.wf_status = 'R' and x.wf_referid=a.id),
   	( select count(id) from wf_recipient x
         where x.action_status<>'P' and x.monitor_id = d.monitor_id and x.entity_id = c.entity_id),
   	c.entity_id,
      'FlowNetIM/IMUserOtr'
FROM 	user_ot_application_hd a,		employee_biodata b,
	wf_recipient c,			inter_ot_requisition d
WHERE	( a.wf_status <> 'P' ) and
      ( c.id in ( select min( x.id) from wf_recipient x, wf_monitor y
         	       where x.monitor_id = y.id and
                         y.agentid = a.agentid
                   group by x.entity_id) ) and
      ( c.monitor_id > 0 ) and
      ( c.action_status <> 'P' ) and
      ( a.requestor_id = b.employee_id ) and
      ( c.monitor_id = d.monitor_id and d.wf_referid = a.id )

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON

CREATE VIEW [dbo].[VNET_WFC_LIST]
(ID, REQUESTOR_ID, ACCOUNT_ID, AGENTID, WF_MODE, 
 WF_REMARKS, WF_STATUS, CREATED_BY, CREATED_DATE, MODIFIED_BY, 
 MODIFIED_DATE, EMPLOYEE_NO, EMPLOYEE_NAME, DATASET, MONITOR_ID, 
 MONITOR_ITEMS, PENDING_ITEMS, COMPLETED_ITEMS, APPROVED_ITEMS, REJECTED_ITEMS, 
 RECIPIENT_ITEMS, PCDS)
AS
SELECT     a.id,
       a.requestor_id,
       a.account_id,
       a.agentid,
       a.wf_mode,
       a.remarks,
       a.wf_status,
       a.created_by,
       a.created_date,
       a.modified_by,
       a.modified_date,
       b.employee_no,
       b.employee_name,
       a.dataset,
       0,
       ( select count(id) from inter_employee_leave_info x
             where x.monitor_id = 0 and x.wf_status in ('P','A','R') and x.wf_referid=a.id),
       ( select count(id) from inter_employee_leave_info x
             where x.monitor_id = 0 and x.wf_status = 'P' and x.wf_referid=a.id),
       ( select count(id) from inter_employee_leave_info x
             where x.monitor_id = 0 and x.wf_status <> 'P' and x.wf_referid=a.id),
       ( select count(id) from inter_employee_leave_info x
             where x.monitor_id = 0 and x.wf_status = 'A' and x.wf_referid=a.id),
       ( select count(id) from inter_employee_leave_info x
             where x.monitor_id = 0 and x.wf_status = 'R' and x.wf_referid=a.id),
        0,
         'FlowLeaveIM/IMUserLeaveInfo'
FROM     user_leave_application_hd a,     employee_biodata b
WHERE ( ( select count(id) from inter_employee_leave_info x
               where x.monitor_id = 0 and x.wf_status in ('P','A','R') and x.wf_referid=a.id ) > 0 ) and
      ( a.requestor_id = b.employee_id )
UNION
SELECT     a.id,
       a.requestor_id,
       a.account_id,
       a.agentid,
       a.wf_mode,
       a.remarks,
        a.wf_status,
       a.created_by,
       a.created_date,
       a.modified_by,
       a.modified_date,
       b.employee_no,
       b.employee_name ,
       a.dataset,
       0,
       ( select count(id) from inter_employee_training x
             where x.monitor_id = 0 and x.wf_status in ('P','A','R') and x.wf_referid=a.id),
       ( select count(id) from inter_employee_training x
             where x.monitor_id = 0 and x.wf_status = 'P' and x.wf_referid=a.id),
       ( select count(id) from inter_employee_training x
             where x.monitor_id = 0 and x.wf_status <> 'P' and x.wf_referid=a.id),
       ( select count(id) from inter_employee_training x
             where x.monitor_id = 0 and x.wf_status = 'A' and x.wf_referid=a.id),
       ( select count(id) from inter_employee_training x
             where x.monitor_id = 0 and x.wf_status = 'R' and x.wf_referid=a.id),
       0,
          'FlowTrainIM/IMUserTrainInfo'
FROM     user_training_nomination_hd a, employee_biodata b
WHERE ( ( select count(id) from inter_employee_training x
               where x.monitor_id = 0 and x.wf_status in ('P','A','R') and x.wf_referid=a.id) > 0 ) and
      ( a.requestor_id = b.employee_id)
UNION
SELECT     a.id,
       a.requestor_id,
       a.account_id,
       a.agentid,
       a.wf_mode,
       a.remarks,
        a.wf_status,
       a.created_by,
       a.created_date,
       a.modified_by,
       a.modified_date,
       b.employee_no,
       b.employee_name ,
       a.dataset,
       0,
       ( select count(id) from inter_employee_leave_cancel x
             where x.monitor_id = 0 and x.wf_status in ('P','A','R') and x.wf_referid=a.id),
       ( select count(id) from inter_employee_leave_cancel x
             where x.monitor_id = 0 and x.wf_status = 'P' and x.wf_referid=a.id),
       ( select count(id) from inter_employee_leave_cancel x
             where x.monitor_id = 0 and x.wf_status <> 'P' and x.wf_referid=a.id),
       ( select count(id) from inter_employee_leave_cancel x
             where x.monitor_id = 0 and x.wf_status = 'A' and x.wf_referid=a.id),
       ( select count(id) from inter_employee_leave_cancel x
             where x.monitor_id = 0 and x.wf_status = 'R' and x.wf_referid=a.id),
       0,
          'FlowLeaveIM/IMUserLeaveInfo'
FROM     user_leave_cancellation_hd a,    employee_biodata b
WHERE ( ( select count(id) from inter_employee_leave_cancel x
               where x.monitor_id = 0 and x.wf_status in ('P','A','R') and x.wf_referid=a.id ) > 0 ) and
       ( a.requestor_id = b.employee_id)
UNION
SELECT     a.id,
       a.requestor_id,
       a.account_id,
       a.agentid,
       a.wf_mode,
       a.remarks,
       a.wf_status,
       a.created_by,
       a.created_date,
       a.modified_by,
       a.modified_date,
       b.employee_no,
       b.employee_name,
       a.dataset,
       0,
       ( select count(id) from inter_claim_trans x
             where x.monitor_id = 0 and x.wf_status in ('P','A','R') and x.wf_referid=a.id),
       ( select count(id) from inter_claim_trans x
             where x.monitor_id = 0 and x.wf_status = 'P' and x.wf_referid=a.id),
       ( select count(id) from inter_claim_trans x
             where x.monitor_id = 0 and x.wf_status <> 'P' and x.wf_referid=a.id),
       ( select count(id) from inter_claim_trans x
             where x.monitor_id = 0 and x.wf_status = 'A' and x.wf_referid=a.id),
       ( select count(id) from inter_claim_trans x
             where x.monitor_id = 0 and x.wf_status = 'R' and x.wf_referid=a.id),
        0,
          'FlowClaimIM/IMUserClaimInfo'
FROM     user_claim_application_hd a,     employee_biodata b
WHERE ( ( select count(id) from inter_claim_trans x
               where x.monitor_id = 0 and x.wf_status in ('P','A','R') and x.wf_referid=a.id ) > 0 ) and
      ( a.requestor_id = b.employee_id ) and
       ( a.dataset = 'claimapplication' )
UNION
SELECT     a.id,
       a.requestor_id,
       a.account_id,
       a.agentid,
       a.wf_mode,
       a.remarks,
       a.wf_status,
       a.created_by,
       a.created_date,
       a.modified_by,
       a.modified_date,
       b.employee_no,
       b.employee_name,
       a.dataset,
       0,
       ( select count(id) from inter_claim_trans x
          where x.monitor_id = 0 and x.wf_status in ('P','A','R') and x.wf_referid=a.id),
       ( select count(id) from inter_claim_trans x
             where x.monitor_id = 0 and x.wf_status = 'P' and x.wf_referid=a.id),
       ( select count(id) from inter_claim_trans x
             where x.monitor_id = 0 and x.wf_status <> 'P' and x.wf_referid=a.id),
       ( select count(id) from inter_claim_trans x
             where x.monitor_id = 0 and x.wf_status = 'A' and x.wf_referid=a.id),
       ( select count(id) from inter_claim_trans x
             where x.monitor_id = 0 and x.wf_status = 'R' and x.wf_referid=a.id),
        0,
          'FlowClaimIM/IMUserClaimInfo'
FROM     user_claim_application_hd a,     employee_biodata b
WHERE ( ( select count(id) from inter_claim_trans x
           where x.monitor_id = 0 and x.wf_status in ('P','A','R') and x.wf_referid=a.id ) > 0 ) and
      ( a.requestor_id = b.employee_id ) and
      ( a.dataset <> 'claimapplication' )
UNION
SELECT     a.id,
       a.requestor_id,
       a.account_id,
       a.agentid,
       a.wf_mode,
       a.remarks,
        a.wf_status,
       a.created_by,
       a.created_date,
       a.modified_by,
       a.modified_date,
       b.employee_no,
       b.employee_name ,
       a.dataset,
       0,
       ( select count(id) from inter_rc_rf_jobspec x
             where x.monitor_id = 0 and x.wf_status in ('P','A','R') and x.wf_referid=a.id),
       ( select count(id) from inter_rc_rf_jobspec x
             where x.monitor_id = 0 and x.wf_status = 'P' and x.wf_referid=a.id),
       ( select count(id) from inter_rc_rf_jobspec x
             where x.monitor_id = 0 and x.wf_status <> 'P' and x.wf_referid=a.id),
       ( select count(id) from inter_rc_rf_jobspec x
             where x.monitor_id = 0 and x.wf_status = 'A' and x.wf_referid=a.id),
       ( select count(id) from inter_rc_rf_jobspec x
             where x.monitor_id = 0 and x.wf_status = 'R' and x.wf_referid=a.id),
       0,
          'FlowResIM/IMUserResourceInfo'
FROM     inter_rc_rf_hd a,     employee_biodata b
WHERE ( ( select count(id) from inter_rc_rf_jobspec x
               where x.monitor_id = 0 and x.wf_status in ('P','A','R') and x.wf_referid=a.id) > 0 ) and
      ( a.requestor_id = b.employee_id)
UNION
SELECT     a.id,
       a.requestor_id,
       a.account_id,
       a.agentid,
       a.wf_mode,
       a.remarks,
        a.wf_status,
       a.created_by,
       a.created_date,
       a.modified_by,
       a.modified_date,
       b.employee_no,
       b.employee_name ,
       a.dataset,
       0,
       ( select count(id) from inter_rc_ro_dt x
             where x.monitor_id = 0 and x.wf_status in ('P','A','R') and x.wf_referid=a.id),
       ( select count(id) from inter_rc_ro_dt x
             where x.monitor_id = 0 and x.wf_status = 'P' and x.wf_referid=a.id),
       ( select count(id) from inter_rc_ro_dt x
             where x.monitor_id = 0 and x.wf_status <> 'P' and x.wf_referid=a.id),
       ( select count(id) from inter_rc_ro_dt x
             where x.monitor_id = 0 and x.wf_status = 'A' and x.wf_referid=a.id),
       ( select count(id) from inter_rc_ro_dt x
             where x.monitor_id = 0 and x.wf_status = 'R' and x.wf_referid=a.id),
       0,
          'FlowResIM/IMUserResourceInfo'
FROM     inter_rc_ro_hd a,     employee_biodata b
WHERE ( ( select count(id) from inter_rc_ro_dt x
               where x.monitor_id = 0 and x.wf_status in ('P','A','R') and x.wf_referid=a.id) > 0 ) and
      ( a.requestor_id = b.employee_id)
UNION
SELECT     a.id,
       a.requestor_id,
       a.account_id,
       a.agentid,
       a.wf_mode,
       a.remarks,
        a.wf_status,
       a.created_by,
       a.created_date,
       a.modified_by,
       a.modified_date,
       b.employee_no,
       b.employee_name ,
       a.dataset,
       0,
       ( select count(id) from inter_loan_car x
             where x.monitor_id = 0 and x.wf_status in ('P','A','R') and x.wf_referid=a.id),
       ( select count(id) from inter_loan_car x
             where x.monitor_id = 0 and x.wf_status = 'P' and x.wf_referid=a.id),
       ( select count(id) from inter_loan_car x
             where x.monitor_id = 0 and x.wf_status <> 'P' and x.wf_referid=a.id),
       ( select count(id) from inter_loan_car x
             where x.monitor_id = 0 and x.wf_status = 'A' and x.wf_referid=a.id),
       ( select count(id) from inter_loan_car x
             where x.monitor_id = 0 and x.wf_status = 'R' and x.wf_referid=a.id),
       0,
          'FlowLoanIM/IMUserLoanInfo'
FROM     user_loan_application_hd a, employee_biodata b
WHERE ( ( select count(id) from inter_loan_car x
               where x.monitor_id = 0 and x.wf_status in ('P','A','R') and x.wf_referid=a.id) > 0 ) and
      ( a.requestor_id = b.employee_id)
UNION
SELECT     a.id,
       a.requestor_id,
       a.account_id,
       a.agentid,
       a.wf_mode,
       a.remarks,
        a.wf_status,
       a.created_by,
       a.created_date,
       a.modified_by,
       a.modified_date,
       b.employee_no,
       b.employee_name ,
       a.dataset,
       0,
       ( select count(id) from inter_loan_motorcycle x
             where x.monitor_id = 0 and x.wf_status in ('P','A','R') and x.wf_referid=a.id),
       ( select count(id) from inter_loan_motorcycle x
             where x.monitor_id = 0 and x.wf_status = 'P' and x.wf_referid=a.id),
       ( select count(id) from inter_loan_motorcycle x
             where x.monitor_id = 0 and x.wf_status <> 'P' and x.wf_referid=a.id),
       ( select count(id) from inter_loan_motorcycle x
             where x.monitor_id = 0 and x.wf_status = 'A' and x.wf_referid=a.id),
       ( select count(id) from inter_loan_motorcycle x
             where x.monitor_id = 0 and x.wf_status = 'R' and x.wf_referid=a.id),
       0,
          'FlowLoanIM/IMUserLoanInfo'
FROM     user_loan_application_hd a, employee_biodata b
WHERE ( ( select count(id) from inter_loan_motorcycle x
               where x.monitor_id = 0 and x.wf_status in ('P','A','R') and x.wf_referid=a.id) > 0 ) and
      ( a.requestor_id = b.employee_id)
UNION
SELECT     a.id,
       a.requestor_id,
       a.account_id,
       a.agentid,
       a.wf_mode,
       a.remarks,
        a.wf_status,
       a.created_by,
       a.created_date,
       a.modified_by,
       a.modified_date,
       b.employee_no,
       b.employee_name ,
       a.dataset,
       0,
       ( select count(id) from inter_loan_housing x
             where x.monitor_id = 0 and x.wf_status in ('P','A','R') and x.wf_referid=a.id),
       ( select count(id) from inter_loan_housing x
             where x.monitor_id = 0 and x.wf_status = 'P' and x.wf_referid=a.id),
       ( select count(id) from inter_loan_housing x
             where x.monitor_id = 0 and x.wf_status <> 'P' and x.wf_referid=a.id),
       ( select count(id) from inter_loan_housing x
             where x.monitor_id = 0 and x.wf_status = 'A' and x.wf_referid=a.id),
       ( select count(id) from inter_loan_housing x
             where x.monitor_id = 0 and x.wf_status = 'R' and x.wf_referid=a.id),
       0,
          'FlowLoanIM/IMUserLoanInfo'
FROM     user_loan_application_hd a, employee_biodata b
WHERE ( ( select count(id) from inter_loan_housing x
               where x.monitor_id = 0 and x.wf_status in ('P','A','R') and x.wf_referid=a.id) > 0 ) and
      ( a.requestor_id = b.employee_id)
UNION
SELECT     a.id,
       a.requestor_id,
       a.account_id,
       a.agentid,
       a.wf_mode,
       a.remarks,
        a.wf_status,
       a.created_by,
       a.created_date,
       a.modified_by,
       a.modified_date,
       b.employee_no,
       b.employee_name ,
       a.dataset,
       0,
       ( select count(id) from inter_loan_renovation x
             where x.monitor_id = 0 and x.wf_status in ('P','A','R') and x.wf_referid=a.id),
       ( select count(id) from inter_loan_renovation x
             where x.monitor_id = 0 and x.wf_status = 'P' and x.wf_referid=a.id),
       ( select count(id) from inter_loan_renovation x
             where x.monitor_id = 0 and x.wf_status <> 'P' and x.wf_referid=a.id),
       ( select count(id) from inter_loan_renovation x
             where x.monitor_id = 0 and x.wf_status = 'A' and x.wf_referid=a.id),
       ( select count(id) from inter_loan_renovation x
             where x.monitor_id = 0 and x.wf_status = 'R' and x.wf_referid=a.id),
       0,
          'FlowLoanIM/IMUserLoanInfo'
FROM     user_loan_application_hd a, employee_biodata b
WHERE ( ( select count(id) from inter_loan_renovation x
               where x.monitor_id = 0 and x.wf_status in ('P','A','R') and x.wf_referid=a.id) > 0 ) and
      ( a.requestor_id = b.employee_id)
UNION
SELECT     a.id,
       a.requestor_id,
       a.account_id,
       a.agentid,
       a.wf_mode,
       a.remarks,
        a.wf_status,
       a.created_by,
       a.created_date,
       a.modified_by,
       a.modified_date,
       b.employee_no,
       b.employee_name ,
       a.dataset,
       0,
       ( select count(id) from inter_loan_study x
             where x.monitor_id = 0 and x.wf_status in ('P','A','R') and x.wf_referid=a.id),
       ( select count(id) from inter_loan_study x
             where x.monitor_id = 0 and x.wf_status = 'P' and x.wf_referid=a.id),
       ( select count(id) from inter_loan_study x
             where x.monitor_id = 0 and x.wf_status <> 'P' and x.wf_referid=a.id),
       ( select count(id) from inter_loan_study x
             where x.monitor_id = 0 and x.wf_status = 'A' and x.wf_referid=a.id),
       ( select count(id) from inter_loan_study x
             where x.monitor_id = 0 and x.wf_status = 'R' and x.wf_referid=a.id),
       0,
          'FlowLoanIM/IMUserLoanInfo'
FROM     user_loan_application_hd a, employee_biodata b
WHERE ( ( select count(id) from inter_loan_study x
               where x.monitor_id = 0 and x.wf_status in ('P','A','R') and x.wf_referid=a.id) > 0 ) and
      ( a.requestor_id = b.employee_id)
UNION
SELECT     a.id,
       a.requestor_id,
       a.account_id,
       a.agentid,
       a.wf_mode,
       a.remarks,
        a.wf_status,
       a.created_by,
       a.created_date,
       a.modified_by,
       a.modified_date,
       b.employee_no,
       b.employee_name ,
       a.dataset,
       0,
       ( select count(id) from inter_loan_sundry x
             where x.monitor_id = 0 and x.wf_status in ('P','A','R') and x.wf_referid=a.id),
       ( select count(id) from inter_loan_sundry x
             where x.monitor_id = 0 and x.wf_status = 'P' and x.wf_referid=a.id),
       ( select count(id) from inter_loan_sundry x
             where x.monitor_id = 0 and x.wf_status <> 'P' and x.wf_referid=a.id),
       ( select count(id) from inter_loan_sundry x
             where x.monitor_id = 0 and x.wf_status = 'A' and x.wf_referid=a.id),
       ( select count(id) from inter_loan_sundry x
             where x.monitor_id = 0 and x.wf_status = 'R' and x.wf_referid=a.id),
       0,
          'FlowLoanIM/IMUserLoanInfo'
FROM     user_loan_application_hd a, employee_biodata b
WHERE ( ( select count(id) from inter_loan_sundry x
               where x.monitor_id = 0 and x.wf_status in ('P','A','R') and x.wf_referid=a.id) > 0 ) and
      ( a.requestor_id = b.employee_id)
UNION
SELECT 	a.id,
   	a.requestor_id,
   	a.account_id,
   	a.agentid,
   	a.wf_mode,
   	a.remarks,
   	a.wf_status,
   	a.created_by,
   	a.created_date,
   	a.modified_by,
   	a.modified_date,
   	b.employee_no,
   	b.employee_name,
   	a.dataset,
   	0,
   	( select count(id) from inter_ot_requisition x
         where x.monitor_id = 0 and x.wf_status in ('P','A','R') and x.wf_referid=a.id),
   	( select count(id) from inter_ot_requisition x
         	where x.monitor_id = 0 and x.wf_status = 'P' and x.wf_referid=a.id),
   	( select count(id) from inter_ot_requisition x
         	where x.monitor_id = 0 and x.wf_status <> 'P' and x.wf_referid=a.id),
   	( select count(id) from inter_ot_requisition x
         	where x.monitor_id = 0 and x.wf_status = 'A' and x.wf_referid=a.id),
   	( select count(id) from inter_ot_requisition x
         where x.monitor_id = 0 and x.wf_status = 'P' and x.wf_referid=a.id),
    	0,
      'FlowNetIM/IMUserOtr'
 FROM user_ot_application_hd a, employee_biodata b
WHERE ( ( select count(id) from inter_ot_requisition x
           where x.monitor_id = 0 and x.wf_status in ('P','A','R') and x.wf_referid=a.id ) > 0 ) and
     	( a.requestor_id = b.employee_id )

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE VIEW [dbo].[VNET_WFWCONSOLE]
(PROCESS, STEP, AGENTID, WF_STATUS, EMPLOYEE_ID, 
 CREATED_BY, CREATED_DATE, MODIFIED_BY, MODIFIED_DATE, ITEM_ID, 
 STATUS, MONITOR_ID, EMPLOYEE_STATUS, WF_RECIPIENT_ID)
AS 
SELECT 'Leave' as process,
			'1. Leave' as step,
         INTER_EMPLOYEE_LEAVE_INFO.AGENTID,
         INTER_EMPLOYEE_LEAVE_INFO.WF_STATUS,
         INTER_EMPLOYEE_LEAVE_INFO.EMPLOYEE_ID,
         INTER_EMPLOYEE_LEAVE_INFO.CREATED_BY,
         INTER_EMPLOYEE_LEAVE_INFO.CREATED_DATE,
         INTER_EMPLOYEE_LEAVE_INFO.MODIFIED_BY,
         INTER_EMPLOYEE_LEAVE_INFO.MODIFIED_DATE,
	 ID as item_id,
	 ' ' as status,
	 INTER_EMPLOYEE_LEAVE_INFO.MONITOR_ID,
	 EMPLOYEE_EMPLOYMENT.EMPLOYEE_STATUS,
	 0
FROM INTER_EMPLOYEE_LEAVE_INFO, EMPLOYEE_EMPLOYMENT
WHERE INTER_EMPLOYEE_LEAVE_INFO.EMPLOYEE_ID = EMPLOYEE_EMPLOYMENT.EMPLOYEE_ID
UNION
SELECT 'Leave',
	'2. Agent',
         WF_AGENT.ID,
         WF_AGENT.STATUS,
	 0,
         WF_AGENT.CREATED_BY,
         WF_AGENT.CREATED_DATE,
         WF_AGENT.MODIFIED_BY,
         WF_AGENT.MODIFIED_DATE,
	 0,
	 ' ',
	 0,
	 ' ',
	 0
FROM WF_AGENT
WHERE ID IN(SELECT AGENTID FROM INTER_EMPLOYEE_LEAVE_INFO)
UNION
SELECT 'Leave',
	'3. Monitor',
         WF_MONITOR.AGENTID,
         WF_MONITOR.STATUS,
	 0,
         WF_MONITOR.CREATED_BY,
         WF_MONITOR.CREATED_DATE,
         WF_MONITOR.MODIFIED_BY,
         WF_MONITOR.MODIFIED_DATE,
	 ITEM_ID,
	 ' ',
 	 WF_MONITOR.MONITOR_ID,
	 ' ',
	 0
FROM WF_MONITOR
WHERE AGENTID IN (SELECT AGENTID FROM INTER_EMPLOYEE_LEAVE_INFO)
UNION
SELECT 'Leave',
	'4. Recipient',
	( select min(agentid) from wf_monitor where id = 	WF_RECIPIENT.MONITOR_ID),
        WF_RECIPIENT.ACTION_STATUS,
	WF_RECIPIENT.ENTITY_ID,
        WF_RECIPIENT.CREATED_BY,
        WF_RECIPIENT.CREATED_DATE,
        WF_RECIPIENT.MODIFIED_BY,
        WF_RECIPIENT.MODIFIED_DATE,
	ITEM_ID,
	WF_RECIPIENT.RECIPIENT_STATUS,
	WF_RECIPIENT.MONITOR_ID,
	EMPLOYEE_EMPLOYMENT.EMPLOYEE_STATUS,
	WF_RECIPIENT.ID
FROM WF_RECIPIENT, EMPLOYEE_EMPLOYMENT
WHERE WF_RECIPIENT.ENTITY_ID = EMPLOYEE_EMPLOYMENT.EMPLOYEE_ID AND
MONITOR_ID IN (SELECT ID FROM WF_MONITOR WHERE AGENTID IN (SELECT AGENTID FROM INTER_EMPLOYEE_LEAVE_INFO))
UNION
SELECT 'Overtime' as process,
			'1. Overtime' as step,
         INTER_OT_REQUISITION.AGENTID,
         INTER_OT_REQUISITION.WF_STATUS,
         INTER_OT_REQUISITION.EMPLOYEE_ID,
         INTER_OT_REQUISITION.CREATED_BY,
         INTER_OT_REQUISITION.CREATED_DATE,
         INTER_OT_REQUISITION.MODIFIED_BY,
         INTER_OT_REQUISITION.MODIFIED_DATE,
	 ID as item_id,
	 ' ' as status,
	 INTER_OT_REQUISITION.MONITOR_ID,
	 EMPLOYEE_EMPLOYMENT.EMPLOYEE_STATUS,
	 0
FROM INTER_OT_REQUISITION, EMPLOYEE_EMPLOYMENT
WHERE INTER_OT_REQUISITION.EMPLOYEE_ID = EMPLOYEE_EMPLOYMENT.EMPLOYEE_ID
UNION
SELECT 'Overtime',
	'2. Agent',
         WF_AGENT.ID,
         WF_AGENT.STATUS,
	 0,
         WF_AGENT.CREATED_BY,
         WF_AGENT.CREATED_DATE,
         WF_AGENT.MODIFIED_BY,
         WF_AGENT.MODIFIED_DATE,
	 0,
	 ' ',
	 0,
	 ' ',
	 0
FROM WF_AGENT
WHERE ID IN(SELECT AGENTID FROM INTER_OT_REQUISITION)
UNION
SELECT 'Overtime',
	'3. Monitor',
         WF_MONITOR.AGENTID,
         WF_MONITOR.STATUS,
	 0,
         WF_MONITOR.CREATED_BY,
         WF_MONITOR.CREATED_DATE,
         WF_MONITOR.MODIFIED_BY,
         WF_MONITOR.MODIFIED_DATE,
	 ITEM_ID,
	 ' ',
 	 WF_MONITOR.MONITOR_ID,
	 ' ',
	 0
FROM WF_MONITOR
WHERE AGENTID IN (SELECT AGENTID FROM INTER_OT_REQUISITION)
UNION
SELECT 'Overtime',
	'4. Recipient',
	( select min(agentid) from wf_monitor where id = 	WF_RECIPIENT.MONITOR_ID),
        WF_RECIPIENT.ACTION_STATUS,
	WF_RECIPIENT.ENTITY_ID,
        WF_RECIPIENT.CREATED_BY,
        WF_RECIPIENT.CREATED_DATE,
        WF_RECIPIENT.MODIFIED_BY,
        WF_RECIPIENT.MODIFIED_DATE,
	ITEM_ID,
	WF_RECIPIENT.RECIPIENT_STATUS,
	WF_RECIPIENT.MONITOR_ID,
	EMPLOYEE_EMPLOYMENT.EMPLOYEE_STATUS,
	WF_RECIPIENT.ID
FROM WF_RECIPIENT, EMPLOYEE_EMPLOYMENT
WHERE WF_RECIPIENT.ENTITY_ID = EMPLOYEE_EMPLOYMENT.EMPLOYEE_ID AND
MONITOR_ID IN (SELECT ID FROM WF_MONITOR WHERE AGENTID IN (SELECT AGENTID FROM INTER_OT_REQUISITION))
UNION
SELECT 'Personal' as process,
	'1. Personal' as step,
         INTER_EMPLOYEE_BIODATA.AGENTID,
         INTER_EMPLOYEE_BIODATA.WF_STATUS,
         INTER_EMPLOYEE_BIODATA.EMPLOYEE_ID,
         INTER_EMPLOYEE_BIODATA.CREATED_BY,
         INTER_EMPLOYEE_BIODATA.CREATED_DATE,
         INTER_EMPLOYEE_BIODATA.MODIFIED_BY,
         INTER_EMPLOYEE_BIODATA.MODIFIED_DATE,
	 ID as item_id,
	 ' ' as status,
	 INTER_EMPLOYEE_BIODATA.MONITOR_ID,
	 EMPLOYEE_EMPLOYMENT.EMPLOYEE_STATUS,
	 0
FROM INTER_EMPLOYEE_BIODATA, EMPLOYEE_EMPLOYMENT
WHERE INTER_EMPLOYEE_BIODATA.EMPLOYEE_ID = EMPLOYEE_EMPLOYMENT.EMPLOYEE_ID
UNION
SELECT 'Personal',
	'2. Agent',
         WF_AGENT.ID,
         WF_AGENT.STATUS,
	 0,
         WF_AGENT.CREATED_BY,
         WF_AGENT.CREATED_DATE,
         WF_AGENT.MODIFIED_BY,
         WF_AGENT.MODIFIED_DATE,
	 0,
	 ' ',
	 0,
	 ' ',
	 0
FROM WF_AGENT
WHERE ID IN (SELECT AGENTID FROM INTER_EMPLOYEE_BIODATA)
UNION
SELECT 'Personal',
	'3. Monitor',
         WF_MONITOR.AGENTID,
         WF_MONITOR.STATUS,
	 0,
         WF_MONITOR.CREATED_BY,
         WF_MONITOR.CREATED_DATE,
         WF_MONITOR.MODIFIED_BY,
         WF_MONITOR.MODIFIED_DATE,
	 ITEM_ID,
	 ' ',
	 WF_MONITOR.MONITOR_ID,
	 ' ',
	 0
FROM WF_MONITOR
WHERE AGENTID IN (SELECT AGENTID FROM INTER_EMPLOYEE_BIODATA)
UNION
SELECT 'Personal',
	'4. Recipient',
	 ( select min(agentid) from wf_monitor 	 where id = WF_RECIPIENT.MONITOR_ID),
         WF_RECIPIENT.ACTION_STATUS,
	 WF_RECIPIENT.ENTITY_ID,
         WF_RECIPIENT.CREATED_BY,
         WF_RECIPIENT.CREATED_DATE,
         WF_RECIPIENT.MODIFIED_BY,
         WF_RECIPIENT.MODIFIED_DATE,
	 ITEM_ID,
	 WF_RECIPIENT.RECIPIENT_STATUS,
	 WF_RECIPIENT.MONITOR_ID,
	 EMPLOYEE_EMPLOYMENT.EMPLOYEE_STATUS,
	 WF_RECIPIENT.ID
FROM WF_RECIPIENT, EMPLOYEE_EMPLOYMENT
WHERE WF_RECIPIENT.ENTITY_ID = EMPLOYEE_EMPLOYMENT.EMPLOYEE_ID AND
MONITOR_ID IN ( SELECT ID FROM WF_MONITOR WHERE AGENTID IN (SELECT AGENTID FROM INTER_EMPLOYEE_BIODATA))
UNION
SELECT 'Relation' as process,
	'1. Relation' as step,
         INTER_EMPLOYEE_RELATION.AGENTID,
         INTER_EMPLOYEE_RELATION.WF_STATUS,
         INTER_EMPLOYEE_RELATION.EMPLOYEE_ID,
         INTER_EMPLOYEE_RELATION.CREATED_BY,
         INTER_EMPLOYEE_RELATION.CREATED_DATE,
         INTER_EMPLOYEE_RELATION.MODIFIED_BY,
         INTER_EMPLOYEE_RELATION.MODIFIED_DATE,
	 ID as item_id,
	 ' ' as status,
	 INTER_EMPLOYEE_RELATION.MONITOR_ID,
	 EMPLOYEE_EMPLOYMENT.EMPLOYEE_STATUS,
	 0
FROM INTER_EMPLOYEE_RELATION, EMPLOYEE_EMPLOYMENT
WHERE INTER_EMPLOYEE_RELATION.EMPLOYEE_ID = EMPLOYEE_EMPLOYMENT.EMPLOYEE_ID
UNION
SELECT 'Relation',
	'2. Agent',
         WF_AGENT.ID,
  	 WF_AGENT.STATUS,
	 0,
         WF_AGENT.CREATED_BY,
         WF_AGENT.CREATED_DATE,
         WF_AGENT.MODIFIED_BY,
         WF_AGENT.MODIFIED_DATE,
	 0,
	 ' ',
	 0,
	 ' ',
	 0
FROM WF_AGENT
WHERE ID IN (SELECT AGENTID FROM INTER_EMPLOYEE_RELATION)
UNION
SELECT 'Relation',
	'3. Monitor',
         WF_MONITOR.AGENTID,
         WF_MONITOR.STATUS,
	 0,
         WF_MONITOR.CREATED_BY,
         WF_MONITOR.CREATED_DATE,
         WF_MONITOR.MODIFIED_BY,
         WF_MONITOR.MODIFIED_DATE,
	 ITEM_ID,
	 ' ',
	 WF_MONITOR.MONITOR_ID,
	 ' ',
	 0
FROM WF_MONITOR
WHERE AGENTID IN (SELECT AGENTID FROM INTER_EMPLOYEE_RELATION)
UNION
SELECT 'Relation',
	'4. Recipient',
	( select min(agentid) from wf_monitor where id = WF_RECIPIENT.MONITOR_ID),
         WF_RECIPIENT.ACTION_STATUS,
	 WF_RECIPIENT.ENTITY_ID,
         WF_RECIPIENT.CREATED_BY,
         WF_RECIPIENT.CREATED_DATE,
         WF_RECIPIENT.MODIFIED_BY,
         WF_RECIPIENT.MODIFIED_DATE,
	 ITEM_ID,
	 WF_RECIPIENT.RECIPIENT_STATUS,
	 WF_RECIPIENT.MONITOR_ID,
	 EMPLOYEE_EMPLOYMENT.EMPLOYEE_STATUS,
	 WF_RECIPIENT.ID
 FROM WF_RECIPIENT, EMPLOYEE_EMPLOYMENT
WHERE WF_RECIPIENT.ENTITY_ID = EMPLOYEE_EMPLOYMENT.EMPLOYEE_ID AND
MONITOR_ID IN( SELECT ID FROM WF_MONITOR WHERE agentid IN (SELECT AGENTID FROM INTER_EMPLOYEE_RELATION))
UNION
SELECT 'Employment' as process,
	'1. Employment' as step,
         INTER_EMPLOYEE_EMPLOYMENT.AGENTID,
         INTER_EMPLOYEE_EMPLOYMENT.WF_STATUS,
         INTER_EMPLOYEE_EMPLOYMENT.EMPLOYEE_ID,
         INTER_EMPLOYEE_EMPLOYMENT.CREATED_BY,
         INTER_EMPLOYEE_EMPLOYMENT.CREATED_DATE,
         INTER_EMPLOYEE_EMPLOYMENT.MODIFIED_BY,
         INTER_EMPLOYEE_EMPLOYMENT.MODIFIED_DATE,
	 ID as item_id,
	 ' ' as status,
	 INTER_EMPLOYEE_EMPLOYMENT.MONITOR_ID,
	 INTER_EMPLOYEE_EMPLOYMENT.EMPLOYEE_STATUS,
	 0
FROM INTER_EMPLOYEE_EMPLOYMENT
UNION
SELECT 'Employment',
	'2. Agent',
         WF_AGENT.ID,
         WF_AGENT.STATUS,
	 0,
         WF_AGENT.CREATED_BY,
         WF_AGENT.CREATED_DATE,
         WF_AGENT.MODIFIED_BY,
         WF_AGENT.MODIFIED_DATE,
	 0,
	 ' ',
	 0,
	 ' ',
	 0
FROM WF_AGENT
WHERE ID IN(SELECT AGENTID FROM INTER_EMPLOYEE_EMPLOYMENT)
UNION
SELECT 'Employment',
	'3. Monitor',
         WF_MONITOR.AGENTID,
         WF_MONITOR.STATUS,
	 0,
         WF_MONITOR.CREATED_BY,
         WF_MONITOR.CREATED_DATE,
         WF_MONITOR.MODIFIED_BY,
         WF_MONITOR.MODIFIED_DATE,
	 ITEM_ID,
	 ' ',
	 WF_MONITOR.MONITOR_ID,
	 ' ',
	 0
FROM WF_MONITOR
WHERE AGENTID IN(SELECT AGENTID FROM INTER_EMPLOYEE_EMPLOYMENT)
UNION
SELECT 'Employment',
	'4. Recipient',
	( select min(agentid) from wf_monitor where id = WF_RECIPIENT.MONITOR_ID),
         WF_RECIPIENT.ACTION_STATUS,
	 WF_RECIPIENT.ENTITY_ID,
         WF_RECIPIENT.CREATED_BY,
         WF_RECIPIENT.CREATED_DATE,
         WF_RECIPIENT.MODIFIED_BY,
         WF_RECIPIENT.MODIFIED_DATE,
	 ITEM_ID,
	 WF_RECIPIENT.RECIPIENT_STATUS,
	 WF_RECIPIENT.MONITOR_ID,
	 EMPLOYEE_EMPLOYMENT.EMPLOYEE_STATUS,
	 WF_RECIPIENT.ID
 FROM WF_RECIPIENT, EMPLOYEE_EMPLOYMENT
WHERE WF_RECIPIENT.ENTITY_ID = EMPLOYEE_EMPLOYMENT.EMPLOYEE_ID AND
MONITOR_ID IN( SELECT ID FROM WF_MONITOR WHERE AGENTID IN(SELECT AGENTID FROM INTER_EMPLOYEE_EMPLOYMENT))
union
  SELECT 'Experience' as process,
	'1. Experience' as step,
         INTER_EMPLOYEE_EXPERIENCE.AGENTID,
         INTER_EMPLOYEE_EXPERIENCE.WF_STATUS,
         INTER_EMPLOYEE_EXPERIENCE.EMPLOYEE_ID,
         INTER_EMPLOYEE_EXPERIENCE.CREATED_BY,
         INTER_EMPLOYEE_EXPERIENCE.CREATED_DATE,
         INTER_EMPLOYEE_EXPERIENCE.MODIFIED_BY,
         INTER_EMPLOYEE_EXPERIENCE.MODIFIED_DATE,
	 ID as item_id,
	 ' ' as status,
	 INTER_EMPLOYEE_EXPERIENCE.MONITOR_ID,
	 EMPLOYEE_EMPLOYMENT.EMPLOYEE_STATUS,
	 0
FROM INTER_EMPLOYEE_EXPERIENCE, EMPLOYEE_EMPLOYMENT
WHERE INTER_EMPLOYEE_EXPERIENCE.EMPLOYEE_ID = EMPLOYEE_EMPLOYMENT.EMPLOYEE_ID
UNION
SELECT 'Experience',
	'2. Agent',
         WF_AGENT.ID,
         WF_AGENT.STATUS,
	 0,
         WF_AGENT.CREATED_BY,
         WF_AGENT.CREATED_DATE,
         WF_AGENT.MODIFIED_BY,
         WF_AGENT.MODIFIED_DATE,
	 0,
	 ' ',
	 0,
	 ' ',
	 0
FROM WF_AGENT
WHERE ID IN(SELECT AGENTID FROM INTER_EMPLOYEE_EXPERIENCE)
UNION
SELECT 'Experience',
	'3. Monitor',
         WF_MONITOR.AGENTID,
         WF_MONITOR.STATUS,
	 0,
         WF_MONITOR.CREATED_BY,
         WF_MONITOR.CREATED_DATE,
         WF_MONITOR.MODIFIED_BY,
         WF_MONITOR.MODIFIED_DATE,
	 ITEM_ID,
	 ' ',
	 WF_MONITOR.MONITOR_ID,
	 ' ',
	 0
FROM WF_MONITOR
WHERE AGENTID IN(SELECT AGENTID FROM INTER_EMPLOYEE_EXPERIENCE)
UNION
SELECT 'Experience',
	'4. Recipient',
	( select min(agentid) from wf_monitor where id = WF_RECIPIENT.MONITOR_ID),
         WF_RECIPIENT.ACTION_STATUS,
	 WF_RECIPIENT.ENTITY_ID,
         WF_RECIPIENT.CREATED_BY,
         WF_RECIPIENT.CREATED_DATE,
         WF_RECIPIENT.MODIFIED_BY,
         WF_RECIPIENT.MODIFIED_DATE,
	 ITEM_ID,
	 WF_RECIPIENT.RECIPIENT_STATUS,
	 WF_RECIPIENT.MONITOR_ID,
	 EMPLOYEE_EMPLOYMENT.EMPLOYEE_STATUS,
	 WF_RECIPIENT.ID
 FROM WF_RECIPIENT, EMPLOYEE_EMPLOYMENT
WHERE WF_RECIPIENT.ENTITY_ID = EMPLOYEE_EMPLOYMENT.EMPLOYEE_ID AND
MONITOR_ID IN( SELECT ID FROM WF_MONITOR WHERE AGENTID IN(SELECT AGENTID FROM INTER_EMPLOYEE_EXPERIENCE))
UNION
  SELECT 'Qualification' as process,
	'1. Qualification' as step,
         INTER_EMPLOYEE_QUALIFICATION.AGENTID,
         INTER_EMPLOYEE_QUALIFICATION.WF_STATUS,
         INTER_EMPLOYEE_QUALIFICATION.EMPLOYEE_ID,
         INTER_EMPLOYEE_QUALIFICATION.CREATED_BY,
         INTER_EMPLOYEE_QUALIFICATION.CREATED_DATE,
         INTER_EMPLOYEE_QUALIFICATION.MODIFIED_BY,
         INTER_EMPLOYEE_QUALIFICATION.MODIFIED_DATE,
	 ID as item_id,
	 ' ' as status,
	 INTER_EMPLOYEE_QUALIFICATION.MONITOR_ID,
	 EMPLOYEE_EMPLOYMENT.EMPLOYEE_STATUS,
	 0
FROM INTER_EMPLOYEE_QUALIFICATION, EMPLOYEE_EMPLOYMENT
WHERE INTER_EMPLOYEE_QUALIFICATION.EMPLOYEE_ID = EMPLOYEE_EMPLOYMENT.EMPLOYEE_ID
UNION
SELECT 'Qualification',
	'2. Agent',
         WF_AGENT.ID,
         WF_AGENT.STATUS,
	 0,
         WF_AGENT.CREATED_BY,
         WF_AGENT.CREATED_DATE,
         WF_AGENT.MODIFIED_BY,
         WF_AGENT.MODIFIED_DATE,
	 0,
	 ' ',
	 0,
	 ' ',
	 0
FROM WF_AGENT
WHERE ID IN(SELECT AGENTID FROM INTER_EMPLOYEE_QUALIFICATION)
UNION
SELECT 'Qualification',
	'3. Monitor',
         WF_MONITOR.AGENTID,
         WF_MONITOR.STATUS,
	 0,
         WF_MONITOR.CREATED_BY,
         WF_MONITOR.CREATED_DATE,
         WF_MONITOR.MODIFIED_BY,
         WF_MONITOR.MODIFIED_DATE,
	 ITEM_ID,
	 ' ',
	 WF_MONITOR.MONITOR_ID,
	 ' ',
	 0
FROM WF_MONITOR
WHERE AGENTID IN(SELECT AGENTID FROM INTER_EMPLOYEE_QUALIFICATION)
UNION
SELECT 'Qualification',
	'4. Recipient',
	( select min(agentid) from wf_monitor where id = WF_RECIPIENT.MONITOR_ID),
         WF_RECIPIENT.ACTION_STATUS,
	 WF_RECIPIENT.ENTITY_ID,
         WF_RECIPIENT.CREATED_BY,
         WF_RECIPIENT.CREATED_DATE,
         WF_RECIPIENT.MODIFIED_BY,
         WF_RECIPIENT.MODIFIED_DATE,
	 ITEM_ID,
	 WF_RECIPIENT.RECIPIENT_STATUS,
	 WF_RECIPIENT.MONITOR_ID,
	 EMPLOYEE_EMPLOYMENT.EMPLOYEE_STATUS,
	 WF_RECIPIENT.ID
 FROM WF_RECIPIENT, EMPLOYEE_EMPLOYMENT
WHERE WF_RECIPIENT.ENTITY_ID = EMPLOYEE_EMPLOYMENT.EMPLOYEE_ID AND
MONITOR_ID IN( SELECT ID FROM WF_MONITOR WHERE AGENTID IN(SELECT AGENTID FROM INTER_EMPLOYEE_QUALIFICATION))
UNION
  SELECT 'Skill' as process,
	'1. Skill' as step,
         INTER_EMPLOYEE_SKILL.AGENTID,
         INTER_EMPLOYEE_SKILL.WF_STATUS,
         INTER_EMPLOYEE_SKILL.EMPLOYEE_ID,
         INTER_EMPLOYEE_SKILL.CREATED_BY,
         INTER_EMPLOYEE_SKILL.CREATED_DATE,
         INTER_EMPLOYEE_SKILL.MODIFIED_BY,
         INTER_EMPLOYEE_SKILL.MODIFIED_DATE,
	 ID as item_id,
	 ' ' as status,
	 INTER_EMPLOYEE_SKILL.MONITOR_ID,
	 EMPLOYEE_EMPLOYMENT.EMPLOYEE_STATUS,
	 0
FROM INTER_EMPLOYEE_SKILL, EMPLOYEE_EMPLOYMENT
WHERE INTER_EMPLOYEE_SKILL.EMPLOYEE_ID = EMPLOYEE_EMPLOYMENT.EMPLOYEE_ID
UNION
SELECT 'Skill',
	 '2. Agent',
         WF_AGENT.ID,
         WF_AGENT.STATUS,
	 0,
         WF_AGENT.CREATED_BY,
         WF_AGENT.CREATED_DATE,
         WF_AGENT.MODIFIED_BY,
         WF_AGENT.MODIFIED_DATE,
	 0,
	 ' ',
	 0,
	 ' ',
	 0
FROM WF_AGENT
WHERE ID IN(SELECT AGENTID FROM INTER_EMPLOYEE_SKILL)
UNION
SELECT 'Skill',
	'3. Monitor',
         WF_MONITOR.AGENTID,
         WF_MONITOR.STATUS,
	 0,
         WF_MONITOR.CREATED_BY,
         WF_MONITOR.CREATED_DATE,
         WF_MONITOR.MODIFIED_BY,
         WF_MONITOR.MODIFIED_DATE,
	 ITEM_ID,
	 ' ',
	 WF_MONITOR.MONITOR_ID,
	' ',
	0
FROM WF_MONITOR
WHERE AGENTID IN(SELECT AGENTID FROM INTER_EMPLOYEE_SKILL)
UNION
SELECT 'Skill',
	'4. Recipient',
	( select min(agentid) from wf_monitor where id = WF_RECIPIENT.MONITOR_ID),
         WF_RECIPIENT.ACTION_STATUS,
	 WF_RECIPIENT.ENTITY_ID,
         WF_RECIPIENT.CREATED_BY,
         WF_RECIPIENT.CREATED_DATE,
         WF_RECIPIENT.MODIFIED_BY,
         WF_RECIPIENT.MODIFIED_DATE,
 	 ITEM_ID,
	 WF_RECIPIENT.RECIPIENT_STATUS,
	 WF_RECIPIENT.MONITOR_ID,
	 EMPLOYEE_EMPLOYMENT.EMPLOYEE_STATUS,
	 WF_RECIPIENT.ID
FROM WF_RECIPIENT, EMPLOYEE_EMPLOYMENT
WHERE WF_RECIPIENT.ENTITY_ID = EMPLOYEE_EMPLOYMENT.EMPLOYEE_ID AND
MONITOR_ID IN(SELECT ID FROM WF_MONITOR WHERE AGENTID IN(SELECT AGENTID FROM INTER_EMPLOYEE_SKILL))
UNION
SELECT 'Training' as process,
	'1. Training' as step,
         INTER_EMPLOYEE_TRAINING.AGENTID,
         INTER_EMPLOYEE_TRAINING.WF_STATUS,
         INTER_EMPLOYEE_TRAINING.EMPLOYEE_ID,
         INTER_EMPLOYEE_TRAINING.CREATED_BY,
         INTER_EMPLOYEE_TRAINING.CREATED_DATE,
         INTER_EMPLOYEE_TRAINING.MODIFIED_BY,
         INTER_EMPLOYEE_TRAINING.MODIFIED_DATE,
	 ID as item_id,
	 ' ' as status,
	 INTER_EMPLOYEE_TRAINING.MONITOR_ID,
	 EMPLOYEE_EMPLOYMENT.EMPLOYEE_STATUS,
	 0
FROM INTER_EMPLOYEE_TRAINING, EMPLOYEE_EMPLOYMENT
WHERE INTER_EMPLOYEE_TRAINING.EMPLOYEE_ID = EMPLOYEE_EMPLOYMENT.EMPLOYEE_ID
UNION
SELECT 'Training',
	'2. Agent',
         WF_AGENT.ID,
         WF_AGENT.STATUS,
			0,
         WF_AGENT.CREATED_BY,
         WF_AGENT.CREATED_DATE,
         WF_AGENT.MODIFIED_BY,
         WF_AGENT.MODIFIED_DATE,
	 0,
	 ' ',
	 0,
	 ' ',
	 0
FROM WF_AGENT
WHERE ID IN(SELECT AGENTID FROM INTER_EMPLOYEE_TRAINING)
UNION
SELECT 'Training',
	'3. Monitor',
         WF_MONITOR.AGENTID,
         WF_MONITOR.STATUS,
	 0,
         WF_MONITOR.CREATED_BY,
         WF_MONITOR.CREATED_DATE,
         WF_MONITOR.MODIFIED_BY,
         WF_MONITOR.MODIFIED_DATE,
	 ITEM_ID,
	 ' ',
	 WF_MONITOR.MONITOR_ID,
	 ' ',
	 0
FROM WF_MONITOR
WHERE AGENTID IN(SELECT AGENTID FROM INTER_EMPLOYEE_TRAINING)
UNION
SELECT 'Training',
	'4. Recipient',
	( select min(agentid) from wf_monitor where id = WF_RECIPIENT.MONITOR_ID),
         WF_RECIPIENT.ACTION_STATUS,
	 WF_RECIPIENT.ENTITY_ID,
         WF_RECIPIENT.CREATED_BY,
         WF_RECIPIENT.CREATED_DATE,
         WF_RECIPIENT.MODIFIED_BY,
         WF_RECIPIENT.MODIFIED_DATE,
	 ITEM_ID,
	 WF_RECIPIENT.RECIPIENT_STATUS,
	 WF_RECIPIENT.MONITOR_ID,
	 EMPLOYEE_EMPLOYMENT.EMPLOYEE_STATUS,
	 WF_RECIPIENT.ID
FROM WF_RECIPIENT, EMPLOYEE_EMPLOYMENT
WHERE WF_RECIPIENT.ENTITY_ID = EMPLOYEE_EMPLOYMENT.EMPLOYEE_ID AND
MONITOR_ID IN( SELECT ID FROM WF_MONITOR WHERE AGENTID IN(SELECT AGENTID FROM INTER_EMPLOYEE_TRAINING))
UNION
SELECT 'LeaveCancel' as process,
	'1. LeaveCancel' as step,
         INTER_EMPLOYEE_LEAVE_CANCEL.AGENTID,
         INTER_EMPLOYEE_LEAVE_CANCEL.WF_STATUS,
         USER_LEAVE_CANCELLATION_HD.REQUESTOR_ID,
         INTER_EMPLOYEE_LEAVE_CANCEL.CREATED_BY,
         INTER_EMPLOYEE_LEAVE_CANCEL.CREATED_DATE,
         INTER_EMPLOYEE_LEAVE_CANCEL.MODIFIED_BY,
         INTER_EMPLOYEE_LEAVE_CANCEL.MODIFIED_DATE,
	 INTER_EMPLOYEE_LEAVE_CANCEL.ID as item_id,
	 ' ' as status,
	 INTER_EMPLOYEE_LEAVE_CANCEL.MONITOR_ID,
 	 EMPLOYEE_EMPLOYMENT.EMPLOYEE_STATUS,
	 0
FROM INTER_EMPLOYEE_LEAVE_CANCEL, USER_LEAVE_CANCELLATION_HD, EMPLOYEE_EMPLOYMENT
WHERE INTER_EMPLOYEE_LEAVE_CANCEL.WF_REFERID = USER_LEAVE_CANCELLATION_HD.ID AND
USER_LEAVE_CANCELLATION_HD.REQUESTOR_ID = EMPLOYEE_EMPLOYMENT.EMPLOYEE_ID
UNION
SELECT 'LeaveCancel',
	'2. Agent',
         WF_AGENT.ID,
         WF_AGENT.STATUS,
	 0,
         WF_AGENT.CREATED_BY,
         WF_AGENT.CREATED_DATE,
         WF_AGENT.MODIFIED_BY,
         WF_AGENT.MODIFIED_DATE,
	 0,
	 ' ',
	 0,
	 ' ',
	 0
FROM WF_AGENT
WHERE ID IN(SELECT AGENTID FROM INTER_EMPLOYEE_LEAVE_CANCEL)
UNION
SELECT 'LeaveCancel',
	'3. Monitor',
         WF_MONITOR.AGENTID,
         WF_MONITOR.STATUS,
	 0,
         WF_MONITOR.CREATED_BY,
         WF_MONITOR.CREATED_DATE,
         WF_MONITOR.MODIFIED_BY,
         WF_MONITOR.MODIFIED_DATE,
	 ITEM_ID,
	 ' ',
	 WF_MONITOR.MONITOR_ID,
	 ' ',
	 0
FROM WF_MONITOR
WHERE AGENTID IN(SELECT AGENTID FROM INTER_EMPLOYEE_LEAVE_CANCEL)
UNION
SELECT 'LeaveCancel',
	'4. Recipient',
	( select min(agentid) from wf_monitor where monitor_id = WF_RECIPIENT.MONITOR_ID),
         WF_RECIPIENT.ACTION_STATUS,
	 WF_RECIPIENT.ENTITY_ID,
         WF_RECIPIENT.CREATED_BY,
         WF_RECIPIENT.CREATED_DATE,
         WF_RECIPIENT.MODIFIED_BY,
         WF_RECIPIENT.MODIFIED_DATE,
	 ITEM_ID,
	 WF_RECIPIENT.RECIPIENT_STATUS,
	 WF_RECIPIENT.MONITOR_ID,
	 EMPLOYEE_EMPLOYMENT.EMPLOYEE_STATUS,
	 WF_RECIPIENT.ID
FROM WF_RECIPIENT, EMPLOYEE_EMPLOYMENT
WHERE WF_RECIPIENT.ENTITY_ID = EMPLOYEE_EMPLOYMENT.EMPLOYEE_ID AND
MONITOR_ID IN( SELECT MONITOR_ID FROM WF_MONITOR WHERE AGENTID IN(SELECT AGENTID FROM INTER_EMPLOYEE_LEAVE_CANCEL))
UNION
SELECT 'Claim' as process,
	'1. Claim' as step,
         INTER_CLAIM_TRANS.AGENTID,
         INTER_CLAIM_TRANS.WF_STATUS,
         INTER_CLAIM_TRANS.EMPLOYEE_ID,
         INTER_CLAIM_TRANS.CREATED_BY,
         INTER_CLAIM_TRANS.CREATED_DATE,
         INTER_CLAIM_TRANS.MODIFIED_BY,
         INTER_CLAIM_TRANS.MODIFIED_DATE,
	      INTER_CLAIM_TRANS.ID as item_id,
	 ' ' as status,
 	 INTER_CLAIM_TRANS.MONITOR_ID,
 	 EMPLOYEE_EMPLOYMENT.EMPLOYEE_STATUS,
	 0
FROM INTER_CLAIM_TRANS, EMPLOYEE_EMPLOYMENT
WHERE INTER_CLAIM_TRANS.EMPLOYEE_ID = EMPLOYEE_EMPLOYMENT.EMPLOYEE_ID AND
DATASET = 'claimapplication'
UNION
SELECT 'Claim',
	'2. Agent',
         WF_AGENT.ID,
         WF_AGENT.STATUS,
	 0,
         WF_AGENT.CREATED_BY,
         WF_AGENT.CREATED_DATE,
         WF_AGENT.MODIFIED_BY,
         WF_AGENT.MODIFIED_DATE,
	 0,
	 ' ',
	 0,
	 ' ',
	 0
FROM WF_AGENT
WHERE ID IN (SELECT AGENTID FROM INTER_CLAIM_TRANS WHERE DATASET = 'claimapplication')
UNION
SELECT 'Claim',
	'3. Monitor',
         WF_MONITOR.AGENTID,
         WF_MONITOR.STATUS,
	 0,
         WF_MONITOR.CREATED_BY,
         WF_MONITOR.CREATED_DATE,
         WF_MONITOR.MODIFIED_BY,
         WF_MONITOR.MODIFIED_DATE,
	 ITEM_ID,
	 ' ',
	 WF_MONITOR.MONITOR_ID,
	 ' ',
	 0
FROM WF_MONITOR
WHERE AGENTID IN(SELECT AGENTID FROM INTER_CLAIM_TRANS WHERE DATASET = 'claimapplication')
UNION
SELECT 'Claim',
	'4. Recipient',
	( select min(agentid) from wf_monitor where monitor_id = WF_RECIPIENT.MONITOR_ID),
         WF_RECIPIENT.ACTION_STATUS,
	 WF_RECIPIENT.ENTITY_ID,
         WF_RECIPIENT.CREATED_BY,
         WF_RECIPIENT.CREATED_DATE,
         WF_RECIPIENT.MODIFIED_BY,
         WF_RECIPIENT.MODIFIED_DATE,
	 ITEM_ID,
	 WF_RECIPIENT.RECIPIENT_STATUS,
	 WF_RECIPIENT.MONITOR_ID,
	 EMPLOYEE_EMPLOYMENT.EMPLOYEE_STATUS,
	 WF_RECIPIENT.ID
FROM WF_RECIPIENT, EMPLOYEE_EMPLOYMENT
WHERE WF_RECIPIENT.ENTITY_ID = EMPLOYEE_EMPLOYMENT.EMPLOYEE_ID AND
MONITOR_ID IN( SELECT MONITOR_ID FROM WF_MONITOR WHERE AGENTID IN
                   ( SELECT AGENTID FROM INTER_CLAIM_TRANS WHERE DATASET = 'claimapplication'))
UNION
SELECT 'ClaimOther' as process,
	'1. ClaimOther' as step,
         INTER_CLAIM_TRANS.AGENTID,
         INTER_CLAIM_TRANS.WF_STATUS,
         INTER_CLAIM_TRANS.EMPLOYEE_ID,
         INTER_CLAIM_TRANS.CREATED_BY,
         INTER_CLAIM_TRANS.CREATED_DATE,
         INTER_CLAIM_TRANS.MODIFIED_BY,
         INTER_CLAIM_TRANS.MODIFIED_DATE,
	 INTER_CLAIM_TRANS.ID as item_id,
	 ' ' as status,
	 INTER_CLAIM_TRANS.MONITOR_ID,
	 EMPLOYEE_EMPLOYMENT.EMPLOYEE_STATUS,
	 0
FROM INTER_CLAIM_TRANS, EMPLOYEE_EMPLOYMENT
WHERE INTER_CLAIM_TRANS.EMPLOYEE_ID = EMPLOYEE_EMPLOYMENT.EMPLOYEE_ID AND
DATASET <> 'claimapplication'
UNION
SELECT 'ClaimOther',
	'2. Agent',
         WF_AGENT.ID,
         WF_AGENT.STATUS,
			0,
         WF_AGENT.CREATED_BY,
         WF_AGENT.CREATED_DATE,
         WF_AGENT.MODIFIED_BY,
         WF_AGENT.MODIFIED_DATE,
	 0,
	 ' ',
	 0,
	 ' ',
	 0
FROM WF_AGENT
WHERE ID IN (SELECT AGENTID FROM INTER_CLAIM_TRANS WHERE DATASET <> 'claimapplication')
UNION
SELECT 'ClaimOther',
	'3. Monitor',
         WF_MONITOR.AGENTID,
         WF_MONITOR.STATUS,
	 0,
         WF_MONITOR.CREATED_BY,
         WF_MONITOR.CREATED_DATE,
         WF_MONITOR.MODIFIED_BY,
         WF_MONITOR.MODIFIED_DATE,
	 ITEM_ID,
	 ' ',
	 WF_MONITOR.MONITOR_ID,
	 ' ',
	 0
FROM WF_MONITOR
WHERE AGENTID IN(SELECT AGENTID FROM INTER_CLAIM_TRANS WHERE DATASET <> 'claimapplication')
UNION
SELECT 'ClaimOther',
	'4. Recipient',
	( select min(agentid) from wf_monitor where monitor_id = WF_RECIPIENT.MONITOR_ID),
        WF_RECIPIENT.ACTION_STATUS,
	WF_RECIPIENT.ENTITY_ID,
        WF_RECIPIENT.CREATED_BY,
        WF_RECIPIENT.CREATED_DATE,
        WF_RECIPIENT.MODIFIED_BY,
        WF_RECIPIENT.MODIFIED_DATE,
	ITEM_ID,
	WF_RECIPIENT.RECIPIENT_STATUS,
	WF_RECIPIENT.MONITOR_ID,
	EMPLOYEE_EMPLOYMENT.EMPLOYEE_STATUS,
	WF_RECIPIENT.ID
    FROM WF_RECIPIENT, EMPLOYEE_EMPLOYMENT
WHERE WF_RECIPIENT.ENTITY_ID = EMPLOYEE_EMPLOYMENT.EMPLOYEE_ID AND
MONITOR_ID IN( SELECT MONITOR_ID FROM WF_MONITOR WHERE AGENTID IN
                   ( SELECT AGENTID FROM INTER_CLAIM_TRANS WHERE DATASET <> 'claimapplication'))
UNION
SELECT 'Appraisal' as process,
	'1. Appraisal' as step,
         INTER_AP_QFORM_HD.AGENTID,
         INTER_AP_QFORM_HD.WF_STATUS,
         INTER_AP_QFORM_HD.EMPLOYEE_ID,
         INTER_AP_QFORM_HD.CREATED_BY,
         INTER_AP_QFORM_HD.CREATED_DATE,
         INTER_AP_QFORM_HD.MODIFIED_BY,
         INTER_AP_QFORM_HD.MODIFIED_DATE,
 	 INTER_AP_QFORM_HD.ID as item_id,
	 ' ' as status,
	 INTER_AP_QFORM_HD.MONITOR_ID,
	 EMPLOYEE_EMPLOYMENT.EMPLOYEE_STATUS,
	 0
FROM INTER_AP_QFORM_HD, EMPLOYEE_EMPLOYMENT
WHERE INTER_AP_QFORM_HD.EMPLOYEE_ID = EMPLOYEE_EMPLOYMENT.EMPLOYEE_ID
UNION
SELECT 'Appraisal',
	'2. Agent',
         WF_AGENT.ID,
         WF_AGENT.STATUS,
			0,
         WF_AGENT.CREATED_BY,
         WF_AGENT.CREATED_DATE,
         WF_AGENT.MODIFIED_BY,
         WF_AGENT.MODIFIED_DATE,
	 0,
	 ' ',
	 0,
	 ' ',
	 0
FROM WF_AGENT
WHERE ID IN(SELECT AGENTID FROM INTER_AP_QFORM_HD)
UNION
SELECT 'Appraisal',
	'3. Monitor',
     	WF_MONITOR.AGENTID,
     	WF_MONITOR.STATUS,
     	0,
     	WF_MONITOR.CREATED_BY,
     	WF_MONITOR.CREATED_DATE,
     	WF_MONITOR.MODIFIED_BY,
     	WF_MONITOR.MODIFIED_DATE,
	ITEM_ID,
	' ',
	 WF_MONITOR.MONITOR_ID,
	' ',
	0
FROM WF_MONITOR
WHERE AGENTID IN(SELECT AGENTID FROM INTER_AP_QFORM_HD)
UNION
SELECT 'Appraisal',
	'4. Recipient',
	( select min(agentid) from wf_monitor where id = WF_RECIPIENT.MONITOR_ID),
         WF_RECIPIENT.ACTION_STATUS,
      	 WF_RECIPIENT.ENTITY_ID,
         WF_RECIPIENT.CREATED_BY,
         WF_RECIPIENT.CREATED_DATE,
         WF_RECIPIENT.MODIFIED_BY,
         WF_RECIPIENT.MODIFIED_DATE,
      	 ITEM_ID,
      	 WF_RECIPIENT.RECIPIENT_STATUS,
	 WF_RECIPIENT.MONITOR_ID,
	 EMPLOYEE_EMPLOYMENT.EMPLOYEE_STATUS,
	 WF_RECIPIENT.ID
FROM WF_RECIPIENT, EMPLOYEE_EMPLOYMENT
WHERE WF_RECIPIENT.ENTITY_ID = EMPLOYEE_EMPLOYMENT.EMPLOYEE_ID AND
MONITOR_ID IN( SELECT ID FROM WF_MONITOR WHERE AGENTID IN(SELECT AGENTID FROM INTER_AP_QFORM_HD))
UNION
SELECT 'GOTReq' as process,
	'1. gotrequisition' as step,
         INTER_OT_REQUISITION.AGENTID,
         INTER_OT_REQUISITION.WF_STATUS,
         INTER_OT_REQUISITION.EMPLOYEE_ID,
         INTER_OT_REQUISITION.CREATED_BY,
         INTER_OT_REQUISITION.CREATED_DATE,
         INTER_OT_REQUISITION.MODIFIED_BY,
         INTER_OT_REQUISITION.MODIFIED_DATE,
	      INTER_OT_REQUISITION.ID as item_id,
	 ' ' as status,
	 INTER_OT_REQUISITION.MONITOR_ID,
	 EMPLOYEE_EMPLOYMENT.EMPLOYEE_STATUS,
 	 0
FROM INTER_OT_REQUISITION, EMPLOYEE_EMPLOYMENT
 WHERE INTER_OT_REQUISITION.EMPLOYEE_ID = EMPLOYEE_EMPLOYMENT.EMPLOYEE_ID AND
DATASET = 'gotrequisition'
UNION
SELECT 'GOTReq',
	'2. Agent',
         WF_AGENT.ID,
         WF_AGENT.STATUS,
			0,
         WF_AGENT.CREATED_BY,
         WF_AGENT.CREATED_DATE,
         WF_AGENT.MODIFIED_BY,
         WF_AGENT.MODIFIED_DATE,
	0,
	' ',
	0,
	' ',
	0
FROM WF_AGENT
WHERE ID IN (SELECT AGENTID FROM INTER_OT_REQUISITION WHERE DATASET = 'gotrequisition')
UNION
SELECT 'GOTReq',
	'3. Monitor',
         WF_MONITOR.AGENTID,
         WF_MONITOR.STATUS,
	0,
         WF_MONITOR.CREATED_BY,
         WF_MONITOR.CREATED_DATE,
         WF_MONITOR.MODIFIED_BY,
         WF_MONITOR.MODIFIED_DATE,
	ITEM_ID,
	' ',
	 WF_MONITOR.MONITOR_ID,
 	' ',
	 0
FROM WF_MONITOR
WHERE ID IN (SELECT AGENTID FROM INTER_OT_REQUISITION WHERE DATASET = 'gotrequisition')
UNION
SELECT 'GOTReq',
	'4. Recipient',
	( select min(agentid) from wf_monitor where monitor_id = WF_RECIPIENT.MONITOR_ID),
         WF_RECIPIENT.ACTION_STATUS,
	 WF_RECIPIENT.ENTITY_ID,
         WF_RECIPIENT.CREATED_BY,
         WF_RECIPIENT.CREATED_DATE,
         WF_RECIPIENT.MODIFIED_BY,
         WF_RECIPIENT.MODIFIED_DATE,
	 ITEM_ID,
	 WF_RECIPIENT.RECIPIENT_STATUS,
	 WF_RECIPIENT.MONITOR_ID,
	 EMPLOYEE_EMPLOYMENT.EMPLOYEE_STATUS,
	 WF_RECIPIENT.ID
FROM WF_RECIPIENT, EMPLOYEE_EMPLOYMENT
WHERE WF_RECIPIENT.ENTITY_ID = EMPLOYEE_EMPLOYMENT.EMPLOYEE_ID AND
MONITOR_ID IN( SELECT MONITOR_ID FROM WF_MONITOR WHERE AGENTID IN
                    (SELECT AGENTID FROM INTER_OT_REQUISITION WHERE DATASET = 'gotrequisition'))
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
create view [dbo].[vusr_clock_entry] 
as
select * from oritms_trng.dbo.vusr_clock_entry
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON


CREATE VIEW [dbo].[VUSR_DOC_EDS_EMPLOYEE]
(FIRST_NAME, LAST_NAME, DISPLAY_NAME, BIRTH_DATE, MARITAL_STATUS, EMPLOYMENT_STATUS, JOB_TITLE, EMPLOYMENT_TYPE, JOB_LEVEL,
START_DATE, END_DATE, REASON_CHANGE, CONTRACT_PROB_PD, WORK_HRS_WEEK, TERMINATION_NOTICE_PD, ENTITY, IMMEDIATE_MANAGER,
BASE_CITY, COST_CENTER_DETAILS, REGION, LOCATION, COST_CENTER_CODE, COST_CENTER_NAME, COST_CENTER_PERCENT, CONTACT_ID, SHIFT_WORKER_STATUS)
AS
SELECT dbo.fusr_getNamePart(a.employee_name, 'FN'), dbo.fusr_getNamePart(a.employee_name, 'LN'), a.employee_name,
	CONVERT(VARCHAR(10), a.birth_date, 110),
	case a.marital_status 
		when 'S' then '1'
		when 'M' then '2'
		when 'D' then '3'
		when 'E' then '5' 
		when null then ' '
	end, 
	(SELECT x.eds FROM user_qsieds_etstatus x WHERE x.employee_id = a.employee_id),	(SELECT x.position_description FROM position x WHERE x.position_code = b.position_code), 
	(SELECT x.eds FROM user_qsieds_ettype x WHERE x.ori = 
		(SELECT y.service_code FROM employee_service y WHERE y.employee_id = a.employee_id AND y.service_date = 
			(SELECT MAX(y1.service_date) FROM employee_service y1 WHERE y1.employee_id = y.employee_id))), 
	case b.grade_code
		when '1' then '2'
		when '2' then '3'
		when '3' then '4'
		when '4' then '5'
		when '5' then '6'
		when '6' then '7'
		when '7' then '8'
		when '8' then '9'
		when '9' then '10'
		when null then ' '
	end,
	CONVERT(VARCHAR(10),d.activity_date,110), CONVERT(VARCHAR(10),b.date_resigned,110), 
	(SELECT x.reason_description FROM reason x WHERE x.reason_code = d.reason_code), b.probation_period, 0, 0, 
	case c.company_name
		when 'Azure Wireless Pty.Ltd.' then '37'
		when 'DOCOMO interTouch Australia Pty. Ltd.' then '36'
		when 'Inter-Touch Pty. Ltd.' then '22'
		when 'DOCOMO interTouch (Bahrain) W.L.L.' then '2628'
		when 'DOCOMO interTouch (BRASIL) Servicos De Informatica Ltda.' then '121'
		when 'interTouch Information Technology (Shanghai) Co. Ltd.' then '3629'
		when 'Inter-Touch Software Information (Shanghai) Co., Ltd.' then '34'
		when 'MagiNet Shanghai Co., Ltd.' then '13'
		when 'Inter-Touch Egypt Limited' then '25'
		when 'MagiNet Interactive Egypt Ltd.' then '14'
		when 'DOCOMO interTouch Australia Pty. Ltd. - Fiji Branch' then '39'
		when 'DOCOMO interTouch (AP) Limited' then '3458'
		when 'DOCOMO interTouch (Mariana), Inc.' then '5'
		when 'DOCOMO interTouch Company Limited' then '19'
		when 'Inter-Touch Hong Kong' then '26'
		when 'DOCOMO interTouch (India) Pvt. Ltd.' then '41'
		when 'Inter-Touch India' then '32'
		when 'Percipia India' then '119'
		when 'PT MagiNet Indonesia' then '40'
		when 'DOCOMO interTouch (Japan) K.K.' then '4'
		when 'Inter-Touch Japan' then '30'
		when 'DOCOMO interTouch (Jordan) LLC' then '1'
		when 'DOCOMO interTouch Limiteda . Sucursal de Macau' then '20'
		when 'E-Room Sdn. Bhd.' then '10'
		when 'inter-touch (Malaysia) Sdn. Bhd.' then '9'
		when 'DCMIT MEXICO S. DE R.L. DE C.V.' then '3451'
		when 'MagiNet Morocco' then '120'
		when 'DOCOMO interTouch (New Zealand) Ltd.' then '38'
		when 'DOCOMO interTouch Business Solutions, Inc.' then '3652'
		when 'DOCOMO interTouch Philippines Inc.' then '24'
		when 'DOCOMO interTouch Pte Ltd' then '134'
		when 'MagiNet Philippines Inc.' then '6'
		when 'DOCOMO interTouch Interactive Pte Ltd.' then '15'
		when 'DOCOMO interTouch Pte. Ltd.' then '21'
		when 'MagiNet South Africa Inc.' then '3'
		when 'DOCOMO interTouch Co., Ltd' then '3624'
		when 'DOCOMO interTouch Interactive Pte Ltd Korea Branch' then '3625'
		when 'DOCOMO interTouch (South Korea) Ltd' then '7'
		when 'Inter-Touch South Korea' then '29'
		when 'DOCOMO interTouch Lanka (Private) Limited' then '132'
		when 'DOCOMO interTouch Pte. Ltd. (Taiwan Branch)' then '35'
		when 'May Shyh Corporation' then '17'
		when 'DOCOMO interTouch (Thailand) Limited' then '33'
		when 'MagiNet Interactive (Thailand) Ltd.' then '8'
		when 'DOCOMO INTERTOUCH INTERAKTIF HIZMETLER TICARET ANONIM SIRKETI' then '11'
		when 'DOCOMO interTouch (ME&NA) FZ-LLC' then '2'
		when 'Inter-Touch (Middle East) FZ-LLC' then '28'
		when 'DOCOMO interTouch EMEA Ltd' then '27'
		when 'DOCOMO interTouch (USA) Inc.' then '23'
		when 'DOCOMO interTouch (USA) Inc. (ex-Percipia USA)' then '12'
		when 'Nomadix, Inc.' then '16'
		when 'DOCOMO interTouch (Vietnam) Company Limited' then '3462'
		when 'MagiNet Vietnam' then '18'
		when null then ' '
    end, 
	8044, 177, ' ', ' ', ' ', 
	case b.cost_center
		when 'Global Operations-Corporate' then '34'
		when 'Technical Support' then '5'
		when 'Legal - Contracts' then '9'
		when 'Centralised Account Managers' then '14'
		when 'Project Management' then '19'
		when 'Regional Helpdesk' then '23'
		when 'Major Account - Regional' then '24'
		when 'Unknown' then '27'
		when 'Corporate' then '1'
		when 'Finance-Corporate' then '2'
		when 'Operations-Regional' then '3'
		when 'Sales-Regional' then '4'
		when 'Marketing-Corporate' then '6'
		when 'Global Accounts-Corporate' then '7'
		when 'New Business-Corporate' then '8'
		when 'Network Operations-Corporate' then '11'
		when 'Legal-Corporate' then '13'
		when 'IS Operations-Corporate' then '15'
		when 'Account Management' then '16'
		when 'Commercial Operations' then '17'
		when 'Human Resources-Corporate' then '18'
		when 'Regional Management' then '20'
		when 'Product Management-Corporate' then '21'
		when 'Product Planning-Corporate' then '25'
		when 'Integration-Corporate' then '26'
		when 'Product Implementation-Corporate' then '28'
		when 'Procurement and Logistics-Global' then '29'
		when 'Procurement and Logistics-Regional' then '30'
		when 'Dedicated Engineers-Regional' then '31'
		when 'Content Management-Global' then '32'
		when 'Content Management-Regional' then '33'
		when 'Finance-Regional' then '35'
		when 'Network Operations-Regional' then '36'
		when 'Helpdesk-Regional' then '37'
		when 'IS Development-Corporate' then '22'
		when 'Human Resources-Regional' then '38'
		when 'Product Design and Development-Corporate' then '10'
		when 'Support Services Management' then '39'
		when 'Managed Services Management' then '40'
		when 'Nomadix R&D' then '42'
		when 'Quality Assurance' then '43'
		when 'Helpdesk Corporate (Internal)' then '12'
		when 'Helpdesk Corporate (External)' then '41'
		when null then ' '
	end,
	isnull((select x.cost_center_description from cost_center x where x.cost_center_code = b.cost_center),' '),
	0, a.usr_doc_contactid, b.usr_doc_shiftworker
FROM employee_biodata as a,
	employee_employment as b,
	company_profile as c,
	pay_activities_mth as d
WHERE a.employee_id = b.employee_id AND b.company_code = c.company_code --AND b.employee_status = 'A'
	AND b.employee_id = d.employee_id 
	AND d.activity_date = (SELECT MAX(x.activity_date) FROM pay_activities_mth x WHERE x.employee_id = d.employee_id)
UNION
SELECT dbo.fusr_getNamePart(a.employee_name, 'FN'), dbo.fusr_getNamePart(a.employee_name, 'LN'), a.employee_name,
	CONVERT(VARCHAR(10), a.birth_date, 110),
	case a.marital_status 
		when 'S' then '1'
		when 'M' then '2'
		when 'D' then '3'
		when 'E' then '5' 
		when null then ' '
	end, 
	(SELECT x.eds FROM user_qsieds_etstatus x WHERE  x.employee_id = a.employee_id),	(SELECT x.position_description FROM position x WHERE x.position_code = b.position_code), 
	(SELECT x.eds FROM user_qsieds_ettype x WHERE x.ori = 
		(SELECT y.service_code FROM employee_service y WHERE y.employee_id = a.employee_id AND y.service_date = 
			(SELECT MAX(y1.service_date) FROM employee_service y1 WHERE y1.employee_id = y.employee_id))), 
	case b.grade_code
		when '1' then '2'
		when '2' then '3'
		when '3' then '4'
		when '4' then '5'
		when '5' then '6'
		when '6' then '7'
		when '7' then '8'
		when '8' then '9'
		when '9' then '10'
		when null then ' '
	end,
	CONVERT(VARCHAR(10),d.activity_date,110), CONVERT(VARCHAR(10),b.date_resigned,110), 
	(SELECT x.reason_description FROM reason x WHERE x.reason_code = d.reason_code), b.probation_period, 0, 0, 
	case c.company_name
		when 'Azure Wireless Pty.Ltd.' then '37'
		when 'DOCOMO interTouch Australia Pty. Ltd.' then '36'
		when 'Inter-Touch Pty. Ltd.' then '22'
		when 'DOCOMO interTouch (Bahrain) W.L.L.' then '2628'
		when 'DOCOMO interTouch (BRASIL) Servicos De Informatica Ltda.' then '121'
		when 'interTouch Information Technology (Shanghai) Co. Ltd.' then '3629'
		when 'Inter-Touch Software Information (Shanghai) Co., Ltd.' then '34'
		when 'MagiNet Shanghai Co., Ltd.' then '13'
		when 'Inter-Touch Egypt Limited' then '25'
		when 'MagiNet Interactive Egypt Ltd.' then '14'
		when 'DOCOMO interTouch Australia Pty. Ltd. - Fiji Branch' then '39'
		when 'DOCOMO interTouch (AP) Limited' then '3458'
		when 'DOCOMO interTouch (Mariana), Inc.' then '5'
		when 'DOCOMO interTouch Company Limited' then '19'
		when 'Inter-Touch Hong Kong' then '26'
		when 'DOCOMO interTouch (India) Pvt. Ltd.' then '41'
		when 'Inter-Touch India' then '32'
		when 'Percipia India' then '119'
		when 'PT MagiNet Indonesia' then '40'
		when 'DOCOMO interTouch (Japan) K.K.' then '4'
		when 'Inter-Touch Japan' then '30'
		when 'DOCOMO interTouch (Jordan) LLC' then '1'
		when 'DOCOMO interTouch Limiteda . Sucursal de Macau' then '20'
		when 'E-Room Sdn. Bhd.' then '10'
		when 'inter-touch (Malaysia) Sdn. Bhd.' then '9'
		when 'DCMIT MEXICO S. DE R.L. DE C.V.' then '3451'
		when 'MagiNet Morocco' then '120'
		when 'DOCOMO interTouch (New Zealand) Ltd.' then '38'
		when 'DOCOMO interTouch Business Solutions, Inc.' then '3652'
		when 'DOCOMO interTouch Philippines Inc.' then '24'
		when 'DOCOMO interTouch Pte Ltd' then '134'
		when 'MagiNet Philippines Inc.' then '6'
		when 'DOCOMO interTouch Interactive Pte Ltd.' then '15'
		when 'DOCOMO interTouch Pte. Ltd.' then '21'
		when 'MagiNet South Africa Inc.' then '3'
		when 'DOCOMO interTouch Co., Ltd' then '3624'
		when 'DOCOMO interTouch Interactive Pte Ltd Korea Branch' then '3625'
		when 'DOCOMO interTouch (South Korea) Ltd' then '7'
		when 'Inter-Touch South Korea' then '29'
		when 'DOCOMO interTouch Lanka (Private) Limited' then '132'
		when 'DOCOMO interTouch Pte. Ltd. (Taiwan Branch)' then '35'
		when 'May Shyh Corporation' then '17'
		when 'DOCOMO interTouch (Thailand) Limited' then '33'
		when 'MagiNet Interactive (Thailand) Ltd.' then '8'
		when 'DOCOMO INTERTOUCH INTERAKTIF HIZMETLER TICARET ANONIM SIRKETI' then '11'
		when 'DOCOMO interTouch (ME&NA) FZ-LLC' then '2'
		when 'Inter-Touch (Middle East) FZ-LLC' then '28'
		when 'DOCOMO interTouch EMEA Ltd' then '27'
		when 'DOCOMO interTouch (USA) Inc.' then '23'
		when 'DOCOMO interTouch (USA) Inc. (ex-Percipia USA)' then '12'
		when 'Nomadix, Inc.' then '16'
		when 'DOCOMO interTouch (Vietnam) Company Limited' then '3462'
		when 'MagiNet Vietnam' then '18'
		when null then ' '
    end, 
	8044, 177, ' ', ' ', ' ', 
	case b.cost_center
		when 'Global Operations-Corporate' then '34'
		when 'Technical Support' then '5'
		when 'Legal - Contracts' then '9'
		when 'Centralised Account Managers' then '14'
		when 'Project Management' then '19'
		when 'Regional Helpdesk' then '23'
		when 'Major Account - Regional' then '24'
		when 'Unknown' then '27'
		when 'Corporate' then '1'
		when 'Finance-Corporate' then '2'
		when 'Operations-Regional' then '3'
		when 'Sales-Regional' then '4'
		when 'Marketing-Corporate' then '6'
		when 'Global Accounts-Corporate' then '7'
		when 'New Business-Corporate' then '8'
		when 'Network Operations-Corporate' then '11'
		when 'Legal-Corporate' then '13'
		when 'IS Operations-Corporate' then '15'
		when 'Account Management' then '16'
		when 'Commercial Operations' then '17'
		when 'Human Resources-Corporate' then '18'
		when 'Regional Management' then '20'
		when 'Product Management-Corporate' then '21'
		when 'Product Planning-Corporate' then '25'
		when 'Integration-Corporate' then '26'
		when 'Product Implementation-Corporate' then '28'
		when 'Procurement and Logistics-Global' then '29'
		when 'Procurement and Logistics-Regional' then '30'
		when 'Dedicated Engineers-Regional' then '31'
		when 'Content Management-Global' then '32'
		when 'Content Management-Regional' then '33'
		when 'Finance-Regional' then '35'
		when 'Network Operations-Regional' then '36'
		when 'Helpdesk-Regional' then '37'
		when 'IS Development-Corporate' then '22'
		when 'Human Resources-Regional' then '38'
		when 'Product Design and Development-Corporate' then '10'
		when 'Support Services Management' then '39'
		when 'Managed Services Management' then '40'
		when 'Nomadix R&D' then '42'
		when 'Quality Assurance' then '43'
		when 'Helpdesk Corporate (Internal)' then '12'
		when 'Helpdesk Corporate (External)' then '41'
		when null then ' '
	end,
	isnull((select x.cost_center_description from cost_center x where x.cost_center_code = b.cost_center),' '),
	0, a.usr_doc_contactid, b.usr_doc_shiftworker
FROM employee_biodata as a,
	employee_employment as b,
	company_profile as c,
	pay_activities_his as d
WHERE a.employee_id = b.employee_id AND b.company_code = c.company_code --AND b.employee_status = 'A'
	AND b.employee_id = d.employee_id 
	AND b.employee_id NOT IN (SELECT x.employee_id FROM pay_activities_mth x)
	AND d.activity_date = (SELECT MAX(x.activity_date) FROM pay_activities_his x WHERE x.employee_id = d.employee_id)
UNION
SELECT dbo.fusr_getNamePart(a.employee_name, 'FN'), dbo.fusr_getNamePart(a.employee_name, 'LN'), a.employee_name,
	CONVERT(VARCHAR(10), a.birth_date, 110),
	case a.marital_status 
		when 'S' then '1'
		when 'M' then '2'
		when 'D' then '3'
		when 'E' then '5' 
		when null then ' '
	end, 
	(SELECT x.eds FROM user_qsieds_etstatus x WHERE  x.employee_id = a.employee_id),	(SELECT x.position_description FROM position x WHERE x.position_code = b.position_code), 
	(SELECT x.eds FROM user_qsieds_ettype x WHERE x.ori = 
		(SELECT y.service_code FROM employee_service y WHERE y.employee_id = a.employee_id AND y.service_date = 
			(SELECT MAX(y1.service_date) FROM employee_service y1 WHERE y1.employee_id = y.employee_id))),
	case b.grade_code
		when '1' then '2'
		when '2' then '3'
		when '3' then '4'
		when '4' then '5'
		when '5' then '6'
		when '6' then '7'
		when '7' then '8'
		when '8' then '9'
		when '9' then '10'
		when null then ' '
	end,
	CONVERT(VARCHAR(10),b.date_joined,110), CONVERT(VARCHAR(10),b.date_resigned,110), 
	' ', b.probation_period, 0, 0, 
	case c.company_name
		when 'Azure Wireless Pty.Ltd.' then '37'
		when 'DOCOMO interTouch Australia Pty. Ltd.' then '36'
		when 'Inter-Touch Pty. Ltd.' then '22'
		when 'DOCOMO interTouch (Bahrain) W.L.L.' then '2628'
		when 'DOCOMO interTouch (BRASIL) Servicos De Informatica Ltda.' then '121'
		when 'interTouch Information Technology (Shanghai) Co. Ltd.' then '3629'
		when 'Inter-Touch Software Information (Shanghai) Co., Ltd.' then '34'
		when 'MagiNet Shanghai Co., Ltd.' then '13'
		when 'Inter-Touch Egypt Limited' then '25'
		when 'MagiNet Interactive Egypt Ltd.' then '14'
		when 'DOCOMO interTouch Australia Pty. Ltd. - Fiji Branch' then '39'
		when 'DOCOMO interTouch (AP) Limited' then '3458'
		when 'DOCOMO interTouch (Mariana), Inc.' then '5'
		when 'DOCOMO interTouch Company Limited' then '19'
		when 'Inter-Touch Hong Kong' then '26'
		when 'DOCOMO interTouch (India) Pvt. Ltd.' then '41'
		when 'Inter-Touch India' then '32'
		when 'Percipia India' then '119'
		when 'PT MagiNet Indonesia' then '40'
		when 'DOCOMO interTouch (Japan) K.K.' then '4'
		when 'Inter-Touch Japan' then '30'
		when 'DOCOMO interTouch (Jordan) LLC' then '1'
		when 'DOCOMO interTouch Limiteda . Sucursal de Macau' then '20'
		when 'E-Room Sdn. Bhd.' then '10'
		when 'inter-touch (Malaysia) Sdn. Bhd.' then '9'
		when 'DCMIT MEXICO S. DE R.L. DE C.V.' then '3451'
		when 'MagiNet Morocco' then '120'
		when 'DOCOMO interTouch (New Zealand) Ltd.' then '38'
		when 'DOCOMO interTouch Business Solutions, Inc.' then '3652'
		when 'DOCOMO interTouch Philippines Inc.' then '24'
		when 'DOCOMO interTouch Pte Ltd' then '134'
		when 'MagiNet Philippines Inc.' then '6'
		when 'DOCOMO interTouch Interactive Pte Ltd.' then '15'
		when 'DOCOMO interTouch Pte. Ltd.' then '21'
		when 'MagiNet South Africa Inc.' then '3'
		when 'DOCOMO interTouch Co., Ltd' then '3624'
		when 'DOCOMO interTouch Interactive Pte Ltd Korea Branch' then '3625'
		when 'DOCOMO interTouch (South Korea) Ltd' then '7'
		when 'Inter-Touch South Korea' then '29'
		when 'DOCOMO interTouch Lanka (Private) Limited' then '132'
		when 'DOCOMO interTouch Pte. Ltd. (Taiwan Branch)' then '35'
		when 'May Shyh Corporation' then '17'
		when 'DOCOMO interTouch (Thailand) Limited' then '33'
		when 'MagiNet Interactive (Thailand) Ltd.' then '8'
		when 'DOCOMO INTERTOUCH INTERAKTIF HIZMETLER TICARET ANONIM SIRKETI' then '11'
		when 'DOCOMO interTouch (ME&NA) FZ-LLC' then '2'
		when 'Inter-Touch (Middle East) FZ-LLC' then '28'
		when 'DOCOMO interTouch EMEA Ltd' then '27'
		when 'DOCOMO interTouch (USA) Inc.' then '23'
		when 'DOCOMO interTouch (USA) Inc. (ex-Percipia USA)' then '12'
		when 'Nomadix, Inc.' then '16'
		when 'DOCOMO interTouch (Vietnam) Company Limited' then '3462'
		when 'MagiNet Vietnam' then '18'
		when null then ' '
    end, 
	8044, 177, ' ', ' ', ' ', 
	case b.cost_center
		when 'Global Operations-Corporate' then '34'
		when 'Technical Support' then '5'
		when 'Legal - Contracts' then '9'
		when 'Centralised Account Managers' then '14'
		when 'Project Management' then '19'
		when 'Regional Helpdesk' then '23'
		when 'Major Account - Regional' then '24'
		when 'Unknown' then '27'
		when 'Corporate' then '1'
		when 'Finance-Corporate' then '2'
		when 'Operations-Regional' then '3'
		when 'Sales-Regional' then '4'
		when 'Marketing-Corporate' then '6'
		when 'Global Accounts-Corporate' then '7'
		when 'New Business-Corporate' then '8'
		when 'Network Operations-Corporate' then '11'
		when 'Legal-Corporate' then '13'
		when 'IS Operations-Corporate' then '15'
		when 'Account Management' then '16'
		when 'Commercial Operations' then '17'
		when 'Human Resources-Corporate' then '18'
		when 'Regional Management' then '20'
		when 'Product Management-Corporate' then '21'
		when 'Product Planning-Corporate' then '25'
		when 'Integration-Corporate' then '26'
		when 'Product Implementation-Corporate' then '28'
		when 'Procurement and Logistics-Global' then '29'
		when 'Procurement and Logistics-Regional' then '30'
		when 'Dedicated Engineers-Regional' then '31'
		when 'Content Management-Global' then '32'
		when 'Content Management-Regional' then '33'
		when 'Finance-Regional' then '35'
		when 'Network Operations-Regional' then '36'
		when 'Helpdesk-Regional' then '37'
		when 'IS Development-Corporate' then '22'
		when 'Human Resources-Regional' then '38'
		when 'Product Design and Development-Corporate' then '10'
		when 'Support Services Management' then '39'
		when 'Managed Services Management' then '40'
		when 'Nomadix R&D' then '42'
		when 'Quality Assurance' then '43'
		when 'Helpdesk Corporate (Internal)' then '12'
		when 'Helpdesk Corporate (External)' then '41'
		when null then ' '
	end,
	isnull((select x.cost_center_description from cost_center x where x.cost_center_code = b.cost_center),' '),
	0, a.usr_doc_contactid, b.usr_doc_shiftworker
FROM employee_biodata as a,
	employee_employment as b,
	company_profile as c
WHERE a.employee_id = b.employee_id AND b.company_code = c.company_code --AND b.employee_status = 'A'
	AND (b.employee_id NOT IN (SELECT x.employee_id FROM pay_activities_mth x) 
		AND b.employee_id NOT IN (SELECT x.employee_id FROM pay_activities_his x))


SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON

CREATE VIEW [dbo].[VUSR_DOC_EDS_EMPLOYEE_old]
(FIRST_NAME, LAST_NAME, DISPLAY_NAME, BIRTH_DATE, MARITAL_STATUS, EMPLOYMENT_STATUS, JOB_TITLE, EMPLOYMENT_TYPE, JOB_LEVEL,
START_DATE, END_DATE, REASON_CHANGE, CONTRACT_PROB_PD, WORK_HRS_WEEK, TERMINATION_NOTICE_PD, ENTITY, IMMEDIATE_MANAGER,
BASE_CITY, COST_CENTER_DETAILS, REGION, LOCATION, COST_CENTER_CODE, COST_CENTER_NAME, COST_CENTER_PERCENT, CONTACT_ID, SHIFT_WORKER_STATUS)
AS
SELECT dbo.fusr_getNamePart(a.employee_name, 'FN'), dbo.fusr_getNamePart(a.employee_name, 'LN'), a.employee_name,
	CONVERT(VARCHAR(10), a.birth_date, 110),
	case a.marital_status 
		when 'S' then '1'
		when 'M' then '2'
		when 'D' then '3'
		when 'E' then '5' 
		when null then ' '
	end, 
	(SELECT x.eds FROM user_qsieds_etstatus x WHERE x.employee_id = a.employee_id),	(SELECT x.position_description FROM position x WHERE x.position_code = b.position_code), 
	(SELECT x.eds FROM user_qsieds_ettype x WHERE x.ori = 
		(SELECT y.service_code FROM employee_service y WHERE y.employee_id = a.employee_id AND y.service_date = 
			(SELECT MAX(y1.service_date) FROM employee_service y1 WHERE y1.employee_id = y.employee_id))), 
	case b.grade_code
		when '1' then '2'
		when '2' then '3'
		when '3' then '4'
		when '4' then '5'
		when '5' then '6'
		when '6' then '7'
		when '7' then '8'
		when '8' then '9'
		when '9' then '10'
		when null then ' '
	end,
	CONVERT(VARCHAR(10),d.activity_date,110), CONVERT(VARCHAR(10),b.date_resigned,110), 
	(SELECT x.reason_description FROM reason x WHERE x.reason_code = d.reason_code), b.probation_period, 0, 0, 
	case c.company_name
		when 'Azure Wireless Pty.Ltd.' then '37'
		when 'DOCOMO interTouch Australia Pty. Ltd.' then '36'
		when 'Inter-Touch Pty. Ltd.' then '22'
		when 'DOCOMO interTouch (Bahrain) W.L.L.' then '2628'
		when 'DOCOMO interTouch (BRASIL) Servicos De Informatica Ltda.' then '121'
		when 'interTouch Information Technology (Shanghai) Co. Ltd.' then '3629'
		when 'Inter-Touch Software Information (Shanghai) Co., Ltd.' then '34'
		when 'MagiNet Shanghai Co., Ltd.' then '13'
		when 'Inter-Touch Egypt Limited' then '25'
		when 'MagiNet Interactive Egypt Ltd.' then '14'
		when 'DOCOMO interTouch Australia Pty. Ltd. - Fiji Branch' then '39'
		when 'DOCOMO interTouch (AP) Limited' then '3458'
		when 'DOCOMO interTouch (Mariana), Inc.' then '5'
		when 'DOCOMO interTouch Company Limited' then '19'
		when 'Inter-Touch Hong Kong' then '26'
		when 'DOCOMO interTouch (India) Pvt. Ltd.' then '41'
		when 'Inter-Touch India' then '32'
		when 'Percipia India' then '119'
		when 'PT MagiNet Indonesia' then '40'
		when 'DOCOMO interTouch (Japan) K.K.' then '4'
		when 'Inter-Touch Japan' then '30'
		when 'DOCOMO interTouch (Jordan) LLC' then '1'
		when 'DOCOMO interTouch Limiteda . Sucursal de Macau' then '20'
		when 'E-Room Sdn. Bhd.' then '10'
		when 'inter-touch (Malaysia) Sdn. Bhd.' then '9'
		when 'DCMIT MEXICO S. DE R.L. DE C.V.' then '3451'
		when 'MagiNet Morocco' then '120'
		when 'DOCOMO interTouch (New Zealand) Ltd.' then '38'
		when 'DOCOMO interTouch Business Solutions, Inc.' then '3652'
		when 'DOCOMO interTouch Philippines Inc.' then '24'
		when 'DOCOMO interTouch Pte Ltd' then '134'
		when 'MagiNet Philippines Inc.' then '6'
		when 'DOCOMO interTouch Interactive Pte Ltd.' then '15'
		when 'DOCOMO interTouch Pte. Ltd.' then '21'
		when 'MagiNet South Africa Inc.' then '3'
		when 'DOCOMO interTouch Co., Ltd' then '3624'
		when 'DOCOMO interTouch Interactive Pte Ltd Korea Branch' then '3625'
		when 'DOCOMO interTouch (South Korea) Ltd' then '7'
		when 'Inter-Touch South Korea' then '29'
		when 'DOCOMO interTouch Lanka (Private) Limited' then '132'
		when 'DOCOMO interTouch Pte. Ltd. (Taiwan Branch)' then '35'
		when 'May Shyh Corporation' then '17'
		when 'DOCOMO interTouch (Thailand) Limited' then '33'
		when 'MagiNet Interactive (Thailand) Ltd.' then '8'
		when 'DOCOMO INTERTOUCH INTERAKTIF HIZMETLER TICARET ANONIM SIRKETI' then '11'
		when 'DOCOMO interTouch (ME&NA) FZ-LLC' then '2'
		when 'Inter-Touch (Middle East) FZ-LLC' then '28'
		when 'DOCOMO interTouch EMEA Ltd' then '27'
		when 'DOCOMO interTouch (USA) Inc.' then '23'
		when 'DOCOMO interTouch (USA) Inc. (ex-Percipia USA)' then '12'
		when 'Nomadix, Inc.' then '16'
		when 'DOCOMO interTouch (Vietnam) Company Limited' then '3462'
		when 'MagiNet Vietnam' then '18'
		when null then ' '
    end, 
	8044, 177, ' ', ' ', ' ', 
	case b.cost_center
		when 'Global Operations-Corporate' then '34'
		when 'Technical Support' then '5'
		when 'Legal - Contracts' then '9'
		when 'Centralised Account Managers' then '14'
		when 'Project Management' then '19'
		when 'Regional Helpdesk' then '23'
		when 'Major Account - Regional' then '24'
		when 'Unknown' then '27'
		when 'Corporate' then '1'
		when 'Finance-Corporate' then '2'
		when 'Operations-Regional' then '3'
		when 'Sales-Regional' then '4'
		when 'Marketing-Corporate' then '6'
		when 'Global Accounts-Corporate' then '7'
		when 'New Business-Corporate' then '8'
		when 'Network Operations-Corporate' then '11'
		when 'Legal-Corporate' then '13'
		when 'IS Operations-Corporate' then '15'
		when 'Account Management' then '16'
		when 'Commercial Operations' then '17'
		when 'Human Resources-Corporate' then '18'
		when 'Regional Management' then '20'
		when 'Product Management-Corporate' then '21'
		when 'Product Planning-Corporate' then '25'
		when 'Integration-Corporate' then '26'
		when 'Product Implementation-Corporate' then '28'
		when 'Procurement and Logistics-Global' then '29'
		when 'Procurement and Logistics-Regional' then '30'
		when 'Dedicated Engineers-Regional' then '31'
		when 'Content Management-Global' then '32'
		when 'Content Management-Regional' then '33'
		when 'Finance-Regional' then '35'
		when 'Network Operations-Regional' then '36'
		when 'Helpdesk-Regional' then '37'
		when 'IS Development-Corporate' then '22'
		when 'Human Resources-Regional' then '38'
		when 'Product Design and Development-Corporate' then '10'
		when 'Support Services Management' then '39'
		when 'Managed Services Management' then '40'
		when 'Nomadix R&D' then '42'
		when 'Quality Assurance' then '43'
		when 'Helpdesk Corporate (Internal)' then '12'
		when 'Helpdesk Corporate (External)' then '41'
		when null then ' '
	end,
	isnull((select x.cost_center_description from cost_center x where x.cost_center_code = b.cost_center),' '),
	0, a.usr_doc_contactid, b.usr_doc_shiftworker
FROM employee_biodata as a,
	employee_employment as b,
	company_profile as c,
	pay_activities_mth as d
WHERE a.employee_id = b.employee_id AND b.company_code = c.company_code AND b.employee_status = 'A'
	AND b.employee_id = d.employee_id 
	AND d.activity_date = (SELECT MAX(x.activity_date) FROM pay_activities_mth x WHERE x.employee_id = d.employee_id)
UNION
SELECT dbo.fusr_getNamePart(a.employee_name, 'FN'), dbo.fusr_getNamePart(a.employee_name, 'LN'), a.employee_name,
	CONVERT(VARCHAR(10), a.birth_date, 110),
	case a.marital_status 
		when 'S' then '1'
		when 'M' then '2'
		when 'D' then '3'
		when 'E' then '5' 
		when null then ' '
	end, 
	(SELECT x.eds FROM user_qsieds_etstatus x WHERE  x.employee_id = a.employee_id),	(SELECT x.position_description FROM position x WHERE x.position_code = b.position_code), 
	(SELECT x.eds FROM user_qsieds_ettype x WHERE x.ori = 
		(SELECT y.service_code FROM employee_service y WHERE y.employee_id = a.employee_id AND y.service_date = 
			(SELECT MAX(y1.service_date) FROM employee_service y1 WHERE y1.employee_id = y.employee_id))), 
	case b.grade_code
		when '1' then '2'
		when '2' then '3'
		when '3' then '4'
		when '4' then '5'
		when '5' then '6'
		when '6' then '7'
		when '7' then '8'
		when '8' then '9'
		when '9' then '10'
		when null then ' '
	end,
	CONVERT(VARCHAR(10),d.activity_date,110), CONVERT(VARCHAR(10),b.date_resigned,110), 
	(SELECT x.reason_description FROM reason x WHERE x.reason_code = d.reason_code), b.probation_period, 0, 0, 
	case c.company_name
		when 'Azure Wireless Pty.Ltd.' then '37'
		when 'DOCOMO interTouch Australia Pty. Ltd.' then '36'
		when 'Inter-Touch Pty. Ltd.' then '22'
		when 'DOCOMO interTouch (Bahrain) W.L.L.' then '2628'
		when 'DOCOMO interTouch (BRASIL) Servicos De Informatica Ltda.' then '121'
		when 'interTouch Information Technology (Shanghai) Co. Ltd.' then '3629'
		when 'Inter-Touch Software Information (Shanghai) Co., Ltd.' then '34'
		when 'MagiNet Shanghai Co., Ltd.' then '13'
		when 'Inter-Touch Egypt Limited' then '25'
		when 'MagiNet Interactive Egypt Ltd.' then '14'
		when 'DOCOMO interTouch Australia Pty. Ltd. - Fiji Branch' then '39'
		when 'DOCOMO interTouch (AP) Limited' then '3458'
		when 'DOCOMO interTouch (Mariana), Inc.' then '5'
		when 'DOCOMO interTouch Company Limited' then '19'
		when 'Inter-Touch Hong Kong' then '26'
		when 'DOCOMO interTouch (India) Pvt. Ltd.' then '41'
		when 'Inter-Touch India' then '32'
		when 'Percipia India' then '119'
		when 'PT MagiNet Indonesia' then '40'
		when 'DOCOMO interTouch (Japan) K.K.' then '4'
		when 'Inter-Touch Japan' then '30'
		when 'DOCOMO interTouch (Jordan) LLC' then '1'
		when 'DOCOMO interTouch Limiteda . Sucursal de Macau' then '20'
		when 'E-Room Sdn. Bhd.' then '10'
		when 'inter-touch (Malaysia) Sdn. Bhd.' then '9'
		when 'DCMIT MEXICO S. DE R.L. DE C.V.' then '3451'
		when 'MagiNet Morocco' then '120'
		when 'DOCOMO interTouch (New Zealand) Ltd.' then '38'
		when 'DOCOMO interTouch Business Solutions, Inc.' then '3652'
		when 'DOCOMO interTouch Philippines Inc.' then '24'
		when 'DOCOMO interTouch Pte Ltd' then '134'
		when 'MagiNet Philippines Inc.' then '6'
		when 'DOCOMO interTouch Interactive Pte Ltd.' then '15'
		when 'DOCOMO interTouch Pte. Ltd.' then '21'
		when 'MagiNet South Africa Inc.' then '3'
		when 'DOCOMO interTouch Co., Ltd' then '3624'
		when 'DOCOMO interTouch Interactive Pte Ltd Korea Branch' then '3625'
		when 'DOCOMO interTouch (South Korea) Ltd' then '7'
		when 'Inter-Touch South Korea' then '29'
		when 'DOCOMO interTouch Lanka (Private) Limited' then '132'
		when 'DOCOMO interTouch Pte. Ltd. (Taiwan Branch)' then '35'
		when 'May Shyh Corporation' then '17'
		when 'DOCOMO interTouch (Thailand) Limited' then '33'
		when 'MagiNet Interactive (Thailand) Ltd.' then '8'
		when 'DOCOMO INTERTOUCH INTERAKTIF HIZMETLER TICARET ANONIM SIRKETI' then '11'
		when 'DOCOMO interTouch (ME&NA) FZ-LLC' then '2'
		when 'Inter-Touch (Middle East) FZ-LLC' then '28'
		when 'DOCOMO interTouch EMEA Ltd' then '27'
		when 'DOCOMO interTouch (USA) Inc.' then '23'
		when 'DOCOMO interTouch (USA) Inc. (ex-Percipia USA)' then '12'
		when 'Nomadix, Inc.' then '16'
		when 'DOCOMO interTouch (Vietnam) Company Limited' then '3462'
		when 'MagiNet Vietnam' then '18'
		when null then ' '
    end, 
	8044, 177, ' ', ' ', ' ', 
	case b.cost_center
		when 'Global Operations-Corporate' then '34'
		when 'Technical Support' then '5'
		when 'Legal - Contracts' then '9'
		when 'Centralised Account Managers' then '14'
		when 'Project Management' then '19'
		when 'Regional Helpdesk' then '23'
		when 'Major Account - Regional' then '24'
		when 'Unknown' then '27'
		when 'Corporate' then '1'
		when 'Finance-Corporate' then '2'
		when 'Operations-Regional' then '3'
		when 'Sales-Regional' then '4'
		when 'Marketing-Corporate' then '6'
		when 'Global Accounts-Corporate' then '7'
		when 'New Business-Corporate' then '8'
		when 'Network Operations-Corporate' then '11'
		when 'Legal-Corporate' then '13'
		when 'IS Operations-Corporate' then '15'
		when 'Account Management' then '16'
		when 'Commercial Operations' then '17'
		when 'Human Resources-Corporate' then '18'
		when 'Regional Management' then '20'
		when 'Product Management-Corporate' then '21'
		when 'Product Planning-Corporate' then '25'
		when 'Integration-Corporate' then '26'
		when 'Product Implementation-Corporate' then '28'
		when 'Procurement and Logistics-Global' then '29'
		when 'Procurement and Logistics-Regional' then '30'
		when 'Dedicated Engineers-Regional' then '31'
		when 'Content Management-Global' then '32'
		when 'Content Management-Regional' then '33'
		when 'Finance-Regional' then '35'
		when 'Network Operations-Regional' then '36'
		when 'Helpdesk-Regional' then '37'
		when 'IS Development-Corporate' then '22'
		when 'Human Resources-Regional' then '38'
		when 'Product Design and Development-Corporate' then '10'
		when 'Support Services Management' then '39'
		when 'Managed Services Management' then '40'
		when 'Nomadix R&D' then '42'
		when 'Quality Assurance' then '43'
		when 'Helpdesk Corporate (Internal)' then '12'
		when 'Helpdesk Corporate (External)' then '41'
		when null then ' '
	end,
	isnull((select x.cost_center_description from cost_center x where x.cost_center_code = b.cost_center),' '),
	0, a.usr_doc_contactid, b.usr_doc_shiftworker
FROM employee_biodata as a,
	employee_employment as b,
	company_profile as c,
	pay_activities_his as d
WHERE a.employee_id = b.employee_id AND b.company_code = c.company_code AND b.employee_status = 'A'
	AND b.employee_id = d.employee_id 
	AND b.employee_id NOT IN (SELECT x.employee_id FROM pay_activities_mth x)
	AND d.activity_date = (SELECT MAX(x.activity_date) FROM pay_activities_his x WHERE x.employee_id = d.employee_id)
UNION
SELECT dbo.fusr_getNamePart(a.employee_name, 'FN'), dbo.fusr_getNamePart(a.employee_name, 'LN'), a.employee_name,
	CONVERT(VARCHAR(10), a.birth_date, 110),
	case a.marital_status 
		when 'S' then '1'
		when 'M' then '2'
		when 'D' then '3'
		when 'E' then '5' 
		when null then ' '
	end, 
	(SELECT x.eds FROM user_qsieds_etstatus x WHERE  x.employee_id = a.employee_id),	(SELECT x.position_description FROM position x WHERE x.position_code = b.position_code), 
	(SELECT x.eds FROM user_qsieds_ettype x WHERE x.ori = 
		(SELECT y.service_code FROM employee_service y WHERE y.employee_id = a.employee_id AND y.service_date = 
			(SELECT MAX(y1.service_date) FROM employee_service y1 WHERE y1.employee_id = y.employee_id))),
	case b.grade_code
		when '1' then '2'
		when '2' then '3'
		when '3' then '4'
		when '4' then '5'
		when '5' then '6'
		when '6' then '7'
		when '7' then '8'
		when '8' then '9'
		when '9' then '10'
		when null then ' '
	end,
	CONVERT(VARCHAR(10),b.date_joined,110), CONVERT(VARCHAR(10),b.date_resigned,110), 
	' ', b.probation_period, 0, 0, 
	case c.company_name
		when 'Azure Wireless Pty.Ltd.' then '37'
		when 'DOCOMO interTouch Australia Pty. Ltd.' then '36'
		when 'Inter-Touch Pty. Ltd.' then '22'
		when 'DOCOMO interTouch (Bahrain) W.L.L.' then '2628'
		when 'DOCOMO interTouch (BRASIL) Servicos De Informatica Ltda.' then '121'
		when 'interTouch Information Technology (Shanghai) Co. Ltd.' then '3629'
		when 'Inter-Touch Software Information (Shanghai) Co., Ltd.' then '34'
		when 'MagiNet Shanghai Co., Ltd.' then '13'
		when 'Inter-Touch Egypt Limited' then '25'
		when 'MagiNet Interactive Egypt Ltd.' then '14'
		when 'DOCOMO interTouch Australia Pty. Ltd. - Fiji Branch' then '39'
		when 'DOCOMO interTouch (AP) Limited' then '3458'
		when 'DOCOMO interTouch (Mariana), Inc.' then '5'
		when 'DOCOMO interTouch Company Limited' then '19'
		when 'Inter-Touch Hong Kong' then '26'
		when 'DOCOMO interTouch (India) Pvt. Ltd.' then '41'
		when 'Inter-Touch India' then '32'
		when 'Percipia India' then '119'
		when 'PT MagiNet Indonesia' then '40'
		when 'DOCOMO interTouch (Japan) K.K.' then '4'
		when 'Inter-Touch Japan' then '30'
		when 'DOCOMO interTouch (Jordan) LLC' then '1'
		when 'DOCOMO interTouch Limiteda . Sucursal de Macau' then '20'
		when 'E-Room Sdn. Bhd.' then '10'
		when 'inter-touch (Malaysia) Sdn. Bhd.' then '9'
		when 'DCMIT MEXICO S. DE R.L. DE C.V.' then '3451'
		when 'MagiNet Morocco' then '120'
		when 'DOCOMO interTouch (New Zealand) Ltd.' then '38'
		when 'DOCOMO interTouch Business Solutions, Inc.' then '3652'
		when 'DOCOMO interTouch Philippines Inc.' then '24'
		when 'DOCOMO interTouch Pte Ltd' then '134'
		when 'MagiNet Philippines Inc.' then '6'
		when 'DOCOMO interTouch Interactive Pte Ltd.' then '15'
		when 'DOCOMO interTouch Pte. Ltd.' then '21'
		when 'MagiNet South Africa Inc.' then '3'
		when 'DOCOMO interTouch Co., Ltd' then '3624'
		when 'DOCOMO interTouch Interactive Pte Ltd Korea Branch' then '3625'
		when 'DOCOMO interTouch (South Korea) Ltd' then '7'
		when 'Inter-Touch South Korea' then '29'
		when 'DOCOMO interTouch Lanka (Private) Limited' then '132'
		when 'DOCOMO interTouch Pte. Ltd. (Taiwan Branch)' then '35'
		when 'May Shyh Corporation' then '17'
		when 'DOCOMO interTouch (Thailand) Limited' then '33'
		when 'MagiNet Interactive (Thailand) Ltd.' then '8'
		when 'DOCOMO INTERTOUCH INTERAKTIF HIZMETLER TICARET ANONIM SIRKETI' then '11'
		when 'DOCOMO interTouch (ME&NA) FZ-LLC' then '2'
		when 'Inter-Touch (Middle East) FZ-LLC' then '28'
		when 'DOCOMO interTouch EMEA Ltd' then '27'
		when 'DOCOMO interTouch (USA) Inc.' then '23'
		when 'DOCOMO interTouch (USA) Inc. (ex-Percipia USA)' then '12'
		when 'Nomadix, Inc.' then '16'
		when 'DOCOMO interTouch (Vietnam) Company Limited' then '3462'
		when 'MagiNet Vietnam' then '18'
		when null then ' '
    end, 
	8044, 177, ' ', ' ', ' ', 
	case b.cost_center
		when 'Global Operations-Corporate' then '34'
		when 'Technical Support' then '5'
		when 'Legal - Contracts' then '9'
		when 'Centralised Account Managers' then '14'
		when 'Project Management' then '19'
		when 'Regional Helpdesk' then '23'
		when 'Major Account - Regional' then '24'
		when 'Unknown' then '27'
		when 'Corporate' then '1'
		when 'Finance-Corporate' then '2'
		when 'Operations-Regional' then '3'
		when 'Sales-Regional' then '4'
		when 'Marketing-Corporate' then '6'
		when 'Global Accounts-Corporate' then '7'
		when 'New Business-Corporate' then '8'
		when 'Network Operations-Corporate' then '11'
		when 'Legal-Corporate' then '13'
		when 'IS Operations-Corporate' then '15'
		when 'Account Management' then '16'
		when 'Commercial Operations' then '17'
		when 'Human Resources-Corporate' then '18'
		when 'Regional Management' then '20'
		when 'Product Management-Corporate' then '21'
		when 'Product Planning-Corporate' then '25'
		when 'Integration-Corporate' then '26'
		when 'Product Implementation-Corporate' then '28'
		when 'Procurement and Logistics-Global' then '29'
		when 'Procurement and Logistics-Regional' then '30'
		when 'Dedicated Engineers-Regional' then '31'
		when 'Content Management-Global' then '32'
		when 'Content Management-Regional' then '33'
		when 'Finance-Regional' then '35'
		when 'Network Operations-Regional' then '36'
		when 'Helpdesk-Regional' then '37'
		when 'IS Development-Corporate' then '22'
		when 'Human Resources-Regional' then '38'
		when 'Product Design and Development-Corporate' then '10'
		when 'Support Services Management' then '39'
		when 'Managed Services Management' then '40'
		when 'Nomadix R&D' then '42'
		when 'Quality Assurance' then '43'
		when 'Helpdesk Corporate (Internal)' then '12'
		when 'Helpdesk Corporate (External)' then '41'
		when null then ' '
	end,
	isnull((select x.cost_center_description from cost_center x where x.cost_center_code = b.cost_center),' '),
	0, a.usr_doc_contactid, b.usr_doc_shiftworker
FROM employee_biodata as a,
	employee_employment as b,
	company_profile as c
WHERE a.employee_id = b.employee_id AND b.company_code = c.company_code AND b.employee_status = 'A'
	AND (b.employee_id NOT IN (SELECT x.employee_id FROM pay_activities_mth x) 
		AND b.employee_id NOT IN (SELECT x.employee_id FROM pay_activities_his x))

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE VIEW [dbo].[vusr_doc_oilavail]
(id, employee_id, request_date, oil_date, reason_code, no_of_hrs, status, created_by, 
	created_date, modified_by, modified_date, remarks)
AS
SELECT 1000000000, '0000000000', getdate(), getdate(), '0000000000', 0, 'P', '0000000000', getdate(),
	'0000000000', getdate(), '0000000000'
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE VIEW dbo.vusr_docomo_cpl
AS
SELECT     COUNT(a.RELATION_CODE) AS child_count
FROM         dbo.EMPLOYEE_RELATION AS a INNER JOIN
                      dbo.EMPLOYEE_BIODATA AS b ON a.EMPLOYEE_ID = b.EMPLOYEE_ID
WHERE     (b.SEX = 'M') AND (b.MARITAL_STATUS = 'M')
GROUP BY a.EMPLOYEE_ID

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON




cREATE VIEW [dbo].[vusr_docomo_form_coe] 
    (employee_title, employee_name, company_name, position_description, department_name, employee_surname, date_joined,
gross_income, 
prepared_date, recipient_code, recipient_desc, remarks, description, modified_by, modified_date, created_by, created_date)
AS
SELECT a.employee_title, 
dbo.fusr_getNamePart(a.EMPLOYEE_NAME, 'FN') + ' ' + dbo.fusr_getNamePart(a.EMPLOYEE_NAME, 'LN') AS employee_name, 
e.company_name, 
d.position_description, 
h.department_name,
dbo.fusr_getNamePart(a.EMPLOYEE_NAME, 'LN') AS employee_surname, 
DATENAME(month, b.DATE_JOINED) + ' ' + DATENAME(day, b.DATE_JOINED) + ', ' + DATENAME(year,b.DATE_JOINED) AS date_joined, 
convert(CHAR(17), cast((b.BASIC_SALARY +  c.AMOUNT) * 13 as money), 1) AS gross_income, 
DATENAME(month, GETDATE()) + ' ' + DATENAME(day, GETDATE()) + ', ' + DATENAME(year, GETDATE()) AS prepared_date,
   g.recipient_code,
   g.recipient_desc,
   g.remarks,  
   f.description,       
   b.modified_by, 
   b.modified_date,
   b.created_by, 
   b.created_date
FROM         dbo.EMPLOYEE_BIODATA AS a INNER JOIN
                      dbo.EMPLOYEE_EMPLOYMENT AS b ON a.EMPLOYEE_ID = b.EMPLOYEE_ID INNER JOIN
                      dbo.POSITION AS d ON b.POSITION_CODE = d.POSITION_CODE INNER JOIN
                      dbo.V_LOCATION_LOOKUP AS h ON b.LOCATION_ID = h.id INNER JOIN
                      dbo.COMPANY_PROFILE AS e ON b.COMPANY_CODE = e.COMPANY_CODE INNER JOIN
                      dbo.EMP_MTH_FIX_TRANSACTION AS c ON b.EMPLOYEE_ID = c.EMPLOYEE_ID INNER JOIN
                      dbo.USER_DOCOMO_COEFORM AS g ON b.EMPLOYEE_ID = g.EMPLOYEE_ID INNER JOIN
                      dbo.USER_QSIEDS_ETSTATUS AS f ON b.EMPLOYEE_ID = f.EMPLOYEE_ID
                      
WHERE     (b.EMPLOYEE_STATUS = 'A') and (c.TRX_CODE = 'NTAX')










SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON





CREATE VIEW [dbo].[vusr_docomo_form_coe_sepa] 
    (employee_title, employee_name, company_name, position_description, department_name, employee_pronoun,employee_surname, date_joined,
     prepared_date, date_resigned,description)
AS
SELECT a.employee_title, 
dbo.fusr_getNamePart(a.EMPLOYEE_NAME, 'FN') + ' ' + dbo.fusr_getNamePart(a.EMPLOYEE_NAME, 'LN') AS employee_name, 
e.company_name, 
d.position_description, 
h.department_name,(CASE a.sex WHEN 'F' THEN 'her' ELSE 'him' END) AS employee_pronoun,
dbo.fusr_getNamePart(a.EMPLOYEE_NAME, 'LN') AS employee_surname, 
DATENAME(month, b.DATE_JOINED) + ' ' + DATENAME(day, b.DATE_JOINED) + ', ' + DATENAME(year,b.DATE_JOINED) AS date_joined, 
DATENAME(month, GETDATE()) + ' ' + DATENAME(day, GETDATE()) + ', ' + DATENAME(year, GETDATE()) AS prepared_date,
DATENAME(month, b.DATE_RESIGNED) + ' ' + DATENAME(day, b.DATE_RESIGNED) + ', ' + DATENAME(year,b.DATE_RESIGNED)AS date_resigned,
			g.description
			
			
FROM         dbo.EMPLOYEE_BIODATA AS a INNER JOIN
                      dbo.EMPLOYEE_EMPLOYMENT AS b ON a.EMPLOYEE_ID = b.EMPLOYEE_ID INNER JOIN
                      dbo.POSITION AS d ON b.POSITION_CODE = d.POSITION_CODE INNER JOIN
                      dbo.V_LOCATION_LOOKUP AS h ON b.LOCATION_ID = h.id INNER JOIN
                      dbo.COMPANY_PROFILE AS e ON b.COMPANY_CODE = e.COMPANY_CODE INNER JOIN
                      dbo.USER_QSIEDS_ETSTATUS AS g ON b.EMPLOYEE_ID = g.EMPLOYEE_ID
              
                   
WHERE     b.EMPLOYEE_STATUS = 'X'







SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE VIEW [dbo].[vusr_docomo_form_coe_sepa1]
AS
SELECT     dbo.fusr_getNamePart(a.EMPLOYEE_NAME, 'FN') + ' ' + dbo.fusr_getNamePart(a.EMPLOYEE_NAME, 'LN') AS employee_name, e.COMPANY_NAME, 
                      d.POSITION_DESCRIPTION, h.department_name, dbo.fusr_getNamePart(a.EMPLOYEE_NAME, 'LN') AS employee_surname, DATENAME(month, b.DATE_JOINED) 
                      + ' ' + DATENAME(day, b.DATE_JOINED) + ', ' + DATENAME(year, b.DATE_JOINED) AS date_joined, DATENAME(month, GETDATE()) + ' ' + DATENAME(day, GETDATE()) 
                      + ', ' + DATENAME(year, GETDATE()) AS prepared_date, g.DESCRIPTION, a.employee_title, b.DATE_RESIGNED
FROM         dbo.EMPLOYEE_BIODATA AS a INNER JOIN
                      dbo.EMPLOYEE_EMPLOYMENT AS b ON a.EMPLOYEE_ID = b.EMPLOYEE_ID INNER JOIN
                      dbo.POSITION AS d ON b.POSITION_CODE = d.POSITION_CODE INNER JOIN
                      dbo.V_LOCATION_LOOKUP AS h ON b.LOCATION_ID = h.id INNER JOIN
                      dbo.COMPANY_PROFILE AS e ON b.COMPANY_CODE = e.COMPANY_CODE INNER JOIN
                      dbo.USER_QSIEDS_ETSTATUS AS g ON b.EMPLOYEE_ID = g.EMPLOYEE_ID
WHERE     (b.EMPLOYEE_STATUS = 'X')

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON




CREATE VIEW [dbo].[vusr_docomo_form_coe_sepa2] 
    (employee_title, employee_name, company_name, position_description, department_name, employee_pronoun,employee_surname, date_joined,
     prepared_date, date_resigned,description)
AS
SELECT a.employee_title, 
dbo.fusr_getNamePart(a.EMPLOYEE_NAME, 'FN') + ' ' + dbo.fusr_getNamePart(a.EMPLOYEE_NAME, 'LN') AS employee_name, 
e.company_name, 
d.position_description, 
h.department_name,(CASE a.sex WHEN 'F' THEN 'her' ELSE 'him' END) AS employee_pronoun,
dbo.fusr_getNamePart(a.EMPLOYEE_NAME, 'LN') AS employee_surname, 
DATENAME(month, b.DATE_JOINED) + ' ' + DATENAME(day, b.DATE_JOINED) + ', ' + DATENAME(year,b.DATE_JOINED) AS date_joined, 
DATENAME(month, GETDATE()) + ' ' + DATENAME(day, GETDATE()) + ', ' + DATENAME(year, GETDATE()) AS prepared_date,
			b.date_resigned,
			g.description
			
			
FROM         dbo.EMPLOYEE_BIODATA AS a INNER JOIN
                      dbo.EMPLOYEE_EMPLOYMENT AS b ON a.EMPLOYEE_ID = b.EMPLOYEE_ID INNER JOIN
                      dbo.POSITION AS d ON b.POSITION_CODE = d.POSITION_CODE INNER JOIN
                      dbo.V_LOCATION_LOOKUP AS h ON b.LOCATION_ID = h.id INNER JOIN
                      dbo.COMPANY_PROFILE AS e ON b.COMPANY_CODE = e.COMPANY_CODE INNER JOIN
                      dbo.USER_QSIEDS_ETSTATUS AS g ON b.EMPLOYEE_ID = g.EMPLOYEE_ID
              
                   
WHERE     b.EMPLOYEE_STATUS = 'X'






SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON



cREATE VIEW [dbo].[vusr_docomo_form_coe1] 
    (employee_title, employee_name, company_name, position_description, department_name, employee_surname, date_joined,
gross_income, 
prepared_date, modified_by, modified_date, created_by, created_date)
AS
SELECT a.employee_title, 
dbo.fusr_getNamePart(a.EMPLOYEE_NAME, 'FN') + '. ' + dbo.fusr_getNamePart(a.EMPLOYEE_NAME, 'LN') AS employee_name, 
e.company_name, 
d.position_description, 
h.department_name,
dbo.fusr_getNamePart(a.EMPLOYEE_NAME, 'LN') AS employee_surname, 
DATENAME(month, b.DATE_JOINED) + ' ' + DATENAME(day, b.DATE_JOINED) + ', ' + DATENAME(year,b.DATE_JOINED) AS date_joined, 
(b.BASIC_SALARY +  c.AMOUNT) * 13 AS gross_income, 
DATENAME(month, GETDATE()) + ' ' + DATENAME(day, GETDATE()) + ', ' + DATENAME(year, GETDATE()) AS prepared_date,
			b.created_date, 
			b.created_by, 
			b.modified_date, 
			b.modified_by 
FROM         dbo.EMPLOYEE_BIODATA AS a INNER JOIN
                      dbo.EMPLOYEE_EMPLOYMENT AS b ON a.EMPLOYEE_ID = b.EMPLOYEE_ID INNER JOIN
                      dbo.POSITION AS d ON b.POSITION_CODE = d.POSITION_CODE INNER JOIN
                      dbo.V_LOCATION_LOOKUP AS h ON b.LOCATION_ID = h.id INNER JOIN
                      dbo.COMPANY_PROFILE AS e ON b.COMPANY_CODE = e.COMPANY_CODE INNER JOIN
                      dbo.EMP_MTH_FIX_TRANSACTION AS c ON b.EMPLOYEE_ID = c.EMPLOYEE_ID
WHERE     (b.EMPLOYEE_STATUS = 'A') and (c.TRX_CODE = 'NTAX')






SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON


CREATE VIEW [dbo].[vusr_docomo_form_coe2] 
    (employee_title, employee_name, position_description, company_name, date_joined, 
employee_pronoun, employee_surname, division_name, department_name,gross_income, 
created_date, created_by, modified_date, modified_by)
    AS

SELECT     a.employee_title, dbo.fusr_getNamePart(a.EMPLOYEE_NAME, 'FN') + '. ' + dbo.fusr_getNamePart(a.EMPLOYEE_NAME, 'LN') AS employee_name, 
                      d.POSITION_DESCRIPTION, e.COMPANY_NAME, DATENAME(month, b.DATE_JOINED) + ' ' + DATENAME(day, b.DATE_JOINED) + ', ' + DATENAME(year, 
                      b.DATE_JOINED) AS date_joined, (CASE a.sex WHEN 'F' THEN 'She' ELSE 'He' END) AS employee_pronoun, dbo.fusr_getNamePart(a.EMPLOYEE_NAME, 'LN') 
                      AS employee_surname, h.division_name, h.department_name, (b.BASIC_SALARY +  c.AMOUNT) * 13 AS gross_income, b.CREATED_DATE, b.CREATED_BY, b.MODIFIED_DATE, b.MODIFIED_BY
FROM         dbo.EMPLOYEE_BIODATA AS a INNER JOIN
                      dbo.EMPLOYEE_EMPLOYMENT AS b ON a.EMPLOYEE_ID = b.EMPLOYEE_ID INNER JOIN
                      dbo.POSITION AS d ON b.POSITION_CODE = d.POSITION_CODE INNER JOIN
                      dbo.V_LOCATION_LOOKUP AS h ON b.LOCATION_ID = h.id INNER JOIN
                      dbo.COMPANY_PROFILE AS e ON b.COMPANY_CODE = e.COMPANY_CODE INNER JOIN
                      dbo.EMP_MTH_FIX_TRANSACTION AS c ON b.EMPLOYEE_ID = c.EMPLOYEE_ID
WHERE     (b.EMPLOYEE_STATUS = 'A') and (c.TRX_CODE = 'NTXA')




SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON

cREATE VIEW [dbo].[vusr_docomo_form_coe3] 
    (employee_title, employee_name, company_name, position_description, department_name, employee_surname, date_joined,
--gross_income, 
prepared_date, modified_by, modified_date, created_by, created_date)
AS
SELECT a.employee_title, 
dbo.fusr_getNamePart(a.EMPLOYEE_NAME, 'FN') + '. ' + dbo.fusr_getNamePart(a.EMPLOYEE_NAME, 'LN') AS employee_name, 
e.company_name, 
d.position_description, 
h.department_name,
dbo.fusr_getNamePart(a.EMPLOYEE_NAME, 'LN') AS employee_surname, 
DATENAME(month, b.DATE_JOINED) + ' ' + DATENAME(day, b.DATE_JOINED) + ', ' + DATENAME(year,b.DATE_JOINED) AS date_joined, 
--(b.BASIC_SALARY +  c.AMOUNT) * 13 AS gross_income, 
DATENAME(month, GETDATE()) + ' ' + DATENAME(day, GETDATE()) + ', ' + DATENAME(year, GETDATE()) AS prepared_date,
			b.created_date, 
			b.created_by, 
			b.modified_date, 
			b.modified_by 
FROM         dbo.EMPLOYEE_BIODATA AS a INNER JOIN
                      dbo.EMPLOYEE_EMPLOYMENT AS b ON a.EMPLOYEE_ID = b.EMPLOYEE_ID INNER JOIN
                      dbo.POSITION AS d ON b.POSITION_CODE = d.POSITION_CODE INNER JOIN
                      dbo.V_LOCATION_LOOKUP AS h ON b.LOCATION_ID = h.id INNER JOIN
                      dbo.COMPANY_PROFILE AS e ON b.COMPANY_CODE = e.COMPANY_CODE --INNER JOIN
                      --dbo.EMP_MTH_FIX_TRANSACTION AS c ON b.EMPLOYEE_ID = c.EMPLOYEE_ID
WHERE     (b.EMPLOYEE_STATUS = 'A') --and (c.TRX_CODE = 'NTXA')




SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON




cREATE VIEW [dbo].[vusr_docomo_form_coe4] 
    (employee_title, employee_name, company_name, position_description, department_name, employee_surname, date_joined,
gross_income, 
prepared_date, recipient_code, recipient_desc, remarks, modified_by, modified_date, created_by, created_date)
AS
SELECT a.employee_title, 
dbo.fusr_getNamePart(a.EMPLOYEE_NAME, 'FN') + '. ' + dbo.fusr_getNamePart(a.EMPLOYEE_NAME, 'LN') AS employee_name, 
e.company_name, 
d.position_description, 
h.department_name,
dbo.fusr_getNamePart(a.EMPLOYEE_NAME, 'LN') AS employee_surname, 
DATENAME(month, b.DATE_JOINED) + ' ' + DATENAME(day, b.DATE_JOINED) + ', ' + DATENAME(year,b.DATE_JOINED) AS date_joined, 
(b.BASIC_SALARY +  c.AMOUNT) * 13 AS gross_income, 
DATENAME(month, GETDATE()) + ' ' + DATENAME(day, GETDATE()) + ', ' + DATENAME(year, GETDATE()) AS prepared_date,
			g.recipient_code,
			g.recipient_desc,
			g.remarks,           
			b.modified_by, 
			b.modified_date,
			b.created_by, 
			b.created_date
FROM         dbo.EMPLOYEE_BIODATA AS a INNER JOIN
                      dbo.EMPLOYEE_EMPLOYMENT AS b ON a.EMPLOYEE_ID = b.EMPLOYEE_ID INNER JOIN
                      dbo.POSITION AS d ON b.POSITION_CODE = d.POSITION_CODE INNER JOIN
                      dbo.V_LOCATION_LOOKUP AS h ON b.LOCATION_ID = h.id INNER JOIN
                      dbo.COMPANY_PROFILE AS e ON b.COMPANY_CODE = e.COMPANY_CODE INNER JOIN
                      dbo.EMP_MTH_FIX_TRANSACTION AS c ON b.EMPLOYEE_ID = c.EMPLOYEE_ID INNER JOIN
                      dbo.USER_DOCOMO_COEFORM AS g ON b.EMPLOYEE_ID = g.EMPLOYEE_ID
                      
WHERE     (b.EMPLOYEE_STATUS = 'A') and (c.TRX_CODE = 'NTAX')







SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON






cREATE VIEW [dbo].[vusr_docomo_form_coe5] 
    (employee_title, employee_name, company_name, position_description, department_name, employee_surname, date_joined,
gross_income, 
prepared_date, recipient_code, recipient_desc, remarks, modified_by, modified_date, created_by, created_date)
AS
SELECT a.employee_title, 
dbo.fusr_getNamePart(a.EMPLOYEE_NAME, 'FN') + ' ' + dbo.fusr_getNamePart(a.EMPLOYEE_NAME, 'LN') AS employee_name, 
e.company_name, 
d.position_description, 
h.department_name,
dbo.fusr_getNamePart(a.EMPLOYEE_NAME, 'LN') AS employee_surname, 
DATENAME(month, b.DATE_JOINED) + ' ' + DATENAME(day, b.DATE_JOINED) + ', ' + DATENAME(year,b.DATE_JOINED) AS date_joined, 
convert(CHAR(17), cast((b.BASIC_SALARY +  c.AMOUNT) * 13 as money), 1) AS gross_income, 
DATENAME(month, GETDATE()) + ' ' + DATENAME(day, GETDATE()) + ', ' + DATENAME(year, GETDATE()) AS prepared_date,
   g.recipient_code,
   g.recipient_desc,
   g.remarks,           
   b.modified_by, 
   b.modified_date,
   b.created_by, 
   b.created_date
FROM         dbo.EMPLOYEE_BIODATA AS a INNER JOIN
                      dbo.EMPLOYEE_EMPLOYMENT AS b ON a.EMPLOYEE_ID = b.EMPLOYEE_ID INNER JOIN
                      dbo.POSITION AS d ON b.POSITION_CODE = d.POSITION_CODE INNER JOIN
                      dbo.V_LOCATION_LOOKUP AS h ON b.LOCATION_ID = h.id INNER JOIN
                      dbo.COMPANY_PROFILE AS e ON b.COMPANY_CODE = e.COMPANY_CODE INNER JOIN
                      dbo.EMP_MTH_FIX_TRANSACTION AS c ON b.EMPLOYEE_ID = c.EMPLOYEE_ID INNER JOIN
                      dbo.USER_DOCOMO_COEFORM AS g ON b.EMPLOYEE_ID = g.EMPLOYEE_ID
                      
WHERE     (b.EMPLOYEE_STATUS = 'A') and (c.TRX_CODE = 'NTAX')









SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON





cREATE VIEW [dbo].[vusr_docomo_form_coe6] 
    (employee_title, employee_name, company_name, position_description, department_name, employee_surname, date_joined,
gross_income, 
prepared_date, recipient_code, recipient_desc, remarks, modified_by, modified_date, created_by, created_date)
AS
SELECT a.employee_title, 
dbo.fusr_getNamePart(a.EMPLOYEE_NAME, 'FN') + ' ' + dbo.fusr_getNamePart(a.EMPLOYEE_NAME, 'LN') AS employee_name, 
e.company_name, 
d.position_description, 
h.department_name,
dbo.fusr_getNamePart(a.EMPLOYEE_NAME, 'LN') AS employee_surname, 
DATENAME(month, b.DATE_JOINED) + ' ' + DATENAME(day, b.DATE_JOINED) + ', ' + DATENAME(year,b.DATE_JOINED) AS date_joined, 
(b.BASIC_SALARY +  c.AMOUNT) * 13 AS gross_income, 
DATENAME(month, GETDATE()) + ' ' + DATENAME(day, GETDATE()) + ', ' + DATENAME(year, GETDATE()) AS prepared_date,
			g.recipient_code,
			g.recipient_desc,
			g.remarks,           
			b.modified_by, 
			b.modified_date,
			b.created_by, 
			b.created_date
FROM         dbo.EMPLOYEE_BIODATA AS a INNER JOIN
                      dbo.EMPLOYEE_EMPLOYMENT AS b ON a.EMPLOYEE_ID = b.EMPLOYEE_ID INNER JOIN
                      dbo.POSITION AS d ON b.POSITION_CODE = d.POSITION_CODE INNER JOIN
                      dbo.V_LOCATION_LOOKUP AS h ON b.LOCATION_ID = h.id INNER JOIN
                      dbo.COMPANY_PROFILE AS e ON b.COMPANY_CODE = e.COMPANY_CODE INNER JOIN
                      dbo.EMP_MTH_FIX_TRANSACTION AS c ON b.EMPLOYEE_ID = c.EMPLOYEE_ID INNER JOIN
                      dbo.USER_DOCOMO_COEFORM AS g ON b.EMPLOYEE_ID = g.EMPLOYEE_ID
                      
WHERE     (b.EMPLOYEE_STATUS = 'A') and (c.TRX_CODE = 'NTAX')








SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
create view vw_trxldg1
as 
(select 
 coalesce(ldg.employee_no, lv.employee_no) empno, coalesce(Surname1, Surname2) Surname, coalesce(FirstName1, FirstName2) FirstName,
 SL, VL, BL, ML, CL, PL, LWOP, SUSP,CML, CMPL, CPL, EXL, MLND, OIL, SLOP, SPAL, VLOP,
 AWOL, AWOL_amt, LATE, LATE_amt, NDWS, NDWS_amt, RDOT, RDOT_amt, LHRO, LHRO_amt, RDND, RDND_amt, RGOT, RGOT_amt, 
 EOUT, EOUT_amt, OVBR, OVBR_amt, LHN8, LHN8_amt, LHND, LHND_amt, LPAT, LPAT_amt, LRN8, LRN8_amt, LRND, LRND_amt,
 NDDS, NDDS_amt, NDOT, NDOT_amt, NTAX, NTAX_amt, RDN8, RDN8_amt, SHN8, SHN8_amt, SHND, SHND_amt, SRDN, SRDN_amt,
 SRN8, SRN8_amt, TAX,  TAX_amt,  TRNS, TRNS_amt, LHD8, LHD8_amt, LHDO, LHDO_amt, LHR8, LHR8_amt,
 RDO8, RDO8_amt, RGO8, RGO8_amt, SHD8, SHD8_amt, SHDO, SHDO_amt, SHR8, SHR8_amt, SHRO, SHRO_amt, getdate() ServerDate from
(select eb.employee_no, 
 dbo.fusr_getNamePart(eb.employee_name,'LN') as Surname1, dbo.fusr_getNamePart(eb.employee_name,'FN') as FirstName1,
 sum(case when trx_code = 'AWOL' then QTY else 0 end) as AWOL,
  sum(case when trx_code = 'AWOL' then AMOUNT else 0 end) as AWOL_amt,
 sum(case when trx_code = 'LATE' then QTY else 0 end) as LATE,
  sum(case when trx_code = 'LATE' then AMOUNT else 0 end) as LATE_amt,
 sum(case when trx_code = 'NDWS' then QTY else 0 end) as NDWS,
   sum(case when trx_code = 'NDWS' then AMOUNT else 0 end) as NDWS_amt,
 sum(case when trx_code = 'RDOT' then QTY else 0 end) as RDOT,
   sum(case when trx_code = 'RDOT' then AMOUNT else 0 end) as RDOT_amt,
 sum(case when trx_code = 'LHRO' then QTY else 0 end) as LHRO,
   sum(case when trx_code = 'LHRO' then AMOUNT else 0 end) as LHRO_amt,
 sum(case when trx_code = 'RDND' then QTY else 0 end) as RDND,
   sum(case when trx_code = 'RDND' then AMOUNT else 0 end) as RDND_amt,
 sum(case when trx_code = 'RGOT' then QTY else 0 end) as RGOT,
   sum(case when trx_code = 'RGOT' then AMOUNT else 0 end) as RGOT_amt,
 sum(case when trx_code = 'EOUT' then QTY else 0 end) as EOUT,
   sum(case when trx_code = 'EOUT' then AMOUNT else 0 end) as EOUT_amt,
 sum(case when trx_code = 'OVBR' then QTY else 0 end) as OVBR,
   sum(case when trx_code = 'OVBR' then AMOUNT else 0 end) as OVBR_amt,
--additional allowance code added: 09/04/2012--
 sum(case when trx_code = 'LHN8' then QTY else 0 end) as LHN8,
   sum(case when trx_code = 'LHN8' then AMOUNT else 0 end) as LHN8_amt,
 sum(case when trx_code = 'LHND' then QTY else 0 end) as LHND,
   sum(case when trx_code = 'LHND' then AMOUNT else 0 end) as LHND_amt,
 sum(case when trx_code = 'LPAT' then QTY else 0 end) as LPAT,
   sum(case when trx_code = 'LPAT' then AMOUNT else 0 end) as LPAT_amt,
 sum(case when trx_code = 'LRN8' then QTY else 0 end) as LRN8,
   sum(case when trx_code = 'LRN8' then AMOUNT else 0 end) as LRN8_amt,
 sum(case when trx_code = 'LRND' then QTY else 0 end) as LRND,
   sum(case when trx_code = 'LRND' then AMOUNT else 0 end) as LRND_amt,
 sum(case when trx_code = 'NDDS' then QTY else 0 end) as NDDS,
   sum(case when trx_code = 'NDDS' then AMOUNT else 0 end) as NDDS_amt,
 sum(case when trx_code = 'NDOT' then QTY else 0 end) as NDOT,
   sum(case when trx_code = 'NDOT' then AMOUNT else 0 end) as NDOT_amt,
 sum(case when trx_code = 'NTAX' then QTY else 0 end) as NTAX,
   sum(case when trx_code = 'NTAX' then AMOUNT else 0 end) as NTAX_amt,
 sum(case when trx_code = 'RDN8' then QTY else 0 end) as RDN8,
   sum(case when trx_code = 'RDN8' then AMOUNT else 0 end) as RDN8_amt,
sum(case when trx_code = 'SHN8' then QTY else 0 end) as SHN8,
   sum(case when trx_code = 'SHN8' then AMOUNT else 0 end) as SHN8_amt,
sum(case when trx_code = 'SHND' then QTY else 0 end) as SHND,
   sum(case when trx_code = 'SHND' then AMOUNT else 0 end) as SHND_amt,
sum(case when trx_code = 'SRDN' then QTY else 0 end) as SRDN,
   sum(case when trx_code = 'SRDN' then AMOUNT else 0 end) as SRDN_amt,
sum(case when trx_code = 'SRN8' then QTY else 0 end) as SRN8,
   sum(case when trx_code = 'SRN8' then AMOUNT else 0 end) as SRN8_amt,
sum(case when trx_code = 'TAX' then QTY else 0 end) as TAX,
   sum(case when trx_code = 'TAX' then AMOUNT else 0 end) as TAX_amt,
sum(case when trx_code = 'TRNS' then QTY else 0 end) as TRNS,
   sum(case when trx_code = 'TRNS' then AMOUNT else 0 end) as TRNS_amt,
--additional deduction code added: 09/04/2012--
--sum(case when trx_code = 'LWOP' then QTY else 0 end) as LWOP,
   --sum(case when trx_code = 'LWOP' then AMOUNT else 0 end) as LWOP_amt,
--additional overtime code added: 09/04/2012--
sum(case when trx_code = 'LHD8' then QTY else 0 end) as LHD8,
   sum(case when trx_code = 'LHD8' then AMOUNT else 0 end) as LHD8_amt,
sum(case when trx_code = 'LHDO' then QTY else 0 end) as LHDO,
   sum(case when trx_code = 'LHDO' then AMOUNT else 0 end) as LHDO_amt,
sum(case when trx_code = 'LHR8' then QTY else 0 end) as LHR8,
   sum(case when trx_code = 'LHR8' then AMOUNT else 0 end) as LHR8_amt,
sum(case when trx_code = 'RDO8' then QTY else 0 end) as RDO8,
   sum(case when trx_code = 'RDO8' then AMOUNT else 0 end) as RDO8_amt,
sum(case when trx_code = 'RGO8' then QTY else 0 end) as RGO8,
   sum(case when trx_code = 'RGO8' then AMOUNT else 0 end) as RGO8_amt,
sum(case when trx_code = 'SHD8' then QTY else 0 end) as SHD8,
   sum(case when trx_code = 'SHD8' then AMOUNT else 0 end) as SHD8_amt,
sum(case when trx_code = 'SHDO' then QTY else 0 end) as SHDO,
   sum(case when trx_code = 'SHDO' then AMOUNT else 0 end) as SHDO_amt,
sum(case when trx_code = 'SHR8' then QTY else 0 end) as SHR8,
   sum(case when trx_code = 'SHR8' then AMOUNT else 0 end) as SHR8_amt,
sum(case when trx_code = 'SHRO' then QTY else 0 end) as SHRO,
   sum(case when trx_code = 'SHRO' then AMOUNT else 0 end) as SHRO_amt
from employee_trxldg tl inner join employee_biodata eb on tl.employee_no = eb.employee_no 
where day(trx_date) >= 20 or day(trx_date) <= 4
group by eb.employee_no, dbo.fusr_getNamePart(eb.employee_name,'LN'), dbo.fusr_getNamePart(eb.employee_name,'FN')) ldg
full outer join 
(select li.employee_no, dbo.fusr_getNamePart(eb.employee_name,'LN') as Surname2, dbo.fusr_getNamePart(eb.employee_name,'FN') as FirstName2, 
 sum(case when leave_code = 'SL' then 1 else 0 end) as SL,
 sum(case when leave_code = 'VL' then 1 else 0 end) as VL,
 sum(case when leave_code = 'BL' then 1 else 0 end) as BL,
 sum(case when leave_code = 'ML' then 1 else 0 end) as ML,
 sum(case when leave_code = 'CL' then 1 else 0 end) as CL,
 sum(case when leave_code = 'PL' then 1 else 0 end) as PL,
 sum(case when leave_code = 'LWOP' then 1 else 0 end) as LWOP,
 sum(case when leave_code = 'SUSP' then 1 else 0 end) as SUSP,
--additional leave code added: 09/04/2012--
 sum(case when leave_code = 'CML' then 1 else 0 end) as CML,
 sum(case when leave_code = 'CMPL' then 1 else 0 end) as CMPL,
 sum(case when leave_code = 'CPL' then 1 else 0 end) as CPL,
 sum(case when leave_code = 'EXL' then 1 else 0 end) as EXL,
 sum(case when leave_code = 'MLND' then 1 else 0 end) as MLND,
 sum(case when leave_code = 'OIL' then 1 else 0 end) as OIL,
 sum(case when leave_code = 'SLOP' then 1 else 0 end) as SLOP,
 sum(case when leave_code = 'SPAL' then 1 else 0 end) as SPAL,
 sum(case when leave_code = 'VLOP' then 1 else 0 end) as VLOP
from employee_leave_day ld, employee_leave_info li, employee_biodata eb
where ld.employee_id = li.employee_id and ld.reference_id = li.reference_no and ld.employee_id = eb.employee_id and
 year(approve_date) = year(getdate()) and ((month(approve_date) = month(getdate()) and day(approve_date) <= 4)
  or (month(approve_date)+1 =  month(getdate()) and day(approve_date) >= 20)) 
group by li.employee_no, dbo.fusr_getNamePart(eb.employee_name,'LN'), dbo.fusr_getNamePart(eb.employee_name,'FN')) lv 
on ldg.employee_no = lv.employee_no)



SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
create view vw_trxldg2
as 
select 
 coalesce(ldg.employee_no, lv.employee_no) empno, coalesce(Surname1, Surname2) Surname, coalesce(FirstName1, FirstName2) FirstName,
 SL, VL, BL, ML, CL, PL, LWOP, SUSP,CML, CMPL, CPL, EXL, MLND, OIL, SLOP, SPAL, VLOP,
 AWOL, AWOL_amt, LATE, LATE_amt, NDWS, NDWS_amt, RDOT, RDOT_amt, LHRO, LHRO_amt, RDND, RDND_amt, RGOT, RGOT_amt, 
 EOUT, EOUT_amt, OVBR, OVBR_amt, LHN8, LHN8_amt, LHND, LHND_amt, LPAT, LPAT_amt, LRN8, LRN8_amt, LRND, LRND_amt,
 NDDS, NDDS_amt, NDOT, NDOT_amt, NTAX, NTAX_amt, RDN8, RDN8_amt, SHN8, SHN8_amt, SHND, SHND_amt, SRDN, SRDN_amt,
 SRN8, SRN8_amt, TAX,  TAX_amt,  TRNS, TRNS_amt, LHD8, LHD8_amt, LHDO, LHDO_amt, LHR8, LHR8_amt,
 RDO8, RDO8_amt, RGO8, RGO8_amt, SHD8, SHD8_amt, SHDO, SHDO_amt, SHR8, SHR8_amt, SHRO, SHRO_amt, getdate() ServerDate from
 (select eb.employee_no, dbo.fusr_getNamePart(eb.employee_name,'LN') as Surname1, dbo.fusr_getNamePart(eb.employee_name,'FN') as FirstName1,
  sum(case when trx_code = 'AWOL' then QTY else 0 end) as AWOL,
  sum(case when trx_code = 'AWOL' then AMOUNT else 0 end) as AWOL_amt,
 sum(case when trx_code = 'LATE' then QTY else 0 end) as LATE,
  sum(case when trx_code = 'LATE' then AMOUNT else 0 end) as LATE_amt,
 sum(case when trx_code = 'NDWS' then QTY else 0 end) as NDWS,
   sum(case when trx_code = 'NDWS' then AMOUNT else 0 end) as NDWS_amt,
 sum(case when trx_code = 'RDOT' then QTY else 0 end) as RDOT,
   sum(case when trx_code = 'RDOT' then AMOUNT else 0 end) as RDOT_amt,
 sum(case when trx_code = 'LHRO' then QTY else 0 end) as LHRO,
   sum(case when trx_code = 'LHRO' then AMOUNT else 0 end) as LHRO_amt,
 sum(case when trx_code = 'RDND' then QTY else 0 end) as RDND,
   sum(case when trx_code = 'RDND' then AMOUNT else 0 end) as RDND_amt,
 sum(case when trx_code = 'RGOT' then QTY else 0 end) as RGOT,
   sum(case when trx_code = 'RGOT' then AMOUNT else 0 end) as RGOT_amt,
 sum(case when trx_code = 'EOUT' then QTY else 0 end) as EOUT,
   sum(case when trx_code = 'EOUT' then AMOUNT else 0 end) as EOUT_amt,
 sum(case when trx_code = 'OVBR' then QTY else 0 end) as OVBR,
   sum(case when trx_code = 'OVBR' then AMOUNT else 0 end) as OVBR_amt,
--additional allowance code added: 09/04/2012--
 sum(case when trx_code = 'LHN8' then QTY else 0 end) as LHN8,
   sum(case when trx_code = 'LHN8' then AMOUNT else 0 end) as LHN8_amt,
 sum(case when trx_code = 'LHND' then QTY else 0 end) as LHND,
   sum(case when trx_code = 'LHND' then AMOUNT else 0 end) as LHND_amt,
 sum(case when trx_code = 'LPAT' then QTY else 0 end) as LPAT,
   sum(case when trx_code = 'LPAT' then AMOUNT else 0 end) as LPAT_amt,
 sum(case when trx_code = 'LRN8' then QTY else 0 end) as LRN8,
   sum(case when trx_code = 'LRN8' then AMOUNT else 0 end) as LRN8_amt,
 sum(case when trx_code = 'LRND' then QTY else 0 end) as LRND,
   sum(case when trx_code = 'LRND' then AMOUNT else 0 end) as LRND_amt,
 sum(case when trx_code = 'NDDS' then QTY else 0 end) as NDDS,
   sum(case when trx_code = 'NDDS' then AMOUNT else 0 end) as NDDS_amt,
 sum(case when trx_code = 'NDOT' then QTY else 0 end) as NDOT,
   sum(case when trx_code = 'NDOT' then AMOUNT else 0 end) as NDOT_amt,
 sum(case when trx_code = 'NTAX' then QTY else 0 end) as NTAX,
   sum(case when trx_code = 'NTAX' then AMOUNT else 0 end) as NTAX_amt,
 sum(case when trx_code = 'RDN8' then QTY else 0 end) as RDN8,
   sum(case when trx_code = 'RDN8' then AMOUNT else 0 end) as RDN8_amt,
 sum(case when trx_code = 'SHN8' then QTY else 0 end) as SHN8,
   sum(case when trx_code = 'SHN8' then AMOUNT else 0 end) as SHN8_amt,
 sum(case when trx_code = 'SHND' then QTY else 0 end) as SHND,
   sum(case when trx_code = 'SHND' then AMOUNT else 0 end) as SHND_amt,
 sum(case when trx_code = 'SRDN' then QTY else 0 end) as SRDN,
   sum(case when trx_code = 'SRDN' then AMOUNT else 0 end) as SRDN_amt,
 sum(case when trx_code = 'SRN8' then QTY else 0 end) as SRN8,
   sum(case when trx_code = 'SRN8' then AMOUNT else 0 end) as SRN8_amt,
 sum(case when trx_code = 'TAX' then QTY else 0 end) as TAX,
   sum(case when trx_code = 'TAX' then AMOUNT else 0 end) as TAX_amt,
 sum(case when trx_code = 'TRNS' then QTY else 0 end) as TRNS,
   sum(case when trx_code = 'TRNS' then AMOUNT else 0 end) as TRNS_amt,
 --additional deduction code added: 09/04/2012--
 --sum(case when trx_code = 'LWOP' then QTY else 0 end) as LWOP,
   --sum(case when trx_code = 'LWOP' then AMOUNT else 0 end) as LWOP_amt,
 --additional overtime code added: 09/04/2012--
 sum(case when trx_code = 'LHD8' then QTY else 0 end) as LHD8,
   sum(case when trx_code = 'LHD8' then AMOUNT else 0 end) as LHD8_amt,
 sum(case when trx_code = 'LHDO' then QTY else 0 end) as LHDO,
   sum(case when trx_code = 'LHDO' then AMOUNT else 0 end) as LHDO_amt,
 sum(case when trx_code = 'LHR8' then QTY else 0 end) as LHR8,
   sum(case when trx_code = 'LHR8' then AMOUNT else 0 end) as LHR8_amt,
 sum(case when trx_code = 'RDO8' then QTY else 0 end) as RDO8,
   sum(case when trx_code = 'RDO8' then AMOUNT else 0 end) as RDO8_amt,
 sum(case when trx_code = 'RGO8' then QTY else 0 end) as RGO8,
   sum(case when trx_code = 'RGO8' then AMOUNT else 0 end) as RGO8_amt,
 sum(case when trx_code = 'SHD8' then QTY else 0 end) as SHD8,
   sum(case when trx_code = 'SHD8' then AMOUNT else 0 end) as SHD8_amt,
 sum(case when trx_code = 'SHDO' then QTY else 0 end) as SHDO,
   sum(case when trx_code = 'SHDO' then AMOUNT else 0 end) as SHDO_amt,
 sum(case when trx_code = 'SHR8' then QTY else 0 end) as SHR8,
   sum(case when trx_code = 'SHR8' then AMOUNT else 0 end) as SHR8_amt,
 sum(case when trx_code = 'SHRO' then QTY else 0 end) as SHRO,
   sum(case when trx_code = 'SHRO' then AMOUNT else 0 end) as SHRO_amt
 from employee_trxldg trx, employee_biodata eb  
 where trx.employee_no = eb.employee_no and day(trx_date) >= 5 and day(trx_date) <= 19
 group by eb.employee_no, dbo.fusr_getNamePart(eb.employee_name,'LN'), dbo.fusr_getNamePart(eb.employee_name,'FN')) ldg
 full outer join 
 (select li.employee_no, dbo.fusr_getNamePart(eb.employee_name,'LN') as Surname2, dbo.fusr_getNamePart(eb.employee_name,'FN') as FirstName2, 
 sum(case when leave_code = 'SL' then 1 else 0 end) as SL,
 sum(case when leave_code = 'VL' then 1 else 0 end) as VL,
 sum(case when leave_code = 'BL' then 1 else 0 end) as BL,
 sum(case when leave_code = 'ML' then 1 else 0 end) as ML,
 sum(case when leave_code = 'CL' then 1 else 0 end) as CL,
 sum(case when leave_code = 'PL' then 1 else 0 end) as PL,
 sum(case when leave_code = 'LWOP' then 1 else 0 end) as LWOP,
 sum(case when leave_code = 'SUSP' then 1 else 0 end) as SUSP,
 --additional leave code added: 09/04/2012--
 sum(case when leave_code = 'CML' then 1 else 0 end) as CML,
 sum(case when leave_code = 'CMPL' then 1 else 0 end) as CMPL,
 sum(case when leave_code = 'CPL' then 1 else 0 end) as CPL,
 sum(case when leave_code = 'EXL' then 1 else 0 end) as EXL,
 sum(case when leave_code = 'MLND' then 1 else 0 end) as MLND,
 sum(case when leave_code = 'OIL' then 1 else 0 end) as OIL,
 sum(case when leave_code = 'SLOP' then 1 else 0 end) as SLOP,
 sum(case when leave_code = 'SPAL' then 1 else 0 end) as SPAL,
 sum(case when leave_code = 'VLOP' then 1 else 0 end) as VLOP
from employee_leave_day ld, employee_leave_info li, employee_biodata eb
where ld.employee_id = li.employee_id and ld.reference_id = li.reference_no and ld.employee_id = eb.employee_id and
 year(approve_date) = year(getdate()) and month(approve_date) = month(getdate()) and day(approve_date) >= 5 and day(approve_date) <= 19 
group by li.employee_no, dbo.fusr_getNamePart(eb.employee_name,'LN'), dbo.fusr_getNamePart(eb.employee_name,'FN')) lv 
on lv.employee_no = ldg.employee_no
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE view weekly_schedule
AS
SELECT * 
FROM	oritms_trng.dbo.weekly_schedule

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
create view WORK_GROUP
AS 
SELECT 	*
FROM 	oritms_trng.dbo.WORK_GROUP

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE view work_type_break_time
AS
SELECT * 
FROM	oritms_trng.dbo.work_type_break_time

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE view work_type_setup
AS
SELECT * 
FROM	oritms_trng.dbo.work_type_setup

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE view work_type_shift
AS
SELECT * 
FROM	oritms_trng.dbo.work_type_shift

